const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');

// Đường dẫn lấy từ vựng: /api/review/vocab/1
router.get('/vocab/:unitId', reviewController.getVocabulary);

// Đường dẫn lấy ngữ pháp: /api/review/grammar/1
router.get('/grammar/:unitId', reviewController.getGrammar);

module.exports = router;