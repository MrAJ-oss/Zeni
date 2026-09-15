import { randomUUID } from 'crypto';
import { db } from '../../db/index.js';
import { routeRequest } from '../ai/modelRouter.js';
import { getResponse } from '../ai/aiService.js';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('teacher-service');

export const SUBJECTS = ['Math', 'Science', 'History', 'English', 'Coding', 'Physics', 'Chemistry', 'Biology'];
const MODES = ['chat', 'explain', 'solve', 'quiz'];

export async function handleTeacherMessage({ userId, conversationId, message, subject, mode, deviceContext }) {
  if (!SUBJECTS.includes(subject)) {
    return { ok: false, status: 'INVALID_SUBJECT' };
  }
  if (!MODES.includes(mode)) {
    return { ok: false, status: 'INVALID_MODE' };
  }

  recordSession(userId, subject);

  const modeInstruction = {
    chat: `Teacher mode, subject: ${subject}. Have a normal conversational discussion about the subject.`,
    explain: `Teacher mode, subject: ${subject}. Break the concept down step by step, building from fundamentals.`,
    solve: `Teacher mode, subject: ${subject}. Show full worked steps to the problem, not just the final answer.`,
    quiz: `Teacher mode, subject: ${subject}. The user is answering a quiz question — evaluate their answer and explain why it is right or wrong.`,
  }[mode];

  return getResponse({
    userId,
    conversationId,
    userMessage: message,
    deviceContext,
    emotionalContext: null,
    mode: modeInstruction,
  });
}

// Structured generation — deliberately bypasses the conversational aiService
// and talks to the model router directly, since this needs parseable JSON,
// not a personality-flavored reply.
export async function generateQuizQuestion({ subject, difficulty = 'medium' }) {
  if (!SUBJECTS.includes(subject)) {
    return { ok: false, status: 'INVALID_SUBJECT' };
  }

  const systemPrompt = `Generate one ${difficulty} multiple-choice question for the subject "${subject}". ` +
    `Respond with ONLY valid JSON, no markdown, no commentary, in this exact shape: ` +
    `{"question": string, "options": [string, string, string, string], "correctIndex": number, "explanation": string}`;

  const result = await routeRequest({
    messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: 'Generate the question now.' }],
    maxTokens: 400,
    temperature: 0.9,
  });

  if (!result.ok) {
    return { ok: false, status: result.status || 'AI_UNAVAILABLE', error: result.error };
  }

  try {
    const cleaned = result.content.trim().replace(/^```json\s*|```$/g, '');
    const parsed = JSON.parse(cleaned);
    if (!parsed.question || !Array.isArray(parsed.options) || typeof parsed.correctIndex !== 'number') {
      return { ok: false, status: 'MALFORMED_RESPONSE' };
    }
    return { ok: true, quiz: parsed };
  } catch (err) {
    logger.error('quiz JSON parse failed', { message: err.message });
    return { ok: false, status: 'MALFORMED_RESPONSE' };
  }
}

function recordSession(userId, subject) {
  const existing = db.prepare(`SELECT id FROM teacher_progress WHERE user_id = ? AND subject = ?`).get(userId, subject);
  if (existing) {
    db.prepare(`UPDATE teacher_progress SET sessions_count = sessions_count + 1, last_session_at = datetime('now') WHERE id = ?`)
      .run(existing.id);
  } else {
    db.prepare(`INSERT INTO teacher_progress (id, user_id, subject, sessions_count, last_session_at) VALUES (?, ?, ?, 1, datetime('now'))`)
      .run(randomUUID(), userId, subject);
  }
}

export function getProgress(userId) {
  return db.prepare(`SELECT subject, sessions_count, last_session_at FROM teacher_progress WHERE user_id = ?`).all(userId);
}
