import { Router } from 'express';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';
import { enrollVoice, verifyVoice } from '../services/voiceAuth/voiceAuthClient.js';

export const voiceAuthRouter = Router();

voiceAuthRouter.post('/enroll', requireApprovedDevice, async (req, res) => {
  const { audio } = req.body;
  if (!audio) return res.status(400).json({ ok: false, error: 'audio (base64) required' });
  const result = await enrollVoice({ userId: req.device.user_id, audioBase64: audio });
  res.json(result);
});

voiceAuthRouter.post('/verify', requireApprovedDevice, async (req, res) => {
  const { audio } = req.body;
  if (!audio) return res.status(400).json({ ok: false, error: 'audio (base64) required' });
  const result = await verifyVoice({ userId: req.device.user_id, audioBase64: audio });
  res.json(result);
});
