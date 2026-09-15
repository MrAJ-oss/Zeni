// services/memory/memoryService.js
// Long-term memory: storage, retrieval, relevance ranking, dedup.
// This is DELIBERATELY separate from conversation history (see services/conversation).
// Memory answers "what should Zeni remember?" not "what was literally said?"

import { randomUUID } from 'crypto';
import { db } from '../../db/index.js';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('memory-service');

export function storeMemory({ userId, content, category, source = null, importance = 5 }) {
  // Basic dedup: skip if a near-identical memory already exists for this user+category
  const existing = db.prepare(
    `SELECT id FROM memories WHERE user_id = ? AND category = ? AND content = ?`
  ).get(userId, category, content);

  if (existing) {
    db.prepare(`UPDATE memories SET updated_at = datetime('now') WHERE id = ?`).run(existing.id);
    return existing.id;
  }

  const id = randomUUID();
  db.prepare(
    `INSERT INTO memories (id, user_id, content, category, source, importance) VALUES (?, ?, ?, ?, ?, ?)`
  ).run(id, userId, content, category, source, importance);
  logger.info('memory stored', { userId, category });
  return id;
}

// TF-IDF cosine similarity over the user's own memory set, computed on the fly.
// No external embedding API — this is a real, if simple, relevance ranking,
// not the naive substring-overlap it replaces.
export function retrieveRelevantMemories({ userId, queryText, limit = 8 }) {
  const all = db.prepare(
    `SELECT * FROM memories WHERE user_id = ? ORDER BY importance DESC, updated_at DESC LIMIT 200`
  ).all(userId);

  if (!queryText || all.length === 0) return all.slice(0, limit);

  const tokenize = (text) => text.toLowerCase().match(/[a-z0-9]+/g) || [];
  const docs = all.map(m => tokenize(m.content));
  const queryTokens = tokenize(queryText);

  const df = new Map();
  docs.forEach(doc => {
    new Set(doc).forEach(term => df.set(term, (df.get(term) || 0) + 1));
  });
  const N = docs.length;
  const idf = (term) => Math.log((N + 1) / ((df.get(term) || 0) + 1)) + 1;

  function vectorize(tokens) {
    const tf = new Map();
    tokens.forEach(t => tf.set(t, (tf.get(t) || 0) + 1));
    const vec = new Map();
    tf.forEach((count, term) => vec.set(term, (count / tokens.length) * idf(term)));
    return vec;
  }

  function cosineSim(vecA, vecB) {
    let dot = 0, magA = 0, magB = 0;
    vecA.forEach((val, term) => {
      magA += val * val;
      if (vecB.has(term)) dot += val * vecB.get(term);
    });
    vecB.forEach(val => { magB += val * val; });
    if (magA === 0 || magB === 0) return 0;
    return dot / (Math.sqrt(magA) * Math.sqrt(magB));
  }

  const queryVec = vectorize(queryTokens);
  const scored = all.map((m, i) => {
    const sim = cosineSim(queryVec, vectorize(docs[i]));
    return { ...m, score: sim * 10 + m.importance * 0.1 };
  });

  scored.sort((a, b) => b.score - a.score);
  const top = scored.slice(0, limit);

  const markUsed = db.prepare(`UPDATE memories SET last_used_at = datetime('now') WHERE id = ?`);
  top.forEach(m => markUsed.run(m.id));

  return top;
}

export function deleteMemory(id) {
  return db.prepare(`DELETE FROM memories WHERE id = ?`).run(id);
}

export function searchMemories({ userId, term }) {
  return db.prepare(
    `SELECT * FROM memories WHERE user_id = ? AND content LIKE ? ORDER BY updated_at DESC`
  ).all(userId, `%${term}%`);
}
