import { Router } from 'express';
import { randomUUID } from 'crypto';
import { db } from '../db/index.js';

export const usersRouter = Router();

usersRouter.post('/', (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ ok: false, error: 'name required' });
  const id = randomUUID();
  db.prepare(`INSERT INTO users (id, name) VALUES (?, ?)`).run(id, name);
  res.json({ ok: true, id });
});
