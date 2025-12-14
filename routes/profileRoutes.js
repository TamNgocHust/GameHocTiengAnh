const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');

// GET: Lấy thông tin (Ví dụ: /api/profile/1)
router.get('/:userId', profileController.getUserProfile);

// PUT: Cập nhật thông tin (Ví dụ: /api/profile/update/1)
router.put('/update/:userId', profileController.updateProfile);

module.exports = router;