const bcrypt = require('bcryptjs');
const db     = require('../config/db');
const { success, error } = require('../utils/responseHelper');

const getPublicAvatarPath = (req, filename) => {
  return `/uploads/avatars/${filename}`;
};

// PUT /api/user/profile
const updateProfile = async (req, res, next) => {
  try {
    const { name } = req.body;
    await db.query(
      'UPDATE users SET name = ? WHERE id = ?',
      [name, req.user.id]
    );
    const [rows] = await db.query(
      'SELECT id, name, email, avatar_url FROM users WHERE id = ?',
      [req.user.id]
    );
    return success(res, rows[0], 'Profil berhasil diperbarui');
  } catch (err) { next(err); }
};

// POST /api/user/avatar
const uploadAvatar = async (req, res, next) => {
  try {
    if (!req.file) return error(res, 'File avatar tidak ditemukan', 400);

    const avatarUrl = getPublicAvatarPath(req, req.file.filename);
    await db.query('UPDATE users SET avatar_url = ? WHERE id = ?', [avatarUrl, req.user.id]);

    const [rows] = await db.query(
      'SELECT id, name, email, avatar_url FROM users WHERE id = ?',
      [req.user.id]
    );
    return success(res, rows[0], 'Avatar berhasil diperbarui');
  } catch (err) { next(err); }
};

// PUT /api/user/password
const updatePassword = async (req, res, next) => {
  try {
    const { old_password, new_password } = req.body;
    if (!old_password || !new_password)
      return error(res, 'Password lama dan baru wajib diisi', 400);

    const [rows] = await db.query('SELECT password FROM users WHERE id = ?', [req.user.id]);
    const valid = await bcrypt.compare(old_password, rows[0].password);
    if (!valid) return error(res, 'Password lama tidak sesuai', 401);

    const hashed = await bcrypt.hash(new_password, 10);
    await db.query('UPDATE users SET password = ? WHERE id = ?', [hashed, req.user.id]);

    return success(res, {}, 'Password berhasil diperbarui');
  } catch (err) { next(err); }
};

module.exports = { updateProfile, uploadAvatar, updatePassword };
