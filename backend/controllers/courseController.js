const db = require('../config/db');
const { success, error } = require('../utils/responseHelper');

const getAll = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT c.*,
              COUNT(t.id) AS task_count,
              SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) AS done_count
       FROM courses c
       LEFT JOIN tasks t
         ON t.course_id = c.id
        AND t.is_deleted = 0
        AND t.parent_id IS NULL
       WHERE c.user_id = ?
       GROUP BY c.id
       ORDER BY FIELD(c.day, 'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'), c.start_time, c.name`,
      [req.user.id]
    );
    return success(res, rows);
  } catch (err) {
    next(err);
  }
};

const create = async (req, res, next) => {
  try {
    const { name, lecturer, room, day, start_time, end_time, credit, color } = req.body;
    if (!name) return error(res, 'Nama mata kuliah wajib diisi', 400);

    const [result] = await db.query(
      `INSERT INTO courses (user_id, name, lecturer, room, day, start_time, end_time, credit, color)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        name,
        lecturer || null,
        room || null,
        day || null,
        start_time || null,
        end_time || null,
        credit || 3,
        color || '#6366f1',
      ]
    );

    const [rows] = await db.query('SELECT * FROM courses WHERE id = ?', [result.insertId]);
    return success(res, rows[0], 'Mata kuliah berhasil dibuat', 201);
  } catch (err) {
    next(err);
  }
};

const update = async (req, res, next) => {
  try {
    const [existing] = await db.query(
      'SELECT * FROM courses WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Mata kuliah tidak ditemukan', 404);

    const current = existing[0];
    const { name, lecturer, room, day, start_time, end_time, credit, color } = req.body;
    await db.query(
      `UPDATE courses
       SET name=?, lecturer=?, room=?, day=?, start_time=?, end_time=?, credit=?, color=?
       WHERE id=? AND user_id=?`,
      [
        name || current.name,
        lecturer !== undefined ? lecturer : current.lecturer,
        room !== undefined ? room : current.room,
        day !== undefined ? day : current.day,
        start_time !== undefined ? start_time : current.start_time,
        end_time !== undefined ? end_time : current.end_time,
        credit !== undefined ? credit : current.credit,
        color || current.color,
        req.params.id,
        req.user.id,
      ]
    );

    const [rows] = await db.query('SELECT * FROM courses WHERE id = ?', [req.params.id]);
    return success(res, rows[0], 'Mata kuliah berhasil diperbarui');
  } catch (err) {
    next(err);
  }
};

const remove = async (req, res, next) => {
  try {
    const [existing] = await db.query(
      'SELECT id FROM courses WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Mata kuliah tidak ditemukan', 404);

    await db.query('DELETE FROM courses WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
    return success(res, {}, 'Mata kuliah berhasil dihapus');
  } catch (err) {
    next(err);
  }
};

module.exports = { getAll, create, update, remove };
