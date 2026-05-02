const db = require('../config/db');
const { success, error } = require('../utils/responseHelper');

// ============================================
// HELPER: Hitung priority dinamis dari deadline
// Semakin dekat deadline → semakin tinggi priority
// ============================================
const calculatePriority = (deadline) => {
  if (!deadline) return 'none'; // tidak ada deadline = tidak ada priority
  const now      = new Date();
  const end      = new Date(deadline);
  const diffMs   = end - now;
  const diffDays = diffMs / (1000 * 60 * 60 * 24);

  if (diffMs < 0)        return 'overdue';  // sudah lewat deadline
  if (diffDays < 1)      return 'critical'; // kurang dari 1 hari
  if (diffDays < 3)      return 'high';     // 1–3 hari
  if (diffDays < 7)      return 'medium';   // 3–7 hari
  return                        'low';      // lebih dari 7 hari
};

// ============================================
// HELPER: Hitung reminder_at otomatis dari deadline + priority
// ============================================
const calculateReminder = (deadline, priority) => {
  if (!deadline) return null;
  const now = new Date();
  const due = new Date(deadline);
  let reminder = new Date(deadline);

  if (priority === 'critical') reminder.setHours(reminder.getHours() - 1); // -1 jam
  else if (priority === 'high') reminder.setHours(reminder.getHours() - 6); // -6 jam
  else if (priority === 'medium') reminder.setDate(reminder.getDate() - 1); // -1 hari
  else if (priority === 'low') reminder.setDate(reminder.getDate() - 3); // -3 hari
  else return null;

  if (due <= now) return null;
  if (reminder <= now) {
    const oneMinuteFromNow = new Date(now.getTime() + 60 * 1000);
    return oneMinuteFromNow < due ? oneMinuteFromNow : due;
  }

  return reminder;
};

// ============================================
// HELPER: Tambahkan priority, progress, reminder ke task
// ============================================
const enrichTask = (task, subs = []) => {
  const priority = calculatePriority(task.deadline);

  // Hitung reminder otomatis jika belum diisi manual
  const reminder = task.reminder_at || calculateReminder(task.deadline, priority);

  // Hitung progress dari sub-task
  const total    = subs.length;
  const done     = subs.filter(s => s.status === 'done').length;
  const progress = total > 0 ? Math.round((done / total) * 100) : null;

  // Tambahkan priority ke masing-masing sub-task juga
  const enrichedSubs = subs.map(s => ({
    ...s,
    priority: calculatePriority(s.deadline),
  }));

  return {
    ...task,
    priority,
    reminder_at: reminder,
    progress,
    sub_tasks: enrichedSubs,
  };
};

// ============================================
// GET /api/tasks
// ============================================
const getAll = async (req, res, next) => {
  try {
    const { status, priority, category_id, date, search } = req.query;

    let query = `SELECT t.*, c.name AS category_name, c.color AS category_color
                 FROM tasks t
                 LEFT JOIN categories c ON t.category_id = c.id
                 WHERE t.user_id = ? AND t.is_deleted = 0 AND t.parent_id IS NULL`;
    const params = [req.user.id];

    if (status)      { query += ' AND t.status = ?';         params.push(status); }
    if (category_id) { query += ' AND t.category_id = ?';    params.push(category_id); }
    if (date)        { query += ' AND DATE(t.deadline) = ?'; params.push(date); }
    if (search)      { query += ' AND t.title LIKE ?';       params.push(`%${search}%`); }

    query += ' ORDER BY t.deadline ASC, t.created_at DESC';

    const [tasks] = await db.query(query, params);

    // Enrich setiap task dengan priority, progress, reminder
    const enriched = [];
    for (const task of tasks) {
      const [subs] = await db.query(
        'SELECT * FROM tasks WHERE parent_id = ? AND is_deleted = 0 ORDER BY created_at ASC',
        [task.id]
      );
      const enrichedTask = enrichTask(task, subs);

      // Filter by priority (dilakukan setelah kalkulasi)
      if (priority && enrichedTask.priority !== priority) continue;

      enriched.push(enrichedTask);
    }

    return success(res, enriched);
  } catch (err) { next(err); }
};

// ============================================
// GET /api/tasks/:id
// ============================================
const getOne = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT t.*, c.name AS category_name, c.color AS category_color
       FROM tasks t
       LEFT JOIN categories c ON t.category_id = c.id
       WHERE t.id = ? AND t.user_id = ? AND t.is_deleted = 0`,
      [req.params.id, req.user.id]
    );
    if (rows.length === 0) return error(res, 'Task tidak ditemukan', 404);

    const [subs] = await db.query(
      'SELECT * FROM tasks WHERE parent_id = ? AND is_deleted = 0 ORDER BY created_at ASC',
      [rows[0].id]
    );

    return success(res, enrichTask(rows[0], subs));
  } catch (err) { next(err); }
};

// ============================================
// POST /api/tasks
// ============================================
const create = async (req, res, next) => {
  try {
    const { title, description, category_id, status, deadline, reminder_at, parent_id } = req.body;
    if (!title) return error(res, 'Judul task wajib diisi', 400);

    // Validasi parent_id
    if (parent_id) {
      const [parent] = await db.query(
        'SELECT id FROM tasks WHERE id = ? AND user_id = ? AND is_deleted = 0',
        [parent_id, req.user.id]
      );
      if (parent.length === 0) return error(res, 'Parent task tidak ditemukan', 404);
    }

    // Hitung reminder otomatis jika tidak diisi manual
    const priority      = calculatePriority(deadline || null);
    const autoReminder  = reminder_at || calculateReminder(deadline || null, priority);

    const [result] = await db.query(
      `INSERT INTO tasks (user_id, category_id, parent_id, title, description, status, deadline, reminder_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        category_id  || null,
        parent_id    || null,
        title,
        description  || null,
        status       || 'todo',
        deadline     || null,
        autoReminder || null,
      ]
    );

    const [rows] = await db.query('SELECT * FROM tasks WHERE id = ?', [result.insertId]);
    return success(res, enrichTask(rows[0], []), 'Task berhasil dibuat', 201);
  } catch (err) { next(err); }
};

// ============================================
// PUT /api/tasks/:id
// ============================================
const update = async (req, res, next) => {
  try {
    const [existing] = await db.query(
      'SELECT * FROM tasks WHERE id = ? AND user_id = ? AND is_deleted = 0',
      [req.params.id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Task tidak ditemukan', 404);

    const t = existing[0];
    const { title, description, category_id, status, deadline, reminder_at } = req.body;

    const newDeadline   = deadline     !== undefined ? deadline    : t.deadline;
    const priority      = calculatePriority(newDeadline);
    const autoReminder  = reminder_at  !== undefined ? reminder_at : calculateReminder(newDeadline, priority);

    await db.query(
      `UPDATE tasks SET title=?, description=?, category_id=?, status=?, deadline=?, reminder_at=?
       WHERE id = ?`,
      [
        title       || t.title,
        description !== undefined ? description : t.description,
        category_id !== undefined ? category_id : t.category_id,
        status      || t.status,
        newDeadline,
        autoReminder,
        req.params.id,
      ]
    );

    const [rows] = await db.query('SELECT * FROM tasks WHERE id = ?', [req.params.id]);
    const [subs] = await db.query(
      'SELECT * FROM tasks WHERE parent_id = ? AND is_deleted = 0', [req.params.id]
    );
    return success(res, enrichTask(rows[0], subs), 'Task berhasil diperbarui');
  } catch (err) { next(err); }
};

// ============================================
// PATCH /api/tasks/:id/status
// ============================================
const updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const allowed = ['todo', 'in_progress', 'done'];
    if (!status || !allowed.includes(status))
      return error(res, 'Status tidak valid. Gunakan: todo, in_progress, done', 400);

    const [existing] = await db.query(
      'SELECT * FROM tasks WHERE id = ? AND user_id = ? AND is_deleted = 0',
      [req.params.id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Task tidak ditemukan', 404);

    await db.query('UPDATE tasks SET status = ? WHERE id = ?', [status, req.params.id]);

    // Auto-update status parent jika semua sub-task selesai
    const parentId = existing[0].parent_id;
    if (parentId) {
      const [siblings] = await db.query(
        'SELECT status FROM tasks WHERE parent_id = ? AND is_deleted = 0',
        [parentId]
      );
      const allDone        = siblings.every(s => s.status === 'done');
      const anyInProgress  = siblings.some(s => s.status === 'in_progress');

      if (allDone) {
        await db.query('UPDATE tasks SET status = "done" WHERE id = ?', [parentId]);
      } else if (anyInProgress) {
        await db.query('UPDATE tasks SET status = "in_progress" WHERE id = ?', [parentId]);
      }
    }

    return success(res, {}, 'Status berhasil diperbarui');
  } catch (err) { next(err); }
};

// ============================================
// DELETE /api/tasks/:id (soft delete)
// ============================================
const remove = async (req, res, next) => {
  try {
    const [existing] = await db.query(
      'SELECT id FROM tasks WHERE id = ? AND user_id = ? AND is_deleted = 0',
      [req.params.id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Task tidak ditemukan', 404);

    await db.query(
      'UPDATE tasks SET is_deleted = 1 WHERE id = ? OR parent_id = ?',
      [req.params.id, req.params.id]
    );
    return success(res, {}, 'Task berhasil dihapus');
  } catch (err) { next(err); }
};

module.exports = { getAll, getOne, create, update, updateStatus, remove };
