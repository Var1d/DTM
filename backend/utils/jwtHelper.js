const jwt = require('jsonwebtoken');

const generateAccessToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
  });
};

const generateRefreshToken = (payload) => {
  const refreshExpiry = process.env.REFRESH_TOKEN_EXPIRES_IN || 'never';
  if (refreshExpiry === 'never') {
    return jwt.sign(payload, process.env.REFRESH_TOKEN_SECRET);
  }
  return jwt.sign(payload, process.env.REFRESH_TOKEN_SECRET, { expiresIn: refreshExpiry });
};

const verifyAccessToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

const verifyRefreshToken = (token) => {
  return jwt.verify(token, process.env.REFRESH_TOKEN_SECRET);
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};
