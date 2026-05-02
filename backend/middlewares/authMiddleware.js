const { verifyAccessToken } = require('../utils/jwtHelper');
const { error } = require('../utils/responseHelper');

const authenticate = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return error(res, 'Token tidak ditemukan', 401);
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = verifyAccessToken(token);
    req.user = decoded; // { id, email }
    next();
  } catch (err) {
    return error(res, 'Token tidak valid atau sudah kedaluwarsa', 401);
  }
};

module.exports = authenticate;
