const errorMiddleware = (err, req, res, next) => {
  console.error(err.stack);

  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Token tidak valid atau sudah kedaluwarsa',
    });
  }

  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({
      success: false,
      message: 'Data duplikat terdeteksi',
    });
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(400).json({
      success: false,
      message: 'Relasi data tidak valid',
    });
  }

  if (err.code === 'ER_SIGNAL_EXCEPTION') {
    return res.status(400).json({
      success: false,
      message: err.sqlMessage || 'Validasi database gagal',
    });
  }

  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      success: false,
      message: 'Format JSON tidak valid',
    });
  }

  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({
      success: false,
      message: 'Ukuran file maksimal 5MB',
    });
  }

  if (err.message === 'File harus berupa gambar') {
    return res.status(400).json({
      success: false,
      message: 'File harus berupa gambar',
    });
  }

  res.status(500).json({
    success: false,
    message: 'Internal Server Error',
  });
};

module.exports = errorMiddleware;
