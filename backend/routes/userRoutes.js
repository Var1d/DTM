const express = require('express');
const router  = express.Router();
const auth    = require('../middlewares/authMiddleware');
const { updateProfile, updatePassword } = require('../controllers/userController');

router.use(auth);
router.put('/profile',  updateProfile);
router.put('/password', updatePassword);

module.exports = router;
