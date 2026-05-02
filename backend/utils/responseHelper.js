const success = (res, data = {}, message = 'Berhasil', statusCode = 200) => {
  return res.status(statusCode).json({ success: true, message, data });
};

const error = (res, message = 'Terjadi kesalahan', statusCode = 500) => {
  return res.status(statusCode).json({ success: false, message });
};

module.exports = { success, error };
