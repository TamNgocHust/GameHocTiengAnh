const sql = require('mssql');

// --- HÀM HỖ TRỢ ---
function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

// ============================================================
// 1. CÁC HÀM XỬ LÝ LOGIC (Định nghĩa riêng lẻ cho sạch code)
// ============================================================

// --- HÀM TÍNH ĐIỂM CHUNG (Survival Mode) ---
// --- HÀM TÍNH ĐIỂM & LƯU KẾT QUẢ (LOGIC TRỪ ĐIỂM) ---
// --- HÀM TÍNH ĐIỂM & LƯU KẾT QUẢ ---
// --- HÀM TÍNH ĐIỂM & LƯU KẾT QUẢ ---
const saveGameResult = async (req, res) => {
    try {
        const studentId = req.body.studentId || req.body.userId;
        const topicId = req.body.topicId || req.body.unitId;
        const timeTaken = req.body.timeTaken || 0;
        let gameId = req.body.gameId; 
        
        // Nhận số lỗi từ Frontend gửi lên
        const wrongCount = req.body.wrongCount || 0;

        // Xử lý riêng cho Round 1 (Matching)
        if (req.body.answers && Array.isArray(req.body.answers)) {
             if (!gameId) gameId = 1; 
        }

        // --- TÍNH ĐIỂM: 100 - (Lỗi * 10) ---
        let finalScore = 100 - (wrongCount * 10);
        if (finalScore < 0) finalScore = 0;

        // --- SỬA LỖI ĐỘ KHÓ TẠI ĐÂY ---
        // Lấy độ khó từ Frontend gửi lên (Easy/Normal/Hard)
        let clientDiff = req.body.difficulty || 'Normal';
        
        // Viết hoa chữ cái đầu cho đẹp và đồng bộ Database (easy -> Easy)
        let difficulty = clientDiff.charAt(0).toUpperCase() + clientDiff.slice(1);

        console.log(`[SAVE] User:${studentId} | Game:${gameId} | Diff:${difficulty} | Score:${finalScore}`);

        // --- LƯU DATABASE ---
        if (studentId && topicId) {
            const pool = await sql.connect();
            const request = new sql.Request(pool);
            
            request.input('sid', sql.Int, studentId);
            request.input('gid', sql.Int, gameId || 1);
            request.input('uid', sql.Int, topicId);
            request.input('score', sql.Int, finalScore);
            request.input('time', sql.Int, timeTaken);
            request.input('diff', sql.NVarChar, difficulty); // Lưu đúng độ khó người chơi chọn

            const query = `
                INSERT INTO PlayHistory (StudentID, GameID, TopicID, Score, TimeTaken, PlayedAt, Difficulty) 
                VALUES (@sid, @gid, @uid, @score, @time, GETDATE(), @diff)
            `;
            await request.query(query);
        }

        res.json({ 
            success: true, 
            message: "Lưu thành công",
            score: finalScore, 
            isPassed: finalScore >= 50
        });

    } catch (err) {
        console.error("Lỗi saveGameResult:", err);
        res.status(500).json({ success: false, message: "Lỗi Server" });
    }
};
// --- LẤY DANH SÁCH UNIT ---
const getUnitsByGrade = async (req, res) => {
    try {
        const { grade } = req.query; 
        const gradeId = grade || 5; 
        const request = new sql.Request();
        request.input('gid', sql.Int, gradeId);
        const result = await request.query(`
            SELECT TopicID, TopicName 
            FROM Topics 
            WHERE GradeID = @gid
            ORDER BY TopicName ASC
        `);
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        console.error("Lỗi getUnits:", err);
        res.status(500).json({ success: false });
    }
};

// --- GET ROUND 1 DATA (NỐI TỪ) ---
const getRound1Data = async (req, res) => {
    try {
        const { unitId } = req.params; 
        const request = new sql.Request();
        request.input('uid', sql.Int, unitId); 
        const result = await request.query(`
            SELECT TOP 10 o.OptionID, o.OptionContent 
            FROM QuestionOptions o 
            JOIN Questions q ON o.QuestionID = q.QuestionID 
            JOIN Topics t ON q.TopicID = t.TopicID 
            WHERE t.TopicID = @uid AND q.QuestionType = 'matching' 
            ORDER BY NEWID()
        `);

        if (result.recordset.length === 0) return res.status(404).json({ success: false, message: "No data" });
        
        let leftCol = [], rightCol = [];
        result.recordset.forEach(row => { 
            try { 
                const c = JSON.parse(row.OptionContent); 
                leftCol.push({ id: row.OptionID, text: c.L }); 
                rightCol.push({ id: row.OptionID, text: c.R }); 
            } catch (e) {} 
        });
        
        res.json({ 
            success: true, 
            totalPairs: leftCol.length, 
            data: { leftColumn: shuffleArray(leftCol), rightColumn: shuffleArray(rightCol) } 
        });
    } catch (err) { 
        console.error(err); res.status(500).json({ success: false }); 
    }
};

// --- GET ROUND 2 DATA (SẮP XẾP CÂU) ---
const getRound2Data = async (req, res) => {
    try {
        const { unitId } = req.params;
        const request = new sql.Request();
        request.input('uid', sql.Int, unitId);

        const result = await request.query(`
            SELECT TOP 10 o.OptionID, o.OptionContent 
            FROM QuestionOptions o 
            JOIN Questions q ON o.QuestionID = q.QuestionID 
            JOIN Topics t ON q.TopicID = t.TopicID 
            WHERE t.TopicID = @uid AND q.QuestionType = 'scramble' 
            ORDER BY NEWID()
        `);

        if (result.recordset.length === 0) return res.status(404).json({ success: false, message: "No data" });
        res.json({ success: true, totalSentences: result.recordset.length, data: result.recordset });
    } catch (err) { res.status(500).json({ success: false }); }
};

// --- GET ROUND 3 DATA (TRẮC NGHIỆM) ---
const getRound3Data = async (req, res) => {
    try {
        const { unitId } = req.params;
        const request = new sql.Request();
        request.input('uid', sql.Int, unitId);

        const qResult = await request.query(`
            SELECT TOP 10 q.QuestionID, q.QuestionText 
            FROM Questions q JOIN Topics t ON q.TopicID = t.TopicID 
            WHERE t.TopicID = @uid AND q.QuestionType = 'multiple_choice' 
            ORDER BY NEWID()
        `);

        if (qResult.recordset.length === 0) return res.status(404).json({ success: false, message: "No data" });
        const qIds = qResult.recordset.map(q => q.QuestionID);
        
        const optResult = await new sql.Request().query(`SELECT * FROM QuestionOptions WHERE QuestionID IN (${qIds.join(',')}) ORDER BY NEWID()`);

        const data = qResult.recordset.map(q => ({
            id: q.QuestionID, 
            question: q.QuestionText,
            options: optResult.recordset
                .filter(o => o.QuestionID === q.QuestionID)
                .map(o => {
                    const correctVal = (o.IsCorrect !== undefined) ? o.IsCorrect : o.isCorrect;
                    return { id: o.OptionID, text: o.OptionContent, IsCorrect: correctVal };
                })
        }));
        res.json({ success: true, data });
    } catch (err) { res.status(500).json({ success: false }); }
};

// --- GET ROUND 4 DATA (ĐIỀN TỪ) ---
const getRound4Data = async (req, res) => {
    try {
        const { unitId } = req.params;
        const request = new sql.Request();
        request.input('uid', sql.Int, unitId);

        const qResult = await request.query(`
            SELECT TOP 10 q.QuestionID, q.QuestionText, q.CorrectAnswer 
            FROM Questions q JOIN Topics t ON q.TopicID = t.TopicID 
            WHERE t.TopicID = @uid AND q.QuestionType = 'fill_in_blank' 
            ORDER BY NEWID()
        `);

        if (qResult.recordset.length === 0) return res.status(404).json({ success: false, message: "No data" });
        const data = qResult.recordset.map(q => ({ id: q.QuestionID, question: q.QuestionText, correctWord: q.CorrectAnswer }));
        res.json({ success: true, data });
    } catch (err) { res.status(500).json({ success: false }); }
};

// ============================================================
// 2. EXPORT CÁC HÀM (Phần quan trọng nhất để Routes gọi)
// ============================================================
module.exports = {
    getUnitsByGrade,
    getRound1Data,
    getRound2Data,
    getRound3Data,
    getRound4Data,
    
    // Xuất hàm lưu điểm
    saveGameResult,

    // Mapping tên cũ sang hàm mới (để gameRoutes.js gọi không lỗi)
    submitRound1: saveGameResult,
    submitRound2: saveGameResult,
    submitRound3: saveGameResult,
    submitRound4: saveGameResult
};