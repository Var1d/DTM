const express = require('express');
const router  = express.Router();
const auth    = require('../middlewares/authMiddleware');
const avatarUpload = require('../middlewares/uploadMiddleware');
const { updateProfile, uploadAvatar, updatePassword } = require('../controllers/userController');

router.use(auth);
router.put('/profile',  updateProfile);
router.post('/avatar', avatarUpload.single('avatar'), uploadAvatar);
router.put('/password', updatePassword);

module.exports = router;
