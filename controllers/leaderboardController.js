const sql = require('mssql');

const leaderboardController = {
    
    getLeaderboard: async (req, res) => {
        try {
            const { unitId, difficulty } = req.query;

            if (!unitId) {
                return res.json({ success: true, data: [] });
            }

            const request = new sql.Request();
            request.input('uid', sql.Int, unitId);
            request.input('diff', sql.NVarChar, difficulty || 'Normal');

            // --- LOGIC TÍNH TỔNG CHUẨN ---
            const query = `
                WITH BestPerRound AS (
                    -- BƯỚC 1: Lấy điểm cao nhất của TỪNG Round (GameID) cho mỗi học sinh
                    SELECT 
                        ph.StudentID,
                        ph.GameID,
                        MAX(ph.Score) as RoundMaxScore,    -- Điểm cao nhất của Round này
                        MIN(ph.TimeTaken) as RoundMinTime  -- Thời gian tốt nhất
                    FROM PlayHistory ph
                    -- Join bảng để lọc theo Khối Lớp
                    JOIN Topics t ON ph.TopicID = t.TopicID
                    JOIN Students s ON ph.StudentID = s.StudentID
                    JOIN Classes c ON s.ClassID = c.ClassID
                    
                    WHERE ph.TopicID = @uid 
                      AND ph.Difficulty = @diff
                      AND c.GradeID = t.GradeID -- Chỉ lấy học sinh đúng khối
                    
                    GROUP BY ph.StudentID, ph.GameID
                )
                -- BƯỚC 2: Cộng tổng điểm các Round lại (SUM)
                SELECT TOP 20
                    u.FullName,
                    u.UserName,
                    c.ClassName,
                    SUM(b.RoundMaxScore) as TotalScore, -- Cộng dồn điểm: Round 1 + Round 2 + ...
                    SUM(b.RoundMinTime) as TotalTime    -- Cộng dồn thời gian
                FROM BestPerRound b
                JOIN Users u ON b.StudentID = u.UserID
                LEFT JOIN Students s ON u.UserID = s.StudentID
                LEFT JOIN Classes c ON s.ClassID = c.ClassID
                
                GROUP BY u.UserID, u.FullName, u.UserName, c.ClassName
                ORDER BY TotalScore DESC, TotalTime ASC;
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