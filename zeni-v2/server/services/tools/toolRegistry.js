// services/tools/toolRegistry.js
// Formal tool system per spec §31/§18:
//   LLM -> tool selection -> structured args -> VALIDATION -> AUTHORIZATION -> execution -> logged result -> LLM
// The LLM NEVER directly executes anything. It can only request a tool call,
// which passes through this registry before anything real happens.

import { createLogger } from '../../utils/logger.js';
import { db } from '../../db/index.js';
import { randomUUID } from 'crypto';

const logger = createLogger('tool-registry');

// Files that decide what's allowed to happen never become something an
// approval can allow changing — this is checked again server-side in
// executeTool, independent of whatever the PC agent itself enforces.
const PROTECTED_PATH_PATTERNS = [
  /middleware\/requireApprovedDevice\.js$/,
  /services\/tools\/toolRegistry\.js$/,
  /config\/index\.js$/,
  /routes\/devices\.js$/,
];

function touchesProtectedPath(args) {
  const candidate = args?.path;
  if (!candidate) return false;
  return PROTECTED_PATH_PATTERNS.some(pattern => pattern.test(candidate));
}

const registry = new Map();

/**
 * Register a tool. Every tool MUST define:
 *   name, description, inputSchema (JSON schema-ish), riskLevel, requiresApproval, handler
 */
export function registerTool({ name, description, inputSchema, riskLevel = 'low', requiresApproval = false, handler }) {
  if (registry.has(name)) {
    throw new Error(`Tool "${name}" already registered — duplicate tool definitions are not allowed.`);
  }
  registry.set(name, { name, description, inputSchema, riskLevel, requiresApproval, handler });

  db.prepare(
    `INSERT INTO tools (name, description, input_schema, risk_level, requires_approval, enabled)
     VALUES (?, ?, ?, ?, ?, 1)
     ON CONFLICT(name) DO UPDATE SET description=excluded.description, input_schema=excluded.input_schema,
       risk_level=excluded.risk_level, requires_approval=excluded.requires_approval`
  ).run(name, description, JSON.stringify(inputSchema), riskLevel, requiresApproval ? 1 : 0);

  logger.info('tool registered', { name, riskLevel, requiresApproval });
}

export function listToolDefinitions() {
  // Format compatible with OpenRouter/OpenAI-style function calling
  return Array.from(registry.values()).map(t => ({
    type: 'function',
    function: {
      name: t.name,
      description: t.description,
      parameters: t.inputSchema,
    },
  }));
}

function validateArgs(schema, args) {
  if (!schema || !schema.required) return { ok: true };
  const missing = schema.required.filter(key => !(key in (args || {})));
  if (missing.length) return { ok: false, error: `Missing required fields: ${missing.join(', ')}` };
  return { ok: true };
}

/**
 * Execute a tool call requested by the LLM. This is the ONLY path by which
 * a tool actually runs. Every call is logged to audit_log regardless of outcome.
 */
export async function executeTool({ name, args, userId, deviceId, context = {} }) {
  const tool = registry.get(name);
  const auditId = randomUUID();

  if (!tool) {
    logAudit(auditId, userId, deviceId, 'tool_call', { name, args, result: 'UNKNOWN_TOOL' });
    return { ok: false, status: 'UNKNOWN_TOOL', error: `No tool registered as "${name}"` };
  }

  const validation = validateArgs(tool.inputSchema, args);
  if (!validation.ok) {
    logAudit(auditId, userId, deviceId, 'tool_call', { name, args, result: 'INVALID_ARGS', error: validation.error });
    return { ok: false, status: 'INVALID_ARGS', error: validation.error };
  }

  // Hard block, independent of approval — no confirmation step unlocks these.
  if ((name === 'pc_write_file' || name === 'pc_execute_command' || name === 'pc_promote_file') && touchesProtectedPath(args)) {
    logAudit(auditId, userId, deviceId, 'tool_call', { name, args, result: 'PROTECTED_PATH_BLOCKED' });
    return { ok: false, status: 'PROTECTED_PATH_BLOCKED', error: 'This path is part of the security/approval system itself and cannot be self-edited.' };
  }

  if (tool.requiresApproval && !context.approved) {
    const automationId = randomUUID();
    db.prepare(
      `INSERT INTO automations (id, user_id, instruction, resolved_action, status) VALUES (?, ?, ?, ?, 'pending')`
    ).run(automationId, userId, `${name} requested via chat`, JSON.stringify({ name, args, deviceId }));

    logAudit(auditId, userId, deviceId, 'tool_call', { name, args, result: 'PENDING_APPROVAL', automationId });
    return {
      ok: false,
      status: 'PENDING_APPROVAL',
      automationId,
      message: `"${name}" requires explicit approval — queued as ${automationId}. Approve via POST /automations/${automationId}/approve.`,
    };
  }

  try {
    const result = await tool.handler(args, { userId, deviceId, ...context });
    logAudit(auditId, userId, deviceId, 'tool_call', { name, args, result: 'SUCCESS' });
    return { ok: true, status: 'EXECUTED', result };
  } catch (err) {
    logger.error('tool execution failed', { name, error: err.message });
    logAudit(auditId, userId, deviceId, 'tool_call', { name, args, result: 'FAILED', error: err.message });
    return { ok: false, status: 'FAILED', error: err.message };
  }
}

/**
 * The other half of the approval flow — actually runs a previously-queued
 * automation. This is the ONLY path that sets context.approved = true, and
 * it's only reachable after the password gate in routes/automations.js.
 */
export async function executeApprovedAutomation(automationId) {
  const row = db.prepare(`SELECT * FROM automations WHERE id = ?`).get(automationId);
  if (!row) return { ok: false, status: 'NOT_FOUND' };
  if (row.status !== 'pending') return { ok: false, status: 'ALREADY_RESOLVED', currentStatus: row.status };

  const { name, args, deviceId } = JSON.parse(row.resolved_action);
  const result = await executeTool({ name, args, userId: row.user_id, deviceId, context: { approved: true } });

  db.prepare(`UPDATE automations SET status = ?, executed_at = datetime('now') WHERE id = ?`)
    .run(result.ok ? 'executed' : 'failed', automationId);

  return result;
}

export function rejectAutomation(automationId) {
  const result = db.prepare(`UPDATE automations SET status = 'rejected' WHERE id = ? AND status = 'pending'`).run(automationId);
  return result.changes > 0;
}

export function listPendingAutomations(userId) {
  return db.prepare(`SELECT * FROM automations WHERE user_id = ? AND status = 'pending' ORDER BY created_at DESC`).all(userId);
}

function logAudit(id, userId, deviceId, eventType, detail) {
  db.prepare(
    `INSERT INTO audit_log (id, user_id, device_id, event_type, detail) VALUES (?, ?, ?, ?, ?)`
  ).run(id, userId || null, deviceId || null, eventType, JSON.stringify(detail));
}

export function getRegisteredTools() {
  return Array.from(registry.keys());
}
