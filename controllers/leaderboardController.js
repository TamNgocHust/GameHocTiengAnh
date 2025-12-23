const sql = require('mssql');

const leaderboardController = {
    
    getLeaderboard: async (req, res) => {
        try {
            // 1. Nhận độ khó từ Client gửi lên (Mặc định là 'Normal' nếu không gửi)
            const difficulty = req.query.difficulty || 'Normal';

            const request = new sql.Request();
            request.input('diff', sql.NVarChar, difficulty);

            // 2. Thêm WHERE ph.Difficulty = @diff
            const query = `
                SELECT TOP 20
                    u.FullName,
                    u.Username,
                    SUM(ph.Score) as TotalScore,
                    SUM(ph.TimeTaken) as TotalTime
                FROM PlayHistory ph
                JOIN Users u ON ph.StudentID = u.UserID
                WHERE ph.Difficulty = @diff 
                GROUP BY u.UserID, u.FullName, u.Username
                ORDER BY TotalScore DESC, TotalTime ASC
            `;

            const result = await request.query(query);

            res.json({ success: true, data: result.recordset });
        } catch (err) {
            console.error("Lỗi lấy bảng xếp hạng:", err);
            res.status(500).json({ success: false, message: "Lỗi Server" });
        }
    }
};

module.exports = leaderboardController;