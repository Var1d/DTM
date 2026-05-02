const bcrypt  = require('bcryptjs');
const db      = require('../config/db');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../utils/jwtHelper');
const { success, error } = require('../utils/responseHelper');

// POST /api/auth/register
const register = async (req, res, next) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password)
      return error(res, 'Nama, email, dan password wajib diisi', 400);

    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0)
      return error(res, 'Email sudah terdaftar', 409);

    const hashed = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name, email, hashed]
    );

    // Insert kategori default mahasiswa
    const newId = result.insertId;
    await db.query(
      `INSERT INTO categories (user_id, name, color) VALUES
       (?, "Kuliah", "#6366f1"), (?, "Tugas", "#f59e0b"),
       (?, "Ujian", "#ef4444"), (?, "Organisasi", "#22c55e")`,
      [newId, newId, newId, newId]
    );

    return success(res, { id: newId, name, email }, "Registrasi berhasil", 201);
  } catch (err) { next(err); }
};

// POST /api/auth/login
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return error(res, 'Email dan password wajib diisi', 400);

    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0)
      return error(res, 'Email atau password salah', 401);

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password);
    if (!valid)
      return error(res, 'Email atau password salah', 401);

    const payload       = { id: user.id, email: user.email };
    const accessToken   = generateAccessToken(payload);
    const refreshToken  = generateRefreshToken(payload);

    // Simpan refresh token sampai user logout.
    const expiresAt = new Date('2038-01-01T00:00:00Z');
    await db.query(
      'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, ?)',
      [user.id, refreshToken, expiresAt]
    );

    return success(res, {
      access_token:  accessToken,
      refresh_token: refreshToken,
      user: { id: user.id, name: user.name, email: user.email, avatar_url: user.avatar_url },
    }, 'Login berhasil');
  } catch (err) { next(err); }
};

// POST /api/auth/refresh
const refresh = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token) return error(res, 'Refresh token diperlukan', 400);

    const [rows] = await db.query(
      'SELECT * FROM refresh_tokens WHERE token = ? AND expires_at > NOW()',
      [refresh_token]
    );
    if (rows.length === 0) return error(res, 'Refresh token tidak valid', 401);

    const decoded     = verifyRefreshToken(refresh_token);
    const accessToken = generateAccessToken({ id: decoded.id, email: decoded.email });

    return success(res, { access_token: accessToken }, 'Token diperbarui');
  } catch (err) { next(err); }
};

// POST /api/auth/logout
const logout = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;
    if (refresh_token) {
      await db.query('DELETE FROM refresh_tokens WHERE token = ?', [refresh_token]);
    }
    return success(res, {}, 'Logout berhasil');
  } catch (err) { next(err); }
};

// GET /api/auth/me
const me = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      'SELECT id, name, email, avatar_url, created_at FROM users WHERE id = ?',
      [req.user.id]
    );
    if (rows.length === 0) return error(res, 'User tidak ditemukan', 404);
    return success(res, rows[0]);
  } catch (err) { next(err); }
};

module.exports = { register, login, refresh, logout, me };
