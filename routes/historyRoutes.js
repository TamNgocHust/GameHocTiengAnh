// Code cho file routes/historyRoutes.js
const express = require('express');
const router = express.Router();
const historyController = require('../controllers/historyController');

router.get('/:userId', historyController.getPlayHistory);

module.exports = router;