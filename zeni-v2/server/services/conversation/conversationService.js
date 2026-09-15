// services/conversation/conversationService.js
// Conversation/message storage. Answers "what was said?" — NOT "what should be
// remembered?" (that's memoryService). Do not blend the two concepts here.

import { randomUUID } from 'crypto';
import { db } from '../../db/index.js';

export function createConversation({ userId, deviceId = null, title = null }) {
  const id = randomUUID();
  db.prepare(
    `INSERT INTO conversations (id, user_id, device_id, title) VALUES (?, ?, ?, ?)`
  ).run(id, userId, deviceId, title);
  return id;
}

export function addMessage({ conversationId, role, content, metadata = {} }) {
  const id = randomUUID();
  db.prepare(
    `INSERT INTO messages (id, conversation_id, role, content, metadata) VALUES (?, ?, ?, ?, ?)`
  ).run(id, conversationId, role, content, JSON.stringify(metadata));
  db.prepare(
    `UPDATE conversations SET last_message_at = datetime('now') WHERE id = ?`
  ).run(conversationId);
  return id;
}

// Recent messages formatted for the AI provider's message array.
export function getRecentMessages({ conversationId, limit = 20 }) {
  const rows = db.prepare(
    `SELECT role, content FROM messages WHERE conversation_id = ? ORDER BY created_at DESC LIMIT ?`
  ).all(conversationId, limit);
  return rows.reverse().map(r => ({ role: r.role, content: r.content }));
}

export function getConversation(id) {
  return db.prepare(`SELECT * FROM conversations WHERE id = ?`).get(id);
}

export function listConversations(userId) {
  return db.prepare(
    `SELECT * FROM conversations WHERE user_id = ? ORDER BY last_message_at DESC`
  ).all(userId);
}
