import { Router } from 'express';
import { db } from '../db/index.js';
import { config } from '../config/index.js';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';
import { executeApprovedAutomation, rejectAutomation, listPendingAutomations } from '../services/tools/toolRegistry.js';

export const automationsRouter = Router();

automationsRouter.get('/', requireApprovedDevice, (req, res) => {
  res.json({ ok: true, pending: listPendingAutomations(req.device.user_id) });
});

automationsRouter.post('/:id/approve', requireApprovedDevice, async (req, res) => {
  const { password } = req.body;
  if (!config.security.mainPassword || password !== config.security.mainPassword) {
    return res.status(403).json({ ok: false, error: 'Invalid approval credential' });
  }
  const result = await executeApprovedAutomation(req.params.id);
  res.json(result);
});

automationsRouter.post('/:id/reject', requireApprovedDevice, (req, res) => {
  const rejected = rejectAutomation(req.params.id);
  res.json({ ok: rejected });
});
