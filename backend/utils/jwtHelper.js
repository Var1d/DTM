const jwt = require('jsonwebtoken');
const accessSecret = process.env.JWT_SECRET || 'dev_access_secret_change_me';
const refreshSecret = process.env.REFRESH_TOKEN_SECRET || process.env.JWT_SECRET || 'dev_refresh_secret_change_me';

const generateAccessToken = (payload) => {
  return jwt.sign(payload, accessSecret, {
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
  });
};

const generateRefreshToken = (payload) => {
  const refreshExpiry = process.env.REFRESH_TOKEN_EXPIRES_IN || 'never';
  if (refreshExpiry === 'never') {
    return jwt.sign(payload, refreshSecret);
  }
  return jwt.sign(payload, refreshSecret, { expiresIn: refreshExpiry });
};

const verifyAccessToken = (token) => {
  return jwt.verify(token, accessSecret);
};

const verifyRefreshToken = (token) => {
  return jwt.verify(token, refreshSecret);
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};
