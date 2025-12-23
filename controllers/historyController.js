const sql = require('mssql');

const historyController = {
    
    getPlayHistory: async (req, res) => {
        try {
            const { userId } = req.params;
            const request = new sql.Request();
            request.input('sid', sql.Int, userId);

            // SELECT thêm cột Difficulty (và bỏ cột Stars)
            const result = await request.query(`
                SELECT GameID, Score, TimeTaken, PlayedAt, Difficulty 
                FROM PlayHistory 
                WHERE StudentID = @sid 
                ORDER BY PlayedAt DESC
            `);

            const gameNames = {
                1: "Round 1: Nối từ",
                2: "Round 2: Sắp xếp câu",
                3: "Round 3: Trắc nghiệm",
                4: "Round 4: Điền từ"
            };

            const history = result.recordset.map(row => ({
                gameName: gameNames[row.GameID] || `Game ${row.GameID}`,
                score: row.Score,
                timeTaken: row.TimeTaken,
                playedAt: row.PlayedAt,
                difficulty: row.Difficulty || 'Normal' // Trả về độ khó để Frontend hiển thị
            }));

            res.json({ success: true, data: history });
        } catch (err) {
            console.error("Lỗi lấy lịch sử:", err);
            res.status(500).json({ success: false, message: "Lỗi server khi tải lịch sử" });
        }
    }
};

module.exports = historyController;