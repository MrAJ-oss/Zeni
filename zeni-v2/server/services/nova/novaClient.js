import { config } from '../../config/index.js';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('nova-client');

export async function analyzeEmotion({ text, userId }) {
  if (!config.nova.enabled) {
    return { ok: false, status: 'NOT_IMPLEMENTED', reason: 'NOVA_SERVICE_URL not configured' };
  }

  try {
    const res = await fetch(`${config.nova.baseUrl}/analyze`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${config.nova.apiKey}` },
      body: JSON.stringify({ text, userId }),
    });
    if (!res.ok) return { ok: false, status: 'SERVICE_ERROR', code: res.status };
    const data = await res.json();
    return { ok: true, emotionalState: data.state, intensity: data.intensity, confidence: data.confidence };
  } catch (err) {
    logger.error('nova request failed', { message: err.message });
    return { ok: false, status: 'SERVICE_UNREACHABLE' };
  }
}
