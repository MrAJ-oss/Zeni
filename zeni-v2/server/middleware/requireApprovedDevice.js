// middleware/requireApprovedDevice.js
// Blocks any route from being used by a device that hasn't gone through
// the approval flow (spec §13). Unknown/pending devices get nothing.

import { db } from '../db/index.js';

export function requireApprovedDevice(req, res, next) {
  const deviceId = req.headers['x-device-id'];
  if (!deviceId) {
    return res.status(401).json({ ok: false, status: 'DEVICE_ID_MISSING' });
  }

  const device = db.prepare(`SELECT * FROM devices WHERE id = ?`).get(deviceId);
  if (!device) {
    return res.status(403).json({ ok: false, status: 'DEVICE_UNKNOWN' });
  }
  if (device.status !== 'approved') {
    return res.status(403).json({ ok: false, status: 'DEVICE_NOT_APPROVED' });
  }

  db.prepare(`UPDATE devices SET last_seen_at = datetime('now') WHERE id = ?`).run(deviceId);
  req.device = device;
  next();
}
