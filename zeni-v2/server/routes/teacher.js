import { Router } from 'express';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';
import { createConversation, addMessage, getConversation } from '../services/conversation/conversationService.js';
import { handleTeacherMessage, generateQuizQuestion, getProgress, SUBJECTS } from '../services/teacher/teacherService.js';

export const teacherRouter = Router();

teacherRouter.get('/subjects', (req, res) => res.json({ ok: true, subjects: SUBJECTS }));

teacherRouter.post('/message', requireApprovedDevice, async (req, res) => {
  const { message, subject, mode, conversationId: incomingConvId } = req.body;
  if (!message || !subject || !mode) {
    return res.status(400).json({ ok: false, error: 'message, subject, mode are required' });
  }

  const userId = req.device.user_id;
  let conversationId = incomingConvId;

  if (conversationId) {
    const conv = getConversation(conversationId);
    if (!conv || conv.user_id !== userId) return res.status(403).json({ ok: false, error: 'invalid conversationId' });
  } else {
    conversationId = createConversation({ userId, deviceId: req.device.id, title: `Teacher: ${subject}` });
  }

  addMessage({ conversationId, role: 'user', content: message });

  const deviceContext = {
    id: req.device.id, name: req.device.name, device_type: req.device.device_type,
    capabilities: JSON.parse(req.device.capabilities || '[]'),
  };

  const result = await handleTeacherMessage({ userId, conversationId, message, subject, mode, deviceContext });

  if (!result.ok) {
    return res.status(result.status === 'INVALID_SUBJECT' || result.status === 'INVALID_MODE' ? 400 : 502).json({ ...result, conversationId });
  }

  addMessage({ conversationId, role: 'assistant', content: result.content });
  res.json({ ok: true, conversationId, reply: result.content });
});

teacherRouter.post('/quiz/generate', requireApprovedDevice, async (req, res) => {
  const { subject, difficulty } = req.body;
  if (!subject) return res.status(400).json({ ok: false, error: 'subject required' });
  const result = await generateQuizQuestion({ subject, difficulty });
  res.json(result);
});

teacherRouter.get('/progress', requireApprovedDevice, (req, res) => {
  res.json({ ok: true, progress: getProgress(req.device.user_id) });
});
