const db = require('../config/db');
const { success, error } = require('../utils/responseHelper');
const { normalizeDateTimeInput, parseLocalDateTime, toMysqlDateTime } = require('../utils/dateTimeHelper');

const calculateDeadlineScore = (deadline) => {
  if (!deadline) return 5;
  const now = new Date();
  const due = parseLocalDateTime(deadline);
  if (!due) return 5;
  const diffMs = due - now;
  const diffDays = diffMs / (1000 * 60 * 60 * 24);

  if (diffMs < 0) return 45;
  if (diffDays < 1) return 40;
  if (diffDays < 3) return 32;
  if (diffDays < 7) return 22;
  return 10;
};

const calculateReminder = (deadline, level) => {
  if (!deadline) return null;
  const now = new Date();
  const due = parseLocalDateTime(deadline);
  if (!due) return null;
  const reminder = new Date(due);

  if (level === 'critical') reminder.setHours(reminder.getHours() - 1);
  else if (level === 'high') reminder.setHours(reminder.getHours() - 6);
  else if (level === 'medium') reminder.setDate(reminder.getDate() - 1);
  else reminder.setDate(reminder.getDate() - 3);

  if (due <= now) return null;
  if (reminder <= now) {
    const oneMinuteFromNow = new Date(now.getTime() + 60 * 1000);
    return oneMinuteFromNow < due ? oneMinuteFromNow : due;
  }
  return reminder;
};

const calculateAcademicPriority = (task, progress) => {
  if (task.status === 'done') {
    return { score: 0, level: 'done', label: 'Selesai' };
  }

  const weight = Number(task.grade_weight || 0);
  const difficultyScore = task.difficulty === 'hard' ? 18 : task.difficulty === 'easy' ? 6 : 12;
  const progressPenalty = progress === null ? 12 : Math.round((100 - progress) * 0.18);
  const score = Math.min(
    100,
    Math.round(calculateDeadlineScore(task.deadline) + Math.min(weight, 40) + difficultyScore + progressPenalty)
  );

  const due = task.deadline ? parseLocalDateTime(task.deadline) : null;
  if (due && due < new Date()) {
    return { score, level: 'overdue', label: 'Terlambat' };
  }
  if (score >= 80) return { score, level: 'critical', label: 'Prioritas Ujian' };
  if (score >= 60) return { score, level: 'high', label: 'Sangat Penting' };
  if (score >= 38) return { score, level: 'medium', label: 'Perlu Dijadwalkan' };
  return { score, level: 'low', label: 'Aman' };
};

const enrichTask = (task, subs = []) => {
  const total = subs.length;
  const done = subs.filter((s) => s.status === 'done').length;
  const progress = total > 0 ? Math.round((done / total) * 100) : null;
  const academicPriority = calculateAcademicPriority(task, progress);
  const reminder = task.reminder_at || calculateReminder(task.deadline, academicPriority.level);

  return {
    ...task,
    priority: academicPriority.level,
    academic_priority: academicPriority,
    reminder_at: reminder,
    progress,
    sub_tasks: subs.map((s) => {
      const subPriority = calculateAcademicPriority(s, null);
      return {
        ...s,
        priority: subPriority.level,
        academic_priority: subPriority,
      };
    }),
  };
};

const getAll = async (req, res, next) => {
  try {
    const { status, priority, course_id, date, search } = req.query;

    let query = `SELECT t.*, c.name AS course_name, c.color AS course_color,
                        c.lecturer AS lecturer, c.room AS room
                 FROM tasks t
                 LEFT JOIN courses c ON t.course_id = c.id
                 WHERE t.user_id = ? AND t.is_deleted = 0 AND t.parent_id IS NULL`;
    const params = [req.user.id];

    if (status) {
      query += ' AND t.status = ?';
      params.push(status);
    }
    if (course_id) {
      query += ' AND t.course_id = ?';
      params.push(course_id);
    }
    if (date) {
      query += ' AND DATE(t.deadline) = ?';
      params.push(date);
    }
    if (search) {
      query += ' AND (t.title LIKE ? OR c.name LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    query += ' ORDER BY t.deadline IS NULL, t.deadline ASC, t.created_at DESC';

    const [tasks] = await db.query(query, params);
    const taskIds = tasks.map((task) => task.id);
    const subTaskMap = new Map();

    if (taskIds.length > 0) {
      const placeholders = taskIds.map(() => '?').join(', ');
      const [allSubs] = await db.query(
        `SELECT * FROM tasks
         WHERE parent_id IN (${placeholders}) AND is_deleted = 0
         ORDER BY parent_id ASC, created_at ASC`,
        taskIds
      );

      for (const sub of allSubs) {
        const existing = subTaskMap.get(sub.parent_id) || [];
        existing.push(sub);
        subTaskMap.set(sub.parent_id, existing);
      }
    }

    const enriched = [];
    for (const task of tasks) {
      const item = enrichTask(task, subTaskMap.get(task.id) || []);
      if (priority && item.priority !== priority) continue;
      enriched.push(item);
    }

    enriched.sort((a, b) => b.academic_priority.score - a.academic_priority.score);
    return success(res, enriched);
  } catch (err) {
    next(err);
  }
};

const getOne = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT t.*, c.name AS course_name, c.color AS course_color,
              c.lecturer AS lecturer, c.room AS room
       FROM tasks t
       LEFT JOIN courses c ON t.course_id = c.id
       WHERE t.id = ? AND t.user_id = ? AND t.is_deleted = 0`,
      [req.params.id, req.user.id]
    );
    if (rows.length === 0) return error(res, 'Task akademik tidak ditemukan', 404);

    const [subs] = await db.query(
      'SELECT * FROM tasks WHERE parent_id = ? AND is_deleted = 0 ORDER BY created_at ASC',
      [rows[0].id]
    );
    return success(res, enrichTask(rows[0], subs));
  } catch (err) {
    next(err);
  }
};

const create = async (req, res, next) => {
  try {
    const {
      title,
      description,
      course_id,
      status,
      deadline,
      reminder_at,
      parent_id,
      task_type,
      difficulty,
      grade_weight,
      achieved_score,
    } = req.body;

    if (!title) return error(res, 'Judul task akademik wajib diisi', 400);

    const parsedGradeWeight =
      grade_weight === undefined || grade_weight === null || grade_weight === '' ? 0 : Number(grade_weight);
    if (!Number.isFinite(parsedGradeWeight) || parsedGradeWeight < 0 || parsedGradeWeight > 100) {
      return error(res, 'Bobot nilai harus berupa angka 0-100', 400);
    }

    const parsedAchievedScore =
      achieved_score === undefined || achieved_score === null || achieved_score === '' ? null : Number(achieved_score);
    if (
      parsedAchievedScore !== null &&
      (!Number.isFinite(parsedAchievedScore) || parsedAchievedScore < 0 || parsedAchievedScore > 100)
    ) {
      return error(res, 'Nilai didapat harus berupa angka 0-100', 400);
    }

    if (course_id) {
      const [course] = await db.query(
        'SELECT id FROM courses WHERE id = ? AND user_id = ?',
        [course_id, req.user.id]
      );
      if (course.length === 0) return error(res, 'Mata kuliah tidak ditemukan', 404);
    }

    if (parent_id) {
      const [parent] = await db.query(
        'SELECT id FROM tasks WHERE id = ? AND user_id = ? AND is_deleted = 0',
        [parent_id, req.user.id]
      );
      if (parent.length === 0) return error(res, 'Parent task tidak ditemukan', 404);
    }

    const nextDeadline = normalizeDateTimeInput(deadline);
    const taskDraft = {
      deadline: nextDeadline,
      status: status || 'todo',
      difficulty: difficulty || 'medium',
      grade_weight: parsedGradeWeight,
    };
    const automaticPriority = calculateAcademicPriority(taskDraft, null);
    const automaticReminder = calculateReminder(taskDraft.deadline, automaticPriority.level);
    const nextReminder = normalizeDateTimeInput(reminder_at) || toMysqlDateTime(automaticReminder);

    const [result] = await db.query(
      `INSERT INTO tasks
       (user_id, course_id, parent_id, title, description, task_type, status, difficulty,
        grade_weight, achieved_score, deadline, reminder_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        course_id || null,
        parent_id || null,
        title,
        description || null,
        task_type || 'assignment',
        status || 'todo',
        difficulty || 'medium',
        parsedGradeWeight,
        parsedAchievedScore,
        nextDeadline,
        nextReminder,
      ]
    );

    const [rows] = await db.query('SELECT * FROM tasks WHERE id = ?', [result.insertId]);
    return success(res, enrichTask(rows[0], []), 'Task akademik berhasil dibuat', 201);
  } catch (err) {
    next(err);
  }
};

const update = async (req, res, next) => {
  try {
    const [existing] = await db.query(
      'SELECT * FROM tasks WHERE id = ? AND user_id = ? AND is_deleted = 0',
      [req.params.id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Task akademik tidak ditemukan', 404);

    const current = existing[0];
    const {
      title,
      description,
      course_id,
      status,
      deadline,
      reminder_at,
      task_type,
      difficulty,
      grade_weight,
      achieved_score,
    } = req.body;

    let parsedGradeWeight = current.grade_weight;
    if (grade_weight !== undefined) {
      parsedGradeWeight = grade_weight === null || grade_weight === '' ? 0 : Number(grade_weight);
      if (!Number.isFinite(parsedGradeWeight) || parsedGradeWeight < 0 || parsedGradeWeight > 100) {
        return error(res, 'Bobot nilai harus berupa angka 0-100', 400);
      }
    }

    let parsedAchievedScore = current.achieved_score;
    if (achieved_score !== undefined) {
      parsedAchievedScore = achieved_score === null || achieved_score === '' ? null : Number(achieved_score);
      if (
        parsedAchievedScore !== null &&
        (!Number.isFinite(parsedAchievedScore) || parsedAchievedScore < 0 || parsedAchievedScore > 100)
      ) {
        return error(res, 'Nilai didapat harus berupa angka 0-100', 400);
      }
    }

    const nextDeadline = deadline !== undefined ? normalizeDateTimeInput(deadline) : current.deadline;
    const taskDraft = {
      ...current,
      deadline: nextDeadline,
      status: status || current.status,
      difficulty: difficulty || current.difficulty,
      grade_weight: parsedGradeWeight,
    };
    const automaticPriority = calculateAcademicPriority(taskDraft, null);
    const automaticReminder = calculateReminder(taskDraft.deadline, automaticPriority.level);
    const nextReminder = reminder_at !== undefined ? normalizeDateTimeInput(reminder_at) : toMysqlDateTime(automaticReminder);

    if (course_id !== undefined && course_id !== null) {
      const [course] = await db.query(
        'SELECT id FROM courses WHERE id = ? AND user_id = ?',
        [course_id, req.user.id]
      );
      if (course.length === 0) return error(res, 'Mata kuliah tidak ditemukan', 404);
    }

    await db.query(
      `UPDATE tasks
       SET title=?, description=?, course_id=?, status=?, deadline=?, reminder_at=?,
           task_type=?, difficulty=?, grade_weight=?, achieved_score=?
       WHERE id = ? AND user_id = ?`,
      [
        title || current.title,
        description !== undefined ? description : current.description,
        course_id !== undefined ? course_id : current.course_id,
        status || current.status,
        nextDeadline,
        nextReminder,
        task_type || current.task_type,
        difficulty || current.difficulty,
        parsedGradeWeight,
        parsedAchievedScore,
        req.params.id,
        req.user.id,
      ]
    );

    const [rows] = await db.query('SELECT * FROM tasks WHERE id = ?', [req.params.id]);
    const [subs] = await db.query(
      'SELECT * FROM tasks WHERE parent_id = ? AND is_deleted = 0',
      [req.params.id]
    );
    return success(res, enrichTask(rows[0], subs), 'Task akademik berhasil diperbarui');
  } catch (err) {
    next(err);
  }
};

const updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const allowed = ['todo', 'in_progress', 'done'];
    if (!status || !allowed.includes(status)) {
      return error(res, 'Status tidak valid. Gunakan: todo, in_progress, done', 400);
    }

    const [existing] = await db.query(
      'SELECT * FROM tasks WHERE id = ? AND user_id = ? AND is_deleted = 0',
      [req.params.id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Task akademik tidak ditemukan', 404);

    await db.query('UPDATE tasks SET status = ? WHERE id = ? AND user_id = ?', [
      status,
      req.params.id,
      req.user.id,
    ]);

    const parentId = existing[0].parent_id;
    if (parentId) {
      const [siblings] = await db.query(
        'SELECT status FROM tasks WHERE parent_id = ? AND is_deleted = 0',
        [parentId]
      );
      const allDone = siblings.every((s) => s.status === 'done');
      const anyInProgress = siblings.some((s) => s.status === 'in_progress');

      if (allDone) {
        await db.query('UPDATE tasks SET status = "done" WHERE id = ? AND user_id = ?', [parentId, req.user.id]);
      } else if (anyInProgress) {
        await db.query('UPDATE tasks SET status = "in_progress" WHERE id = ? AND user_id = ?', [
          parentId,
          req.user.id,
        ]);
      } else {
        await db.query('UPDATE tasks SET status = "todo" WHERE id = ? AND user_id = ?', [parentId, req.user.id]);
      }
    }

    return success(res, {}, 'Status berhasil diperbarui');
  } catch (err) {
    next(err);
  }
};

const remove = async (req, res, next) => {
  try {
    const [existing] = await db.query(
      'SELECT id FROM tasks WHERE id = ? AND user_id = ? AND is_deleted = 0',
      [req.params.id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Task akademik tidak ditemukan', 404);

    await db.query(
      'UPDATE tasks SET is_deleted = 1 WHERE user_id = ? AND (id = ? OR parent_id = ?)',
      [req.user.id, req.params.id, req.params.id]
    );
    return success(res, {}, 'Task akademik berhasil dihapus');
  } catch (err) {
    next(err);
  }
};

module.exports = { getAll, getOne, create, update, updateStatus, remove };
