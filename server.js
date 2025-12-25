const express = require('express');
const cors = require('cors');
const sql = require('mssql');


const gameRoutes = require('./routes/gameRoutes');

const historyRoutes = require('./routes/historyRoutes'); 

const leaderboardRoutes = require('./routes/leaderboardRoutes'); 

// Các route tùy chọn (Dùng try/catch để không lỗi nếu file chưa tồn tại)
let profileRoutes, reviewRoutes;
try {
    profileRoutes = require('./routes/profileRoutes');
} catch (error) { 
    console.error("❌ LỖI NẠP PROFILE:", error.message); 
    // In ra toàn bộ lỗi để dễ xem
    console.error(error);
}

try {
    reviewRoutes = require('./routes/reviewRoutes');
} catch (error) { console.log("⚠️ Chưa có file reviewRoutes (bỏ qua)"); }

// =============================================================
// 2. CẤU HÌNH SERVER & DB
// =============================================================
const app = express();
const PORT = 5000;

app.use(cors()); 
app.use(express.json());

// Cấu hình kết nối SQL Server
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
// 3. API ĐĂNG NHẬP (AUTH)
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
// 4. ĐĂNG KÝ ROUTES (SỬ DỤNG API)
// =============================================================

// Route cho Game (Round 1 -> 4)
app.use('/api/game', gameRoutes); 

// Route cho Lịch sử (History)
app.use('/api/history', historyRoutes);

// Route cho Bảng xếp hạng
app.use('/api/leaderboard', leaderboardRoutes);

// Route cho Profile & Review (Nếu có)
if (profileRoutes) app.use('/api/profile', profileRoutes);
if (reviewRoutes) app.use('/api/review', reviewRoutes);


// =============================================================
// 5. KHỞI ĐỘNG SERVER
// =============================================================
app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại: http://localhost:${PORT}`);
});