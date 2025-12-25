const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');

// Dòng này cực kỳ quan trọng để kiểm tra dữ liệu nạp vào
console.log("------------------------------------------");
console.log("🔍 ĐANG KIỂM TRA PROFILE CONTROLLER:");
console.log("Giá trị nạp vào:", profileController);
console.log("Kiểu dữ liệu:", typeof profileController);
if (profileController) {
    console.log("Hàm getProfile:", typeof profileController.getProfile);
}
console.log("------------------------------------------");

// Kiểm tra trước khi gán để tránh crash server
if (profileController && typeof profileController.getProfile === 'function') {
    router.get('/:id', profileController.getProfile);
} else {
    console.error("❌ LỖI: profileController.getProfile không phải là một hàm!");
}

if (profileController && typeof profileController.updateProfile === 'function') {
    router.put('/update/:id', profileController.updateProfile);
}

module.exports = router;