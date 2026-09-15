// routes/chat.js
// Main conversation endpoint. This is what the client (web/mobile/overlay) calls.

import { Router } from 'express';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';
import { getResponse } from '../services/ai/aiService.js';
import { createConversation, addMessage, getConversation } from '../services/conversation/conversationService.js';
import { analyzeEmotion } from '../services/nova/novaClient.js';
import { createLogger } from '../utils/logger.js';
import { db } from '../db/index.js';
import { randomUUID } from 'crypto';

export const chatRouter = Router();
const logger = createLogger('chat-route');

function recordEmotion({ userId, conversationId, source, emotionResult }) {
  db.prepare(
    `INSERT INTO emotion_records (id, user_id, conversation_id, source, emotional_state, intensity, confidence, raw_output)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(randomUUID(), userId, conversationId, source, emotionResult.emotionalState, emotionResult.intensity, emotionResult.confidence, JSON.stringify(emotionResult));
}

chatRouter.post('/message', requireApprovedDevice, async (req, res) => {
  const { message, conversationId: incomingConvId, mode } = req.body;
  if (!message || typeof message !== 'string') {
    return res.status(400).json({ ok: false, error: 'message (string) is required' });
  }

  const userId = req.device.user_id;
  let conversationId = incomingConvId;

  if (conversationId) {
    const conv = getConversation(conversationId);
    if (!conv || conv.user_id !== userId) {
      return res.status(403).json({ ok: false, error: 'Invalid conversationId for this user' });
    }
  } else {
    conversationId = createConversation({ userId, deviceId: req.device.id });
  }

  addMessage({ conversationId, role: 'user', content: message });

  const deviceContext = {
    id: req.device.id,
    name: req.device.name,
    device_type: req.device.device_type,
    capabilities: JSON.parse(req.device.capabilities || '[]'),
  };

  // Calls the real NOVA service when one is configured; otherwise this
  // correctly resolves to a NOT_IMPLEMENTED result and emotionalContext stays
  // null rather than being faked.
  const emotionResult = await analyzeEmotion({ text: message, userId });
  const emotionalContext = emotionResult.ok
    ? { state: emotionResult.emotionalState, intensity: emotionResult.intensity, confidence: emotionResult.confidence }
    : null;
  if (emotionResult.ok) {
    recordEmotion({ userId, conversationId, source: 'text', emotionResult });
  }

  const result = await getResponse({
    userId,
    conversationId,
    userMessage: message,
    deviceContext,
    emotionalContext,
    mode: mode || 'default',
  });

  if (!result.ok) {
    logger.error('chat response failed', { status: result.status });
    return res.status(502).json({ ok: false, status: result.status, error: result.error, conversationId });
  }

  addMessage({ conversationId, role: 'assistant', content: result.content });

  res.json({
    ok: true,
    conversationId,
    reply: result.content,
    model: result.model,
    usedFallback: result.usedFallback,
    visual: result.visual || null,
    citations: result.citations || null,
    contactAction: result.contactAction || null,
  });
});
