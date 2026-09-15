import { Router } from 'express';
import { randomUUID } from 'crypto';
import { db } from '../db/index.js';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';

export const projectsRouter = Router();

projectsRouter.post('/', requireApprovedDevice, (req, res) => {
  const { name, description } = req.body;
  if (!name) return res.status(400).json({ ok: false, error: 'name required' });
  const id = randomUUID();
  db.prepare(`INSERT INTO projects (id, user_id, name, description) VALUES (?, ?, ?, ?)`)
    .run(id, req.device.user_id, name, description || null);
  res.json({ ok: true, id });
});

projectsRouter.get('/', requireApprovedDevice, (req, res) => {
  const projects = db.prepare(`SELECT * FROM projects WHERE user_id = ? ORDER BY updated_at DESC`)
    .all(req.device.user_id);
  res.json({ ok: true, projects });
});

projectsRouter.post('/:id/tasks', requireApprovedDevice, (req, res) => {
  const { title, notes } = req.body;
  if (!title) return res.status(400).json({ ok: false, error: 'title required' });
  const id = randomUUID();
  db.prepare(`INSERT INTO tasks (id, project_id, title, notes) VALUES (?, ?, ?, ?)`)
    .run(id, req.params.id, title, notes || null);
  res.json({ ok: true, id });
});

projectsRouter.get('/:id/tasks', requireApprovedDevice, (req, res) => {
  const tasks = db.prepare(`SELECT * FROM tasks WHERE project_id = ? ORDER BY created_at`).all(req.params.id);
  res.json({ ok: true, tasks });
});
