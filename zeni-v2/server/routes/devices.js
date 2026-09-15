// routes/devices.js
// Device registration + approval flow (spec §12/§13).

import { Router } from 'express';
import { randomUUID } from 'crypto';
import { db } from '../db/index.js';
import { config } from '../config/index.js';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';

export const devicesRouter = Router();

// New device registers itself -> status: pending. No capabilities until approved.
devicesRouter.post('/register', (req, res) => {
  const { userId, name, deviceType, capabilities = [] } = req.body;
  if (!userId || !name || !deviceType) {
    return res.status(400).json({ ok: false, error: 'userId, name, deviceType are required' });
  }
  const id = randomUUID();
  db.prepare(
    `INSERT INTO devices (id, user_id, name, device_type, capabilities, status) VALUES (?, ?, ?, ?, ?, 'pending')`
  ).run(id, userId, name, deviceType, JSON.stringify(capabilities));
  res.json({ ok: true, deviceId: id, status: 'pending' });
});

// Approve a pending device - requires the main password (spec: privileged action gate).
devicesRouter.post('/:id/approve', (req, res) => {
  const { password } = req.body;
  if (!config.security.mainPassword || password !== config.security.mainPassword) {
    return res.status(403).json({ ok: false, error: 'Invalid approval credential' });
  }
  const result = db.prepare(`UPDATE devices SET status = 'approved' WHERE id = ?`).run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ ok: false, error: 'Device not found' });
  res.json({ ok: true, status: 'approved' });
});

devicesRouter.post('/:id/revoke', (req, res) => {
  const { password } = req.body;
  if (!config.security.mainPassword || password !== config.security.mainPassword) {
    return res.status(403).json({ ok: false, error: 'Invalid credential' });
  }
  db.prepare(`UPDATE devices SET status = 'revoked' WHERE id = ?`).run(req.params.id);
  res.json({ ok: true, status: 'revoked' });
});

devicesRouter.get('/', requireApprovedDevice, (req, res) => {
  const devices = db.prepare(`SELECT id, name, device_type, status, last_seen_at FROM devices WHERE user_id = ?`)
    .all(req.device.user_id);
  res.json({ ok: true, devices });
});
