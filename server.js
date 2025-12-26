const express = require('express');
const cors = require('cors');
const sql = require('mssql');
const path = require('path');
const fs = require('fs');

// --- NẠP ROUTES ---
const gameRoutes = require('./routes/gameRoutes');
const historyRoutes = require('./routes/historyRoutes'); 
const leaderboardRoutes = require('./routes/leaderboardRoutes'); 
const profileRoutes = require('./routes/profileRoutes');
const reviewRoutes = require('./routes/reviewRoutes'); // ✅ Đã có (Tốt)

const app = express();
const PORT = 5000;

app.use(cors()); 
app.use(express.json());

// =============================================================
// 📂 CẤU HÌNH ĐƯỜNG DẪN TĨNH
// =============================================================
app.use(express.static(path.join(__dirname, 'Frontend', 'screen')));
app.use(express.static(path.join(__dirname, 'Frontend')));

console.log("--------------------------------------------------");
console.log("📂 Server đang phục vụ file giao diện từ:");
console.log("   👉 " + path.join(__dirname, 'Frontend', 'screen'));
console.log("--------------------------------------------------");


// =============================================================
// KẾT NỐI DATABASE
// =============================================================
const dbConfig = {
    user: 'GameUser',
    password: '123456',
    server: 'DESKTOP-HRMHVJB\\SQLEXPRESS',
    database: 'GameHocTiengAnh1',
    options: { encrypt: false, trustServerCertificate: true }
};

async function connectDB() {
    try {
        await sql.connect(dbConfig);
        console.log("✅ Đã kết nối SQL Server thành công!");
    } catch (err) { console.error("❌ Lỗi kết nối SQL Server:", err); }
}
connectDB();

// =============================================================
// API ROUTES
// =============================================================

// API Đăng nhập
app.post('/api/auth/login', async (req, res) => {
    const { username, password } = req.body;
    try {
        const request = new sql.Request(); 
        request.input('u', sql.NVarChar, username);
        request.input('p', sql.NVarChar, password);
        const result = await request.query('SELECT * FROM Users WHERE Username = @u AND PasswordHash = @p');
        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            res.json({ success: true, message: "Đăng nhập thành công!", role: user.RoleID, fullName: user.FullName, userId: user.UserID });
        } else {
            res.status(401).json({ success: false, message: "Sai thông tin đăng nhập!" });
        }
    } catch (err) { res.status(500).json({ success: false, message: "Lỗi Server" }); }
});

app.use('/api/game', gameRoutes);
app.use('/api/history', historyRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/review', reviewRoutes); 


// KHỞI ĐỘNG
app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại: http://localhost:${PORT}`);
});