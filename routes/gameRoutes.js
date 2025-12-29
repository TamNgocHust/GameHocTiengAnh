const express = require('express');
const router = express.Router();
const gameController = require('../controllers/gameController'); 

// API lấy danh sách bài học
router.get('/units', gameController.getUnitsByGrade);

// --- ROUND 1: Nối từ ---
router.get('/round1/:unitId', gameController.getRound1Data);
// Sửa thành saveGameResult để khớp với Controller
router.post('/submit-round1', gameController.saveGameResult); 

// --- ROUND 2: Sắp xếp câu ---
router.get('/round2/:unitId', gameController.getRound2Data);
// Nếu chưa viết hàm riêng, có thể tạm dùng saveGameResult
router.post('/submit-round2', gameController.saveGameResult); 

// --- ROUND 3: Trắc nghiệm ---
router.get('/round3/:unitId', gameController.getRound3Data);
router.post('/submit-round3', gameController.saveGameResult);

// --- ROUND 4: Điền từ ---
router.get('/round4/:unitId', gameController.getRound4Data);
router.post('/submit-round4', gameController.saveGameResult);

module.exports = router;