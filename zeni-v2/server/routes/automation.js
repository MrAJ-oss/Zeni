import { Router } from 'express';
import { randomUUID } from 'crypto';
import { db } from '../db/index.js';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';
import { createConversation, getConversation } from '../services/conversation/conversationService.js';
import { generateProactiveMessage, generatePresenceReaction } from '../services/ai/aiService.js';

export const automationRouter = Router();

const GEOFENCE_COOLDOWN_MINUTES = 20;
const PRESENCE_COOLDOWN_MINUTES = 15;

automationRouter.post('/geofence-trigger', requireApprovedDevice, async (req, res) => {
  const { conversationId: incomingConvId } = req.body;

  const last = req.device.last_geofence_trigger_at;
  if (last) {
    const minutesSince = (Date.now() - new Date(last + 'Z').getTime()) / 60000;
    if (minutesSince < GEOFENCE_COOLDOWN_MINUTES) {
      return res.json({ ok: false, status: 'COOLDOWN', minutesRemaining: Math.ceil(GEOFENCE_COOLDOWN_MINUTES - minutesSince) });
    }
  }

  const userId = req.device.user_id;
  let conversationId = incomingConvId;
  if (conversationId) {
    const conv = getConversation(conversationId);
    if (!conv || conv.user_id !== userId) return res.status(403).json({ ok: false, error: 'invalid conversationId' });
  } else {
    conversationId = createConversation({ userId, deviceId: req.device.id, title: 'Geofence check-in' });
  }

  const deviceContext = {
    id: req.device.id, name: req.device.name, device_type: req.device.device_type,
    capabilities: JSON.parse(req.device.capabilities || '[]'),
  };

  const result = await generateProactiveMessage({
    userId,
    conversationId,
    triggerDescription: 'user just arrived back at their saved home location',
    deviceContext,
  });

  db.prepare(`INSERT INTO audit_log (id, user_id, device_id, event_type, detail) VALUES (?, ?, ?, 'geofence_trigger', ?)`)
    .run(randomUUID(), userId, req.device.id, JSON.stringify({ resultOk: result.ok }));

  if (!result.ok) return res.status(502).json({ ok: false, status: result.status, error: result.error, conversationId });

  // Cooldown only starts on a real, successful trigger — a failed AI call
  // (missing key, provider down) is not an event that should lock the user
  // out of the next genuine attempt.
  db.prepare(`UPDATE devices SET last_geofence_trigger_at = datetime('now') WHERE id = ?`).run(req.device.id);
  res.json({ ok: true, conversationId, reply: result.content });
});

automationRouter.post('/presence-trigger', requireApprovedDevice, async (req, res) => {
  const { imageBase64, conversationId: incomingConvId } = req.body;
  if (!imageBase64) return res.status(400).json({ ok: false, error: 'imageBase64 required' });

  const last = req.device.last_presence_trigger_at;
  if (last) {
    const minutesSince = (Date.now() - new Date(last + 'Z').getTime()) / 60000;
    if (minutesSince < PRESENCE_COOLDOWN_MINUTES) {
      return res.json({ ok: false, status: 'COOLDOWN', minutesRemaining: Math.ceil(PRESENCE_COOLDOWN_MINUTES - minutesSince) });
    }
  }

  const userId = req.device.user_id;
  let conversationId = incomingConvId;
  if (conversationId) {
    const conv = getConversation(conversationId);
    if (!conv || conv.user_id !== userId) return res.status(403).json({ ok: false, error: 'invalid conversationId' });
  } else {
    conversationId = createConversation({ userId, deviceId: req.device.id, title: 'Presence check-in' });
  }

  const deviceContext = {
    id: req.device.id, name: req.device.name, device_type: req.device.device_type,
    capabilities: JSON.parse(req.device.capabilities || '[]'),
  };

  const result = await generatePresenceReaction({ userId, conversationId, imageBase64, deviceContext });

  db.prepare(`INSERT INTO audit_log (id, user_id, device_id, event_type, detail) VALUES (?, ?, ?, 'presence_trigger', ?)`)
    .run(randomUUID(), userId, req.device.id, JSON.stringify({ resultOk: result.ok }));

  if (!result.ok) return res.status(502).json({ ok: false, status: result.status, error: result.error, conversationId });

  db.prepare(`UPDATE devices SET last_presence_trigger_at = datetime('now') WHERE id = ?`).run(req.device.id);
  res.json({ ok: true, conversationId, reply: result.content });
});
