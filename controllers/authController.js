const { connectDB, sql } = require('../config/db');

exports.login = async (req, res) => {
    const { username, password } = req.body;

    try {
        const pool = await connectDB();
        
        // Kiểm tra xem user và pass có đúng trong DB không
        const result = await pool.request()
            .input('user', sql.VarChar, username)
            .input('pass', sql.VarChar, password) // Lưu ý: Dự án thật nên mã hóa pass, đây là demo học tập nên so sánh text
            .query(`
                SELECT u.UserID, u.Username, u.FullName, r.RoleName, s.ClassID, c.ClassName
                FROM Users u
                JOIN Roles r ON u.RoleID = r.RoleID
                LEFT JOIN Students s ON u.UserID = s.StudentID
                LEFT JOIN Classes c ON s.ClassID = c.ClassID
                WHERE u.Username = @user AND u.Password = @pass
            `);

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            // Trả về thông tin user nếu đăng nhập đúng
            res.json({ success: true, user: user });
        } else {
            res.status(401).json({ success: false, message: "Sai tên đăng nhập hoặc mật khẩu!" });
        }

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Lỗi Server" });
    }
};