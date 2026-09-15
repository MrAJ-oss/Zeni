import { registerTool } from './toolRegistry.js';
import { storeMemory, searchMemories } from '../memory/memoryService.js';
import { db } from '../../db/index.js';
import { randomUUID } from 'crypto';
import { dispatchToAgent } from '../pcAgent/agentGateway.js';
import { geocodeLocation } from './geocodeService.js';

registerTool({
  name: 'remember',
  description: 'Store a fact or preference about the user for future conversations',
  inputSchema: {
    type: 'object',
    required: ['content', 'category'],
    properties: {
      content: { type: 'string' },
      category: { type: 'string', enum: ['preference', 'project', 'relationship', 'fact', 'emotional'] },
      importance: { type: 'number' },
    },
  },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => {
    const id = storeMemory({ userId: ctx.userId, content: args.content, category: args.category, importance: args.importance || 5, source: ctx.conversationId || 'chat' });
    return { stored: true, id };
  },
});

registerTool({
  name: 'recall',
  description: 'Search stored memories for a specific term',
  inputSchema: { type: 'object', required: ['term'], properties: { term: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => {
    const results = searchMemories({ userId: ctx.userId, term: args.term });
    return { count: results.length, memories: results.map(m => m.content) };
  },
});

registerTool({
  name: 'create_task',
  description: 'Add a task to a project',
  inputSchema: {
    type: 'object',
    required: ['projectId', 'title'],
    properties: { projectId: { type: 'string' }, title: { type: 'string' }, notes: { type: 'string' } },
  },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args) => {
    const id = randomUUID();
    db.prepare(`INSERT INTO tasks (id, project_id, title, notes) VALUES (?, ?, ?, ?)`)
      .run(id, args.projectId, args.title, args.notes || null);
    return { created: true, id };
  },
});

// Lets Zeni place calls by name — client does the actual contact lookup,
// this just passes the intent through.
registerTool({
  name: 'call_contact',
  description: 'Place a phone call to a contact by name (first name is fine — do fuzzy matching, not exact full name)',
  inputSchema: { type: 'object', required: ['contactName'], properties: { contactName: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  // No server-side side effect — the phone's own contact list lives on the
  // device, not here. This just passes the intent through; the client does
  // the lookup and the OS dialer still requires the user's own tap to
  // actually place the call, same safety line as everything else.
  handler: async (args) => ({ action: 'call_contact', contactName: args.contactName }),
});

// Real location lookup for the map visual — no key needed. Places and
// events only, per registerTool's description above.
registerTool({
  name: 'geocode_location',
  description: 'Resolve a place name (city, landmark, address) to real coordinates for showing on a map. Places and events only — never for locating a specific named person.',
  inputSchema: { type: 'object', required: ['query'], properties: { query: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args) => geocodeLocation(args.query),
});

// PC control — high risk, requires approval, routes through the PC Agent gateway,
// never executes anything directly on the server.
registerTool({
  name: 'pc_execute_command',
  description: 'Request an approved local command be run on a connected, approved PC device',
  inputSchema: {
    type: 'object',
    required: ['deviceId', 'command'],
    properties: { deviceId: { type: 'string' }, command: { type: 'string' }, args: { type: 'array' } },
  },
  riskLevel: 'high',
  requiresApproval: true,
  handler: async (args, ctx) => {
    return dispatchToAgent({ deviceId: args.deviceId, command: args.command, args: args.args || [], userId: ctx.userId });
  },
});

registerTool({
  name: 'pc_get_status',
  description: 'Get status/info from a connected PC agent (no side effects)',
  inputSchema: { type: 'object', required: ['deviceId'], properties: { deviceId: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'status', args: [], userId: ctx.userId }),
});

registerTool({
  name: 'pc_list_directory',
  description: 'List files in a directory within the configured project root on a connected PC (read-only)',
  inputSchema: { type: 'object', required: ['deviceId'], properties: { deviceId: { type: 'string' }, path: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'list_dir', args: [args.path || '.'], userId: ctx.userId }),
});

registerTool({
  name: 'pc_read_file',
  description: 'Read a file within the configured project root on a connected PC (read-only)',
  inputSchema: { type: 'object', required: ['deviceId', 'path'], properties: { deviceId: { type: 'string' }, path: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'read_file', args: [args.path], userId: ctx.userId }),
});

registerTool({
  name: 'pc_write_file',
  description: 'Write/overwrite a file within the configured project root on a connected PC. Has real side effects.',
  inputSchema: {
    type: 'object', required: ['deviceId', 'path', 'content'],
    properties: { deviceId: { type: 'string' }, path: { type: 'string' }, content: { type: 'string' } },
  },
  riskLevel: 'high',
  requiresApproval: true,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'write_file', args: [args.path, args.content], userId: ctx.userId }),
});

// Sandbox tools — an isolated copy, not the live server. Nothing here is
// approval-gated except promotion, since nothing here can affect anything
// actually running until that one deliberate step.
registerTool({
  name: 'pc_sandbox_create',
  description: 'Create a fresh isolated copy of the project for building/testing a new feature without touching the live code',
  inputSchema: { type: 'object', required: ['deviceId', 'sandboxName'], properties: { deviceId: { type: 'string' }, sandboxName: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'sandbox_create', args: [args.sandboxName], userId: ctx.userId, timeoutMs: 30000 }),
});

registerTool({
  name: 'pc_sandbox_read_file',
  description: 'Read a file inside a sandbox copy',
  inputSchema: { type: 'object', required: ['deviceId', 'sandboxName', 'path'], properties: { deviceId: { type: 'string' }, sandboxName: { type: 'string' }, path: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'sandbox_read_file', args: [args.sandboxName, args.path], userId: ctx.userId }),
});

registerTool({
  name: 'pc_sandbox_list_directory',
  description: 'List files inside a sandbox copy',
  inputSchema: { type: 'object', required: ['deviceId', 'sandboxName'], properties: { deviceId: { type: 'string' }, sandboxName: { type: 'string' }, path: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'sandbox_list_dir', args: [args.sandboxName, args.path || '.'], userId: ctx.userId }),
});

registerTool({
  name: 'pc_sandbox_write_file',
  description: 'Write a file inside a sandbox copy — free to iterate, has no effect on the live system',
  inputSchema: {
    type: 'object', required: ['deviceId', 'sandboxName', 'path', 'content'],
    properties: { deviceId: { type: 'string' }, sandboxName: { type: 'string' }, path: { type: 'string' }, content: { type: 'string' } },
  },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'sandbox_write_file', args: [args.sandboxName, args.path, args.content], userId: ctx.userId }),
});

registerTool({
  name: 'pc_sandbox_run',
  description: 'Start the sandbox copy as a live server on a separate port so the built feature can actually be tested',
  inputSchema: { type: 'object', required: ['deviceId', 'sandboxName'], properties: { deviceId: { type: 'string' }, sandboxName: { type: 'string' }, port: { type: 'number' } } },
  riskLevel: 'medium',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'sandbox_run', args: [args.sandboxName, args.port], userId: ctx.userId, timeoutMs: 30000 }),
});

registerTool({
  name: 'pc_sandbox_stop',
  description: 'Stop the currently running sandbox server',
  inputSchema: { type: 'object', required: ['deviceId'], properties: { deviceId: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'sandbox_stop', args: [], userId: ctx.userId }),
});

// The one moment a sandbox change becomes real — same approval + protected-path
// gate as pc_write_file, because this IS pc_write_file's risk the instant it lands.
registerTool({
  name: 'pc_promote_file',
  description: 'Copy one file from a sandbox into the live project — the deliberate "ship it" step, after the user has tested and approved the result',
  inputSchema: {
    type: 'object', required: ['deviceId', 'sandboxName', 'path'],
    properties: { deviceId: { type: 'string' }, sandboxName: { type: 'string' }, path: { type: 'string' } },
  },
  riskLevel: 'high',
  requiresApproval: true,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'promote_file', args: [args.sandboxName, args.path], userId: ctx.userId }),
});

// Screen/mouse/keyboard control — one approval gates the whole session, not
// each action. Real-time inside the window; the agent itself refuses every
// input command outside an active session regardless of what reaches it here.
registerTool({
  name: 'pc_start_control_session',
  description: 'Request real-time mouse/keyboard/screen control of a connected PC for a time-boxed window (max 15 min). Requires explicit approval — this is the one gate; actions inside the session are immediate.',
  inputSchema: { type: 'object', required: ['deviceId'], properties: { deviceId: { type: 'string' }, minutes: { type: 'number' } } },
  riskLevel: 'high',
  requiresApproval: true,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'start_control_session', args: [args.minutes || 5], userId: ctx.userId }),
});

registerTool({
  name: 'pc_stop_control_session',
  description: 'End the active control session immediately — always frictionless, no approval, same as a stop phrase',
  inputSchema: { type: 'object', required: ['deviceId'], properties: { deviceId: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'stop_control_session', args: [], userId: ctx.userId }),
});

registerTool({
  name: 'pc_screen_capture',
  description: 'Take a screenshot of the connected PC — read-only, no session required',
  inputSchema: { type: 'object', required: ['deviceId'], properties: { deviceId: { type: 'string' } } },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'screen_capture', args: [], userId: ctx.userId, timeoutMs: 15000 }),
});

registerTool({
  name: 'pc_mouse_move',
  description: 'Move the mouse to screen coordinates — only works during an active control session',
  inputSchema: { type: 'object', required: ['deviceId', 'x', 'y'], properties: { deviceId: { type: 'string' }, x: { type: 'number' }, y: { type: 'number' } } },
  riskLevel: 'medium',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'mouse_move', args: [args.x, args.y], userId: ctx.userId }),
});

registerTool({
  name: 'pc_mouse_click',
  description: 'Click the mouse at its current position — only works during an active control session',
  inputSchema: { type: 'object', required: ['deviceId'], properties: { deviceId: { type: 'string' }, button: { type: 'string', enum: ['left', 'right', 'middle'] } } },
  riskLevel: 'medium',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'mouse_click', args: [args.button || 'left'], userId: ctx.userId }),
});

registerTool({
  name: 'pc_type_text',
  description: 'Type text at the current cursor focus — only works during an active control session',
  inputSchema: { type: 'object', required: ['deviceId', 'text'], properties: { deviceId: { type: 'string' }, text: { type: 'string' } } },
  riskLevel: 'medium',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'type_text', args: [args.text], userId: ctx.userId }),
});

registerTool({
  name: 'pc_key_press',
  description: 'Press a single key (e.g. "Enter", "Tab", "Escape") — only works during an active control session',
  inputSchema: { type: 'object', required: ['deviceId', 'key'], properties: { deviceId: { type: 'string' }, key: { type: 'string' } } },
  riskLevel: 'medium',
  requiresApproval: false,
  handler: async (args, ctx) => dispatchToAgent({ deviceId: args.deviceId, command: 'key_press', args: [args.key], userId: ctx.userId }),
});
