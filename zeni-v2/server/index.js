import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import { config, validateConfig } from './config/index.js';
import { initDb, healthCheck } from './db/index.js';
import { createLogger } from './utils/logger.js';
import { usersRouter } from './routes/users.js';
import { devicesRouter } from './routes/devices.js';
import { chatRouter } from './routes/chat.js';
import { memoryRouter } from './routes/memory.js';
import { projectsRouter } from './routes/projects.js';
import { sentinelRouter } from './routes/sentinel.js';
import { teacherRouter } from './routes/teacher.js';
import { automationRouter } from './routes/automation.js';
import { automationsRouter } from './routes/automations.js';
import { voiceAuthRouter } from './routes/voiceAuth.js';
import { voiceRouter } from './routes/voice.js';
import { registerAgentSocket } from './services/pcAgent/agentGateway.js';
import { requireApprovedDevice } from './middleware/requireApprovedDevice.js';
import './services/tools/builtinTools.js';
import './services/tools/visualTool.js';

const logger = createLogger('server');

validateConfig();
initDb();

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    logger.info('request', { method: req.method, path: req.path, status: res.statusCode, ms: Date.now() - start });
  });
  next();
});

app.get('/health', (req, res) => {
  const db_ = healthCheck();
  res.json({
    ok: db_.ok,
    services: {
      database: db_.ok ? 'up' : 'down',
      ai_provider: config.ai.openRouterApiKey ? 'configured' : 'not_configured',
      nova: config.nova.enabled ? 'configured' : 'not_configured',
      voice_auth: config.voiceAuth.enabled ? 'configured' : 'not_configured',
    },
  });
});

app.use('/users', usersRouter);
app.use('/devices', devicesRouter);
app.use('/chat', chatRouter);
app.use('/memory', memoryRouter);
app.use('/projects', projectsRouter);
app.use('/sentinel', sentinelRouter);
app.use('/teacher', teacherRouter);
app.use('/automation', automationRouter);
app.use('/automations', automationsRouter);
app.use('/voice-auth', voiceAuthRouter);
app.use('/voice', voiceRouter);

app.use((err, req, res, next) => {
  logger.error('unhandled error', { message: err.message, path: req.path });
  res.status(500).json({ ok: false, error: 'internal_error' });
});

const httpServer = createServer(app);
const wss = new WebSocketServer({ server: httpServer, path: '/agent' });

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, 'http://localhost');
  const deviceId = url.searchParams.get('deviceId');
  const sharedSecret = url.searchParams.get('secret');
  if (!deviceId) { ws.close(4000, 'missing_device_id'); return; }
  registerAgentSocket(ws, { deviceId, sharedSecret });
});

httpServer.listen(config.server.port, () => {
  logger.info('zeni server started', { port: config.server.port, env: config.env });
});
