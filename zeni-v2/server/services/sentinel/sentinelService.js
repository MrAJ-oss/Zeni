import { db } from '../../db/index.js';
import { randomUUID } from 'crypto';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('sentinel');

// Real DNS/IP reputation lookup using a public API. Defensive read-only check —
// no scanning, no probing of third-party systems.
export async function checkIpReputation(ip) {
  try {
    const res = await fetch(`https://ipapi.co/${ip}/json/`);
    if (!res.ok) return { ok: false, status: 'LOOKUP_FAILED' };
    const data = await res.json();
    return {
      ok: true,
      ip,
      country: data.country_name,
      org: data.org,
      isVpnOrProxy: null, // requires a paid reputation API — not implemented
      status: 'PARTIAL_IMPLEMENTATION',
    };
  } catch (err) {
    logger.error('ip lookup failed', { message: err.message });
    return { ok: false, status: 'LOOKUP_FAILED' };
  }
}

// Link scanning requires an external threat-intel API (e.g. Google Safe Browsing,
// VirusTotal). Not wired to a provider yet — honest state, not a fake pass.
export async function scanLink(url) {
  return { ok: false, status: 'NOT_IMPLEMENTED', reason: 'No threat-intel provider configured', url };
}

export function logSecurityEvent({ userId, deviceId, eventType, detail }) {
  const id = randomUUID();
  db.prepare(`INSERT INTO audit_log (id, user_id, device_id, event_type, detail) VALUES (?, ?, ?, ?, ?)`)
    .run(id, userId || null, deviceId || null, `sentinel_${eventType}`, JSON.stringify(detail));
  return id;
}

export function getRecentSecurityEvents(userId, limit = 50) {
  return db.prepare(
    `SELECT * FROM audit_log WHERE user_id = ? AND event_type LIKE 'sentinel_%' ORDER BY created_at DESC LIMIT ?`
  ).all(userId, limit);
}
