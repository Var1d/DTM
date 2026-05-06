const express = require('express');
const router = express.Router();
const auth = require('../middlewares/authMiddleware');
const { getPublicKey, subscribe, test, unsubscribe } = require('../controllers/notificationController');

router.use(auth);
router.get('/public-key', getPublicKey);
router.post('/subscribe', subscribe);
router.post('/unsubscribe', unsubscribe);
router.post('/test', test);

module.exports = router;
