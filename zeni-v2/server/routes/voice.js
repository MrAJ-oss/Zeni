import { Router } from 'express';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';
import { transcribeAudio, synthesizeSpeech } from '../services/voice/speechService.js';

export const voiceRouter = Router();

voiceRouter.post('/speak', requireApprovedDevice, async (req, res) => {
  const { text, languageCode } = req.body;
  if (!text) return res.status(400).json({ ok: false, error: 'text required' });
  const result = await synthesizeSpeech(text, languageCode || null);
  res.json(result);
});

voiceRouter.post('/transcribe', requireApprovedDevice, async (req, res) => {
  const { audio, format, language } = req.body;
  if (!audio) return res.status(400).json({ ok: false, error: 'audio (base64) required' });
  const result = await transcribeAudio({ audioBase64: audio, format: format || 'wav', language: language || null });
  res.json(result);
});
