const db = require('../config/db');
const { success, error } = require('../utils/responseHelper');

// GET /api/categories
const getAll = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM categories WHERE user_id = ? ORDER BY created_at DESC',
      [req.user.id]
    );
    return success(res, rows);
  } catch (err) { next(err); }
};

// POST /api/categories
const create = async (req, res, next) => {
  try {
    const { name, color } = req.body;
    if (!name) return error(res, 'Nama kategori wajib diisi', 400);

    const [result] = await db.query(
      'INSERT INTO categories (user_id, name, color) VALUES (?, ?, ?)',
      [req.user.id, name, color || '#6366f1']
    );

    const [rows] = await db.query('SELECT * FROM categories WHERE id = ?', [result.insertId]);
    return success(res, rows[0], 'Kategori berhasil dibuat', 201);
  } catch (err) { next(err); }
};

// PUT /api/categories/:id
const update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, color } = req.body;

    const [existing] = await db.query(
      'SELECT * FROM categories WHERE id = ? AND user_id = ?',
      [id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Kategori tidak ditemukan', 404);

    await db.query(
      'UPDATE categories SET name = ?, color = ? WHERE id = ?',
      [name || existing[0].name, color || existing[0].color, id]
    );

    const [rows] = await db.query('SELECT * FROM categories WHERE id = ?', [id]);
    return success(res, rows[0], 'Kategori berhasil diperbarui');
  } catch (err) { next(err); }
};

// DELETE /api/categories/:id
const remove = async (req, res, next) => {
  try {
    const { id } = req.params;
    const [existing] = await db.query(
      'SELECT * FROM categories WHERE id = ? AND user_id = ?',
      [id, req.user.id]
    );
    if (existing.length === 0) return error(res, 'Kategori tidak ditemukan', 404);

    await db.query('DELETE FROM categories WHERE id = ?', [id]);
    return success(res, {}, 'Kategori berhasil dihapus');
  } catch (err) { next(err); }
};

module.exports = { getAll, create, update, remove };
