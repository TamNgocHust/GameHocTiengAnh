const { connectDB, sql } = require('../config/db');

// 1. Lấy thông tin chi tiết Profile
exports.getUserProfile = async (req, res) => {
    const { userId } = req.params;

    try {
        const pool = await connectDB();
        
        const query = `
            SELECT 
                u.UserID, u.Username, u.FullName, r.RoleName,
                s.AvatarURL, 
                c.ClassName, 
                g.GradeName,
                (SELECT ISNULL(SUM(Score), 0) FROM PlayHistory WHERE StudentID = u.UserID) as LifetimeScore,
                (SELECT ISNULL(SUM(Stars), 0) FROM PlayHistory WHERE StudentID = u.UserID) as LifetimeStars
            FROM Users u
            JOIN Roles r ON u.RoleID = r.RoleID
            LEFT JOIN Students s ON u.UserID = s.StudentID
            LEFT JOIN Classes c ON s.ClassID = c.ClassID
            LEFT JOIN Grades g ON c.GradeID = g.GradeID
            WHERE u.UserID = @id
        `;

        const result = await pool.request()
            .input('id', sql.Int, userId)
            .query(query);

        if (result.recordset.length > 0) {
            res.json({ success: true, data: result.recordset[0] });
        } else {
            res.status(404).json({ success: false, message: "Không tìm thấy người dùng" });
        }

    } catch (err) {
        console.log(err);
        res.status(500).json({ error: "Lỗi server: " + err.message });
    }
};

// 2. Cập nhật thông tin (Tên và Avatar)
exports.updateProfile = async (req, res) => {
    const { userId } = req.params;
    const { fullName, avatarUrl } = req.body;

    try {
        const pool = await connectDB();
        
        // Cập nhật tên trong bảng Users
        await pool.request()
            .input('uid', sql.Int, userId)
            .input('name', sql.NVarChar, fullName)
            .query("UPDATE Users SET FullName = @name WHERE UserID = @uid");

        // Nếu có avatar thì cập nhật bảng Students
        if (avatarUrl) {
            await pool.request()
                .input('uid', sql.Int, userId)
                .input('ava', sql.NVarChar, avatarUrl)
                .query("UPDATE Students SET AvatarURL = @ava WHERE StudentID = @uid");
        }

        res.json({ success: true, message: "Cập nhật hồ sơ thành công!" });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};