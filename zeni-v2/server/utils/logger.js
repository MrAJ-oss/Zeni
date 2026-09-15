// utils/logger.js
// Structured logging used everywhere. Never log raw request bodies that might
// contain API keys/tokens/passwords — use logger.redact() for anything close to secrets.

import { config } from '../config/index.js';

const LEVELS = { error: 0, warn: 1, info: 2, debug: 3 };
const currentLevel = LEVELS[config.logging.level] ?? LEVELS.info;

const SECRET_KEYS = ['password', 'apikey', 'api_key', 'token', 'secret', 'authorization'];

function redact(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  const clone = Array.isArray(obj) ? [] : {};
  for (const [k, v] of Object.entries(obj)) {
    if (SECRET_KEYS.some(s => k.toLowerCase().includes(s))) {
      clone[k] = '[REDACTED]';
    } else if (typeof v === 'object' && v !== null) {
      clone[k] = redact(v);
    } else {
      clone[k] = v;
    }
  }
  return clone;
}

function emit(level, service, message, meta) {
  if (LEVELS[level] > currentLevel) return;
  const entry = {
    ts: new Date().toISOString(),
    level,
    service,
    message,
    ...(meta ? { meta: redact(meta) } : {}),
  };
  const line = JSON.stringify(entry);
  if (level === 'error') console.error(line);
  else if (level === 'warn') console.warn(line);
  else console.log(line);
}

export function createLogger(service) {
  return {
    error: (message, meta) => emit('error', service, message, meta),
    warn: (message, meta) => emit('warn', service, message, meta),
    info: (message, meta) => emit('info', service, message, meta),
    debug: (message, meta) => emit('debug', service, message, meta),
    redact,
  };
}
