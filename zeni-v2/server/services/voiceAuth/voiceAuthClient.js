import { config } from '../../config/index.js';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('voice-auth-client');

export async function verifyVoice({ userId, audioBase64 }) {
  if (!config.voiceAuth.enabled) {
    return { ok: false, status: 'NOT_IMPLEMENTED', reason: 'VOICE_AUTH_SERVICE_URL not configured' };
  }

  try {
    const res = await fetch(`${config.voiceAuth.baseUrl}/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${config.voiceAuth.apiKey}` },
      body: JSON.stringify({ userId, audio: audioBase64 }),
    });
    if (!res.ok) return { ok: false, status: 'SERVICE_ERROR', code: res.status };
    const data = await res.json();
    return { ok: true, verified: data.verified, confidence: data.confidence };
  } catch (err) {
    logger.error('voice auth request failed', { message: err.message });
    return { ok: false, status: 'SERVICE_UNREACHABLE' };
  }
}

export async function enrollVoice({ userId, audioBase64 }) {
  if (!config.voiceAuth.enabled) {
    return { ok: false, status: 'NOT_IMPLEMENTED', reason: 'VOICE_AUTH_SERVICE_URL not configured' };
  }

  try {
    const res = await fetch(`${config.voiceAuth.baseUrl}/enroll`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${config.voiceAuth.apiKey}` },
      body: JSON.stringify({ userId, audio: audioBase64 }),
    });
    if (!res.ok) return { ok: false, status: 'SERVICE_ERROR', code: res.status };
    return { ok: true, enrolled: true };
  } catch (err) {
    logger.error('voice enroll request failed', { message: err.message });
    return { ok: false, status: 'SERVICE_UNREACHABLE' };
  }
}
