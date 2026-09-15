// db/index.js
// Single database connection point. Everything else imports `db` from here —
// nothing else should open its own connection or hardcode the driver.
// Swapping SQLite -> Postgres later means changing THIS file only.

import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { config } from '../config/index.js';
import { createLogger } from '../utils/logger.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const logger = createLogger('db');

// Ensure the data directory exists
const dbDir = path.dirname(config.db.path);
if (!fs.existsSync(dbDir)) fs.mkdirSync(dbDir, { recursive: true });

export const db = new Database(config.db.path);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Schema must exist before any other module (tool registrations, etc.) can use
// the db. ES module imports resolve before top-level code in index.js runs, so
// this cannot wait to be called manually from index.js — it runs on import.
const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf-8');
db.exec(schema);
logger.info('database initialized', { path: config.db.path });

export function initDb() {
  // kept as a no-op export for explicitness at the call site in index.js
}

export function healthCheck() {
  try {
    db.prepare('SELECT 1').get();
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err.message };
  }
}
