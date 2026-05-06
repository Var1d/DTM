const { success, error } = require('../utils/responseHelper');
const {
  isPushConfigured,
  removeSubscription,
  saveSubscription,
  sendToUser,
  vapidPublicKey,
} = require('../services/pushService');

const getPublicKey = (_req, res) => {
  if (!isPushConfigured()) {
    return error(res, 'Web Push belum dikonfigurasi di server', 503);
  }

  return success(res, { public_key: vapidPublicKey });
};

const subscribe = async (req, res, next) => {
  try {
    if (!isPushConfigured()) {
      return error(res, 'Web Push belum dikonfigurasi di server', 503);
    }

    await saveSubscription(req.user.id, req.body.subscription, req.get('user-agent'));
    return success(res, {}, 'Notifikasi berhasil diaktifkan', 201);
  } catch (err) {
    if (err.statusCode) return error(res, err.message, err.statusCode);
    next(err);
  }
};

const unsubscribe = async (req, res, next) => {
  try {
    await removeSubscription(req.user.id, req.body.endpoint);
    return success(res, {}, 'Notifikasi berhasil dinonaktifkan');
  } catch (err) {
    next(err);
  }
};

const test = async (req, res, next) => {
  try {
    const now = Date.now();
    const result = await sendToUser(req.user.id, {
      title: 'PIO notification aktif',
      body: `Browser ini sudah siap menerima pengingat tugas. Test ${new Date(now).toLocaleTimeString('id-ID')}`,
      url: '/profile',
      tag: `pio-test-notification-${now}`,
    });
    return success(res, result, result.sent > 0 ? 'Notifikasi test dikirim' : 'Belum ada browser yang subscribe');
  } catch (err) {
    if (err.statusCode) return error(res, err.message, err.statusCode);
    next(err);
  }
};

module.exports = { getPublicKey, subscribe, test, unsubscribe };
