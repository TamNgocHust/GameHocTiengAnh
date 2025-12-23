// File: routes/leaderboardRoutes.js
const express = require('express');
const router = express.Router();
const leaderboardController = require('../controllers/leaderboardController');

// URL gọi: GET /api/leaderboard
router.get('/', leaderboardController.getLeaderboard);

module.exports = router;