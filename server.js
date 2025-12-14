const express = require('express');
const cors = require('cors');
const sql = require('mssql');

const app = express();
const PORT = 5000; // Giữ nguyên port 5000

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

// Kết nối Database ngay khi bật Server
async function connectDB() {
    try {
        await sql.connect(dbConfig);
        console.log("✅ Đã kết nối SQL Server thành công!");
    } catch (err) {
        console.log("❌ Lỗi kết nối SQL Server:", err);
    }
}
connectDB();

// PHẦN 1: API ĐĂNG NHẬP (ĐÃ SỬA LỖI TREO)
// =============================================================
app.post('/api/auth/login', async (req, res) => {
    const { username, password } = req.body;
    console.log(`📡 Đang kiểm tra đăng nhập: ${username}`); // Log 1: Đã nhận lệnh

    try {
        // --- SỬA Ở ĐÂY: KHÔNG gọi sql.connect() nữa ---
        // Thay vào đó, dùng new sql.Request() để dùng luôn kết nối đang có
        const request = new sql.Request(); 
        
        request.input('u', sql.NVarChar, username);
        request.input('p', sql.NVarChar, password);
        
        const result = await request.query('SELECT * FROM Users WHERE Username = @u AND PasswordHash = @p');
        
        console.log("🏁 Đã truy vấn xong Database"); // Log 2: Đã hỏi xong (Nếu thấy dòng này là ngon)

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            console.log("✅ Đăng nhập thành công:", user.Username);
            res.json({ 
                success: true, 
                message: "Đăng nhập thành công!",
                role: user.RoleID,
                fullName: user.FullName,
                userId: user.UserID
            });
        } else {
            console.log("❌ Sai mật khẩu hoặc tài khoản");
            res.status(401).json({ success: false, message: "Sai tên đăng nhập hoặc mật khẩu!" });
        }
    } catch (err) {
        console.error("❌ Lỗi khi hỏi Database:", err);
        res.status(500).json({ success: false, message: "Lỗi Server nội bộ" });
    }
});
// =============================================================
// PHẦN 2: KẾT NỐI CÁC ROUTE KHÁC (Đã mở lại)
// =============================================================

// 2.1 Route cho Profile (Thông tin cá nhân)
// Đường dẫn gốc sẽ là: http://localhost:5000/api/profile
try {
    const profileRoutes = require('./routes/profileRoutes');
    app.use('/api/profile', profileRoutes);
    console.log("✅ Đã nạp module Profile");
} catch (error) {
    console.error("⚠️ Chưa tìm thấy file profileRoutes, bỏ qua module này.");
}

// 2.2 Route cho Review (Học tập - Từ vựng & Ngữ pháp)
// Đường dẫn gốc sẽ là: http://localhost:5000/api/review
try {
    const reviewRoutes = require('./routes/reviewRoutes');
    app.use('/api/review', reviewRoutes);
    console.log("✅ Đã nạp module Review");
} catch (error) {
    console.error("⚠️ Chưa tìm thấy file reviewRoutes, bỏ qua module này.");
}

// === KHỞI ĐỘNG SERVER ===
app.listen(PORT, () => {
    console.log(`🚀 Server Backend đang chạy tại: http://localhost:${PORT}`);
});