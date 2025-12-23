// File: routes/gameRoutes.js
const express = require('express');
const router = express.Router();
const gameController = require('../controllers/gameController'); // Đảm bảo đường dẫn trỏ đúng file controller của bạn

// --- ROUND 1: Nối từ ---
router.get('/round1/:unitId', gameController.getRound1Data);
router.post('/submit-round1', gameController.submitRound1);

// --- ROUND 2: Sắp xếp câu ---
router.get('/round2/:unitId', gameController.getRound2Data);
router.post('/submit-round2', gameController.submitRound2);

// --- ROUND 3: Trắc nghiệm (Cái bạn vừa làm) ---
router.get('/round3/:unitId', gameController.getRound3Data);
router.post('/submit-round3', gameController.submitRound3);

// --- ROUND 4: ĐIỀN TỪ ---
router.get('/round4/:unitId', gameController.getRound4Data);
router.post('/submit-round4', gameController.submitRound4);

module.exports = router;