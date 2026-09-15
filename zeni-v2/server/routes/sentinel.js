import { Router } from 'express';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';
import { checkIpReputation, scanLink, logSecurityEvent, getRecentSecurityEvents } from '../services/sentinel/sentinelService.js';

export const sentinelRouter = Router();

sentinelRouter.get('/ip-lookup/:ip', requireApprovedDevice, async (req, res) => {
  const result = await checkIpReputation(req.params.ip);
  if (result.ok) {
    logSecurityEvent({ userId: req.device.user_id, deviceId: req.device.id, eventType: 'ip_lookup', detail: { ip: req.params.ip } });
  }
  res.json(result);
});

sentinelRouter.post('/scan-link', requireApprovedDevice, async (req, res) => {
  const { url } = req.body;
  if (!url) return res.status(400).json({ ok: false, error: 'url required' });
  const result = await scanLink(url);
  logSecurityEvent({ userId: req.device.user_id, deviceId: req.device.id, eventType: 'link_scan_requested', detail: { url } });
  res.json(result);
});

sentinelRouter.get('/events', requireApprovedDevice, (req, res) => {
  const events = getRecentSecurityEvents(req.device.user_id);
  res.json({ ok: true, events });
});
