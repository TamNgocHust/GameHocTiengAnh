const express = require('express');
const router = express.Router();

// Import controller (Phải trỏ đúng đường dẫn)
const reviewController = require('../controllers/reviewController'); 

// Định nghĩa API
// 1. Lấy từ vựng: /api/review/vocab/1
router.get('/vocab/:unitId', reviewController.getVocab); 

// 2. Lấy ngữ pháp: /api/review/grammar/1
router.get('/grammar/:unitId', reviewController.getGrammar);

module.exports = router;