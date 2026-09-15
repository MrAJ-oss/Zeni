-- Zeni core database schema.
-- One table per core entity from the spec. Do NOT add a new table per feature —
-- extend an existing entity or use the `metadata` JSON column for feature-specific data.

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  preferences TEXT NOT NULL DEFAULT '{}'   -- JSON blob: communication style, defaults, etc.
);

CREATE TABLE IF NOT EXISTS devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,                       -- user-given, e.g. "My Windows PC"
  device_type TEXT NOT NULL,                -- pc | mobile | tablet | web
  capabilities TEXT NOT NULL DEFAULT '[]',  -- JSON array of capability strings
  status TEXT NOT NULL DEFAULT 'pending',   -- pending | approved | revoked
  last_seen_at TEXT,
  last_geofence_trigger_at TEXT,
  last_presence_trigger_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS conversations (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  device_id TEXT REFERENCES devices(id),
  title TEXT,
  started_at TEXT NOT NULL DEFAULT (datetime('now')),
  last_message_at TEXT
);

CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL REFERENCES conversations(id),
  role TEXT NOT NULL,                       -- user | assistant | tool | system
  content TEXT NOT NULL,
  metadata TEXT NOT NULL DEFAULT '{}',      -- JSON: tool_calls, emotion snapshot, etc.
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS memories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  content TEXT NOT NULL,
  category TEXT NOT NULL,                   -- preference | project | relationship | fact | emotional
  source TEXT,                              -- conversation id or 'manual'
  importance INTEGER NOT NULL DEFAULT 5,    -- 1-10, used for relevance ranking
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  last_used_at TEXT
);

CREATE TABLE IF NOT EXISTS projects (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'active',    -- active | paused | done
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id),
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',      -- open | in_progress | done
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS tools (
  name TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  input_schema TEXT NOT NULL,               -- JSON schema
  risk_level TEXT NOT NULL DEFAULT 'low',   -- low | medium | high
  requires_approval INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS auth_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  device_id TEXT REFERENCES devices(id),
  method TEXT NOT NULL,                     -- password | voice | token
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  expires_at TEXT
);

CREATE TABLE IF NOT EXISTS emotion_records (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  conversation_id TEXT REFERENCES conversations(id),
  source TEXT NOT NULL,                     -- text | voice
  emotional_state TEXT,
  intensity REAL,
  confidence REAL,
  raw_output TEXT,                          -- JSON from NOVA
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS automations (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  instruction TEXT NOT NULL,
  resolved_action TEXT NOT NULL,            -- JSON: structured tool call(s)
  status TEXT NOT NULL DEFAULT 'pending',   -- pending | approved | executed | rejected | failed
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  executed_at TEXT
);

CREATE TABLE IF NOT EXISTS audit_log (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  device_id TEXT,
  event_type TEXT NOT NULL,                 -- tool_call | device_approval | auth | error | ...
  detail TEXT NOT NULL DEFAULT '{}',        -- JSON, redacted of secrets before insert
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS teacher_progress (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  subject TEXT NOT NULL,
  sessions_count INTEGER NOT NULL DEFAULT 0,
  last_session_at TEXT,
  UNIQUE(user_id, subject)
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_memories_user ON memories(user_id, category);
CREATE INDEX IF NOT EXISTS idx_devices_user ON devices(user_id, status);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_log(created_at);
