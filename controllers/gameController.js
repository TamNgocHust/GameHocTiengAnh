const sql = require('mssql');

// Cấu hình Database (Nên khớp với server.js)
const config = {
    user: 'GameUser',
    password: '123456',
    server: 'DESKTOP-HRMHVJB\\SQLEXPRESS', // Chú ý: Dùng 2 dấu gạch chéo \\
    database: 'GameHocTiengAnh1',
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

// Hàm tiện ích: Xáo trộn mảng
function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

const gameController = {

    // =========================================================
    // ROUND 1: NỐI TỪ VỰNG (MATCHING)
    // =========================================================
    
    // GET /api/game/round1
    getRound1Data: async (req, res) => {
        try {
            // Sử dụng new sql.Request() sẽ tự động dùng kết nối toàn cục từ server.js
            // Nếu server.js chưa kết nối, dòng này sẽ lỗi. Đảm bảo server.js đã chạy connectDB().
            const request = new sql.Request();

            // 1. Lấy ngẫu nhiên 10 cặp từ Topic "Game Round 1 Pool"
            const query = `
                SELECT TOP 10 o.OptionID, o.OptionContent
                FROM QuestionOptions o
                JOIN Questions q ON o.QuestionID = q.QuestionID
                JOIN Topics t ON q.TopicID = t.TopicID
                WHERE t.TopicName = N'Game Round 1 Pool' 
                  AND q.QuestionType = 'matching'
                ORDER BY NEWID()
            `;

            const result = await request.query(query);

            if (result.recordset.length === 0) {
                return res.status(404).json({ msg: "Chưa có dữ liệu cho Round 1. Hãy chạy Script SQL tạo câu hỏi!" });
            }

            let leftCol = [];
            let rightCol = [];

            // Xử lý JSON {"L": "...", "R": "..."}
            result.recordset.forEach(row => {
                try {
                    const content = JSON.parse(row.OptionContent); 
                    
                    leftCol.push({
                        id: row.OptionID,
                        text: content.L  // Tiếng Anh
                    });

                    rightCol.push({
                        id: row.OptionID,
                        text: content.R  // Tiếng Việt
                    });
                } catch (e) {
                    console.error("Lỗi JSON tại ID: " + row.OptionID);
                }
            });

            // Xáo trộn cột phải
            rightCol = shuffleArray(rightCol);

            res.json({
                success: true,
                roundName: "Vòng 1: Thử thách từ vựng",
                totalPairs: 10,
                data: {
                    leftColumn: leftCol,
                    rightColumn: rightCol
                }
            });

        } catch (err) {
            console.error("❌ Lỗi Round 1:", err);
            res.status(500).send("Lỗi Server Round 1");
        }
    },

    // POST /api/game/submit-round1
    submitRound1: async (req, res) => {
        try {
            const { studentId, answers, timeTaken } = req.body; 
            
            // Logic chấm điểm Server (An toàn hơn để Client tự chấm)
            let score = 10;
            let wrongCount = 0;

            answers.forEach(pair => {
                if (pair.leftId !== pair.rightId) {
                    wrongCount++;
                }
            });

            score = score - wrongCount;
            if (score < 0) score = 0;
            
            // Quy đổi ra sao (Ví dụ: 10đ = 3 sao, 8-9đ = 2 sao, 5-7đ = 1 sao, dưới 5 = 0 sao)
            let stars = 0;
            if (score === 10) stars = 3;
            else if (score >= 8) stars = 2;
            else if (score >= 5) stars = 1;

            const isPassed = score >= 5;

            // LƯU VÀO DATABASE
            if (studentId) {
                const request = new sql.Request();
                // Giả sử GameID = 1 là Round 1
                const queryHistory = `
                    INSERT INTO PlayHistory (StudentID, GameID, Score, Stars, TimeTaken, PlayedAt)
                    VALUES (@sid, 1, @score, @stars, @time, GETDATE())
                `;
                request.input('sid', sql.Int, studentId);
                request.input('score', sql.Int, score);
                request.input('stars', sql.Int, stars);
                request.input('time', sql.Int, timeTaken || 0);
                
                await request.query(queryHistory);
            }

            res.json({
                success: true,
                isPassed: isPassed,
                score: score,
                stars: stars,
                message: isPassed ? "Chúc mừng! Bạn đã qua màn." : "Rất tiếc, hãy thử lại nhé!",
                nextRoundUrl: isPassed ? "/game/round2" : null
            });

        } catch (err) {
            console.error(err);
            res.status(500).send("Lỗi chấm điểm Round 1");
        }
    },

    // =========================================================
    // ROUND 2: SẮP XẾP CÂU (SCRAMBLE)
    // =========================================================

    // GET /api/game/round2
    getRound2Data: async (req, res) => {
        console.log("📡 Đang lấy dữ liệu Round 2...");
        try {
            const request = new sql.Request();

            // Lấy 5 câu ngẫu nhiên từ Topic "Game Round 2 Pool"
            // Lưu ý: OptionContent ở đây là câu tiếng Anh hoàn chỉnh (VD: "I love my family")
            const query = `
                SELECT TOP 10 o.OptionID, o.OptionContent
                FROM QuestionOptions o
                JOIN Questions q ON o.QuestionID = q.QuestionID
                JOIN Topics t ON q.TopicID = t.TopicID
                WHERE t.TopicName = N'Game Round 2 Pool' 
                  AND q.QuestionType = 'scramble'
                ORDER BY NEWID()
            `;

            const result = await request.query(query);

            if (result.recordset.length === 0) {
                return res.status(404).json({ msg: "Chưa có dữ liệu Round 2. Hãy chạy script SQL tạo Round 2!" });
            }

            // Trả về danh sách câu đúng. Frontend sẽ tự lo việc:
            // 1. Split (tách từ) -> 2. Shuffle (xáo trộn) -> 3. Hiển thị
            res.json({
                success: true,
                roundName: "Vòng 2: Trật tự câu",
                totalSentences: 10,
                data: result.recordset // Trả về mảng [{OptionContent: "Câu đúng..."}, ...]
            });

        } catch (err) {
            console.error("❌ Lỗi lấy dữ liệu Round 2:", err);
            res.status(500).json({ success: false, message: "Lỗi Server Round 2" });
        }
    },

    // POST /api/game/submit-round2
    submitRound2: async (req, res) => {
        // Đối với Round 2, Frontend thường chấm điểm (so sánh chuỗi user xếp với chuỗi gốc)
        // Sau đó Frontend gửi kết quả (Score, Stars) về đây để lưu.
        try {
            const { studentId, score, stars, timeTaken } = req.body;

            console.log(`💾 Lưu điểm Round 2 - User: ${studentId}, Score: ${score}, Stars: ${stars}`);

            if (studentId) {
                const request = new sql.Request();
                
                // Giả sử GameID = 2 là Round 2
                // (Đảm bảo bạn đã INSERT INTO Games một bản ghi có ID = 2 hoặc sửa số này cho khớp DB)
                const query = `
                    INSERT INTO PlayHistory (StudentID, GameID, Score, Stars, TimeTaken, PlayedAt)
                    VALUES (@sid, 2, @score, @stars, @time, GETDATE())
                `;
                
                request.input('sid', sql.Int, studentId);
                request.input('score', sql.Int, score);
                request.input('stars', sql.Int, stars);
                request.input('time', sql.Int, timeTaken || 0);

                await request.query(query);
            }

            res.json({ 
                success: true, 
                message: "Lưu kết quả Round 2 thành công!",
                isPassed: score >= 5 // Ví dụ luật: trên 5 điểm là qua
            });

        } catch (err) {
            console.error("❌ Lỗi lưu điểm Round 2:", err);
            res.status(500).json({ success: false, message: "Lỗi Database khi lưu Round 2" });
        }
    }
};

module.exports = gameController;