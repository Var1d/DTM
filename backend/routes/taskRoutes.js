const express = require('express');
const router  = express.Router();
const auth    = require('../middlewares/authMiddleware');
const { getAll, getOne, create, update, updateStatus, remove } = require('../controllers/taskController');

router.use(auth); // semua task route butuh auth
router.get('/',            getAll);
router.get('/:id',         getOne);
router.post('/',           create);
router.put('/:id',         update);
router.patch('/:id/status', updateStatus);
router.delete('/:id',      remove);

module.exports = router;
