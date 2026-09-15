import { Router } from 'express';
import { requireApprovedDevice } from '../middleware/requireApprovedDevice.js';
import { storeMemory, retrieveRelevantMemories, deleteMemory, searchMemories } from '../services/memory/memoryService.js';

export const memoryRouter = Router();

memoryRouter.post('/', requireApprovedDevice, (req, res) => {
  const { content, category, importance } = req.body;
  if (!content || !category) return res.status(400).json({ ok: false, error: 'content and category required' });
  const id = storeMemory({ userId: req.device.user_id, content, category, importance, source: 'manual' });
  res.json({ ok: true, id });
});

memoryRouter.get('/', requireApprovedDevice, (req, res) => {
  const { q } = req.query;
  const results = q
    ? searchMemories({ userId: req.device.user_id, term: q })
    : retrieveRelevantMemories({ userId: req.device.user_id, queryText: null, limit: 50 });
  res.json({ ok: true, memories: results });
});

memoryRouter.delete('/:id', requireApprovedDevice, (req, res) => {
  deleteMemory(req.params.id);
  res.json({ ok: true });
});
