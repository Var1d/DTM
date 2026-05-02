const express = require('express');
const router  = express.Router();
const auth    = require('../middlewares/authMiddleware');
const { register, login, refresh, logout, me } = require('../controllers/authController');

router.post('/register', register);
router.post('/login',    login);
router.post('/refresh',  refresh);
router.post('/logout',   auth, logout);
router.get('/me',        auth, me);

module.exports = router;
