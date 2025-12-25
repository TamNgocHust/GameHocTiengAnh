const sql = require('mssql');

const leaderboardController = {
    
    getLeaderboard: async (req, res) => {
        try {
            const { unitId, difficulty } = req.query;

            // Nếu chưa chọn Unit, trả về rỗng
            if (!unitId) {
                return res.json({ success: true, data: [] });
            }

            const request = new sql.Request();
            request.input('uid', sql.Int, unitId);
            request.input('diff', sql.NVarChar, difficulty || 'Normal');

            // --- GIẢI THÍCH LOGIC MỚI (HƯỚNG B) ---
            // Chúng ta Join thêm bảng Students, Classes và Topics ngay trong phần lọc dữ liệu (CTE)
            // Và thêm điều kiện: c.GradeID = t.GradeID
            // Nghĩa là: Khối của Lớp học sinh phải BẰNG Khối của Bài học thì mới được tính xếp hạng.

            const query = `
                WITH RankedPlays AS (
                    SELECT 
                        ph.StudentID,
                        ph.Score,
                        ph.TimeTaken,
                        ROW_NUMBER() OVER (
                            PARTITION BY ph.StudentID 
                            ORDER BY ph.Score DESC, ph.TimeTaken ASC
                        ) as rn
                    FROM PlayHistory ph
                    -- Join các bảng để lấy thông tin Khối Lớp
                    JOIN Students s ON ph.StudentID = s.StudentID
                    JOIN Classes c ON s.ClassID = c.ClassID
                    JOIN Topics t ON ph.TopicID = t.TopicID
                    
                    WHERE ph.TopicID = @uid 
                      AND ph.Difficulty = @diff
                      AND c.GradeID = t.GradeID -- <--- ĐIỀU KIỆN QUAN TRỌNG NHẤT CỦA HƯỚNG B
                )
                SELECT TOP 20
                    u.FullName,
                    u.Username,
                    c.ClassName,
                    rp.Score as TotalScore,
                    rp.TimeTaken as TotalTime
                FROM RankedPlays rp
                JOIN Users u ON rp.StudentID = u.UserID
                LEFT JOIN Students s ON u.UserID = s.StudentID
                LEFT JOIN Classes c ON s.ClassID = c.ClassID
                WHERE rp.rn = 1
                ORDER BY rp.Score DESC, rp.TimeTaken ASC;
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