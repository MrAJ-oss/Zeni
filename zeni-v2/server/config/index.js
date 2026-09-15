// config/index.js
// SINGLE source of truth for all configuration.
// Nothing else in the codebase should call process.env directly.
// If a value is missing and required, we fail loudly at boot — not silently at runtime.

import dotenv from 'dotenv';
dotenv.config();

function required(name) {
  const val = process.env[name];
  if (!val) {
    console.error(`[CONFIG] Missing required env var: ${name}`);
    console.error(`[CONFIG] Copy .env.example to .env and fill it in.`);
    process.exit(1);
  }
  return val;
}

function optional(name, fallback = undefined) {
  return process.env[name] ?? fallback;
}

export const config = {
  env: optional('NODE_ENV', 'development'),
  isProd: optional('NODE_ENV', 'development') === 'production',

  server: {
    port: parseInt(optional('PORT', '3000'), 10),
  },

  security: {
    // Password/passphrase that gates privileged actions (device approval, etc.)
    mainPassword: optional('MAIN_PASSWORD', null),
    jwtSecret: optional('JWT_SECRET', null),
  },

  ai: {
    // OpenRouter is the ONLY model provider integration point.
    // Nothing else in the app should import an SDK for a specific model.
    openRouterApiKey: optional('OPENROUTER_API_KEY', null),
    openRouterBaseUrl: optional('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1'),
    defaultModel: optional('ZENI_DEFAULT_MODEL', 'openai/gpt-4o-mini'),
    // Fallback model if the primary is down/rate-limited
    fallbackModel: optional('ZENI_FALLBACK_MODEL', 'anthropic/claude-3.5-haiku'),
    // Vision-capable model for camera-triggered reactions. Defaults to
    // OpenRouter's free auto-router so this costs nothing out of the box —
    // override if you want a specific pinned model instead.
    visionModel: optional('ZENI_VISION_MODEL', 'openrouter/free'),
    // Server-side web search — billed through the same OpenRouter key, no
    // separate provider/account needed. Model decides when to actually search.
    webSearchEnabled: optional('ZENI_WEB_SEARCH_ENABLED', 'true') === 'true',
  },

  voice: {
    // TTS: ElevenLabs if configured (confirmed Marathi/Hindi/Japanese/English
    // support, voice cloning available), otherwise falls back to OpenRouter's
    // own /audio/speech — same key already required, no extra signup.
    elevenLabsApiKey: optional('ELEVENLABS_API_KEY', null),
    elevenLabsVoiceId: optional('ELEVENLABS_VOICE_ID', null),
    openRouterTtsModel: optional('ZENI_TTS_MODEL', 'openai/tts-1'),
    openRouterTtsVoice: optional('ZENI_TTS_VOICE', 'nova'),
    // STT: OpenRouter's own Whisper endpoint — same key as everything else.
    sttModel: optional('ZENI_STT_MODEL', 'openai/whisper-large-v3-turbo'),
  },

  nova: {
    // Emotion service — separate deployment, may be absent in dev.
    baseUrl: optional('NOVA_SERVICE_URL', null),
    apiKey: optional('NOVA_API_KEY', null),
    enabled: !!optional('NOVA_SERVICE_URL', null),
  },

  voiceAuth: {
    baseUrl: optional('VOICE_AUTH_SERVICE_URL', null),
    apiKey: optional('VOICE_AUTH_API_KEY', null),
    enabled: !!optional('VOICE_AUTH_SERVICE_URL', null),
  },

  pcAgent: {
    // The main server never dials OUT to a PC agent directly (agents may be
    // behind NAT/firewalls). Agents connect IN via websocket and register.
    // This is just the shared secret used to authenticate agent connections.
    agentSharedSecret: optional('PC_AGENT_SHARED_SECRET', null),
  },

  db: {
    // SQLite file path for dev/small deployments. Swappable for Postgres later
    // by changing this one value + the db/index.js driver — nothing else changes.
    path: optional('DB_PATH', './data/zeni.db'),
  },

  logging: {
    level: optional('LOG_LEVEL', 'info'), // error | warn | info | debug
  },
};

// Fail fast in production if critical secrets are missing.
export function validateConfig() {
  const problems = [];
  if (!config.ai.openRouterApiKey) problems.push('OPENROUTER_API_KEY is not set — AI brain will not function.');
  if (config.isProd && !config.security.mainPassword) problems.push('MAIN_PASSWORD is not set — privileged actions unprotected.');
  if (config.isProd && !config.security.jwtSecret) problems.push('JWT_SECRET is not set — sessions cannot be signed securely.');

  if (problems.length) {
    console.warn('[CONFIG] Warnings:');
    problems.forEach(p => console.warn('  - ' + p));
  }
  return problems;
}
