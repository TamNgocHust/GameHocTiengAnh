const sql = require('mssql');

const leaderboardController = {
    
    getLeaderboard: async (req, res) => {
        try {
            // 1. Nhận tham số từ Frontend (unitId là bắt buộc để biết đang xem bảng xếp hạng bài nào)
            const { unitId, difficulty } = req.query;

            // Nếu chưa chọn Unit thì trả về danh sách rỗng (hoặc xử lý tùy ý)
            if (!unitId) {
                return res.json({ success: true, data: [] });
            }

            const request = new sql.Request();
            request.input('uid', sql.Int, unitId);
            request.input('diff', sql.NVarChar, difficulty || 'Normal');

            // --- CÂU LỆNH SQL NÂNG CAO (CTE) ---
            // Bước 1 (RankedPlays): Tìm tất cả lịch sử chơi của Unit này, Độ khó này.
            // Bước 2: Dùng ROW_NUMBER() để đánh số thứ tự cho mỗi học sinh:
            //         Dòng số 1 (rn=1) là dòng có Điểm cao nhất, Thời gian thấp nhất.
            // Bước 3: Chỉ lấy dòng số 1 (WHERE rp.rn = 1) để đưa vào bảng xếp hạng.
            
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
                    JOIN Games g ON ph.GameID = g.GameID
                    WHERE g.TopicID = @uid 
                      AND ph.Difficulty = @diff
                )
                SELECT TOP 20
                    u.FullName,
                    u.Username,
                    c.ClassName,  -- Lấy thêm tên lớp để hiển thị
                    rp.Score as TotalScore, -- Đây là điểm cao nhất
                    rp.TimeTaken as TotalTime
                FROM RankedPlays rp
                JOIN Users u ON rp.StudentID = u.UserID
                LEFT JOIN Students s ON u.UserID = s.StudentID
                LEFT JOIN Classes c ON s.ClassID = c.ClassID
                WHERE rp.rn = 1  -- Chỉ lấy thành tích tốt nhất của mỗi người
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