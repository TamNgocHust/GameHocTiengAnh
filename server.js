const express = require('express');
const cors = require('cors');
const sql = require('mssql');

// Import gameController (Đảm bảo file này đã được cập nhật các hàm mới)
const gameController = require('./controllers/gameController'); 

const app = express();
const PORT = 5000;

app.use(cors()); 
app.use(express.json());

// 1. Cấu hình kết nối SQL Server
const dbConfig = {
    user: 'GameUser',
    password: '123456',
    server: 'DESKTOP-HRMHVJB\\SQLEXPRESS',
    database: 'GameHocTiengAnh1',
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

// Kết nối Database
async function connectDB() {
    try {
        await sql.connect(dbConfig);
        console.log("✅ Đã kết nối SQL Server thành công!");
    } catch (err) {
        console.log("❌ Lỗi kết nối SQL Server:", err);
    }
}
connectDB();

// =============================================================
// PHẦN 1: API ĐĂNG NHẬP (GIỮ NGUYÊN)
// =============================================================
app.post('/api/auth/login', async (req, res) => {
    const { username, password } = req.body;
    console.log(`📡 Đang kiểm tra đăng nhập: ${username}`);

    try {
        const request = new sql.Request(); 
        request.input('u', sql.NVarChar, username);
        request.input('p', sql.NVarChar, password);
        const result = await request.query('SELECT * FROM Users WHERE Username = @u AND PasswordHash = @p');
        
        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            res.json({ 
                success: true, 
                message: "Đăng nhập thành công!",
                role: user.RoleID,
                fullName: user.FullName,
                userId: user.UserID
            });
        } else {
            res.status(401).json({ success: false, message: "Sai tên đăng nhập hoặc mật khẩu!" });
        }
    } catch (err) {
        console.error("❌ Lỗi Auth:", err);
        res.status(500).json({ success: false, message: "Lỗi Server" });
    }
});

// =============================================================
// PHẦN 2: API GAME (CẬP NHẬT THÊM ROUND 2)
// =============================================================

// --- ROUND 1: NỐI TỪ ---
app.get('/api/game/round1', gameController.getRound1Data);
app.post('/api/game/submit-round1', gameController.submitRound1);

// --- ROUND 2: SẮP XẾP CÂU (MỚI THÊM) ---
// Route lấy dữ liệu các câu cần sắp xếp
app.get('/api/game/round2', gameController.getRound2Data);

// Route nộp điểm Round 2
app.post('/api/game/submit-round2', gameController.submitRound2);


// =============================================================
// PHẦN 3: CÁC MODULE KHÁC
// =============================================================
try {
    const profileRoutes = require('./routes/profileRoutes');
    app.use('/api/profile', profileRoutes);
} catch (error) { console.log("⚠️ Bỏ qua profileRoutes"); }

try {
    const reviewRoutes = require('./routes/reviewRoutes');
    app.use('/api/review', reviewRoutes);
} catch (error) { console.log("⚠️ Bỏ qua reviewRoutes"); }

// === KHỞI ĐỘNG SERVER ===
app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại: http://localhost:${PORT}`);
});