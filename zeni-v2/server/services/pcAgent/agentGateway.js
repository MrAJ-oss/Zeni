import { randomUUID } from 'crypto';
import { config } from '../../config/index.js';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('pc-agent-gateway');

const connectedAgents = new Map(); // deviceId -> ws
const pendingRequests = new Map(); // requestId -> {resolve, reject, timeout}

export function registerAgentSocket(ws, { deviceId, sharedSecret }) {
  if (!config.pcAgent.agentSharedSecret || sharedSecret !== config.pcAgent.agentSharedSecret) {
    ws.close(4001, 'invalid_secret');
    return false;
  }
  connectedAgents.set(deviceId, ws);
  logger.info('agent connected', { deviceId });

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch { return; }
    const pending = pendingRequests.get(msg.requestId);
    if (pending) {
      clearTimeout(pending.timeout);
      pendingRequests.delete(msg.requestId);
      pending.resolve(msg);
    }
  });

  ws.on('close', () => {
    connectedAgents.delete(deviceId);
    logger.info('agent disconnected', { deviceId });
  });

  return true;
}

export function isAgentOnline(deviceId) {
  return connectedAgents.has(deviceId);
}

export function dispatchToAgent({ deviceId, command, args, userId, timeoutMs = 10000 }) {
  const ws = connectedAgents.get(deviceId);
  if (!ws) {
    return Promise.resolve({ ok: false, status: 'AGENT_OFFLINE', error: `No connected agent for device ${deviceId}` });
  }

  const requestId = randomUUID();
  return new Promise((resolve) => {
    const timeout = setTimeout(() => {
      pendingRequests.delete(requestId);
      resolve({ ok: false, status: 'AGENT_TIMEOUT' });
    }, timeoutMs);

    pendingRequests.set(requestId, { resolve, timeout });
    ws.send(JSON.stringify({ requestId, command, args, userId }));
  });
}
