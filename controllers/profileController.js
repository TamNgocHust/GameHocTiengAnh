const sql = require('mssql');

const profileController = {
    // 1. Lấy thông tin Profile
    getProfile: async (req, res) => {
        try {
            const { id } = req.params;
            const request = new sql.Request();
            request.input('uid', sql.Int, id);

            // Query lấy thông tin User + Tổng điểm + Tổng thời gian
            const query = `
                SELECT 
                    u.Username, 
                    u.FullName, 
                    r.RoleName,
                    s.AvatarURL,
                    c.ClassName,
                    (SELECT ISNULL(SUM(Score), 0) FROM PlayHistory WHERE StudentID = u.UserID) as TotalScore,
                    (SELECT ISNULL(SUM(TimeTaken), 0) FROM PlayHistory WHERE StudentID = u.UserID) as TotalTime
                FROM Users u
                LEFT JOIN Roles r ON u.RoleID = r.RoleID
                LEFT JOIN Students s ON u.UserID = s.StudentID
                LEFT JOIN Classes c ON s.ClassID = c.ClassID
                WHERE u.UserID = @uid
            `;

            const result = await request.query(query);

            if (result.recordset.length > 0) {
                res.json({ success: true, data: result.recordset[0] });
            } else {
                res.json({ success: false, message: "User not found" });
            }
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: "Database Error" });
        }
    },

    // 2. Cập nhật tên hiển thị
    updateProfile: async (req, res) => {
        try {
            const { id } = req.params;
            const { fullName } = req.body;
            
            const request = new sql.Request();
            request.input('uid', sql.Int, id);
            request.input('fn', sql.NVarChar, fullName);

            await request.query("UPDATE Users SET FullName = @fn WHERE UserID = @uid");
            
            res.json({ success: true });
        } catch (err) {
            console.error(err);
            res.status(500).json({ success: false, message: "Update failed" });
        }
    }
};

// --- QUAN TRỌNG: DÒNG NÀY GIÚP ROUTES NHÌN THẤY CONTROLLER ---
module.exports = profileController;