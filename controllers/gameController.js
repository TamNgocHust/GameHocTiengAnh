const sql = require('mssql');

function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

const gameController = {

    // --- ROUND 1: NỐI TỪ ---
    getRound1Data: async (req, res) => {
        try {
            const { unitId } = req.params;
            const request = new sql.Request();
            request.input('TopicPattern', sql.NVarChar, `Unit ${unitId}:%`);
            const result = await request.query(`SELECT TOP 10 o.OptionID, o.OptionContent FROM QuestionOptions o JOIN Questions q ON o.QuestionID = q.QuestionID JOIN Topics t ON q.TopicID = t.TopicID WHERE t.TopicName LIKE @TopicPattern AND q.QuestionType = 'matching' ORDER BY NEWID()`);
            if (result.recordset.length === 0) return res.status(404).json({ success: false, message: "No data" });
            let leftCol = [], rightCol = [];
            result.recordset.forEach(row => { try { const c = JSON.parse(row.OptionContent); leftCol.push({ id: row.OptionID, text: c.L }); rightCol.push({ id: row.OptionID, text: c.R }); } catch (e) {} });
            res.json({ success: true, totalPairs: leftCol.length, data: { leftColumn: shuffleArray(leftCol), rightColumn: shuffleArray(rightCol) } });
        } catch (err) { res.status(500).json({ success: false }); }
    },

    submitRound1: async (req, res) => {
        try {
            // Nhận thêm difficulty
            const { userId, answers, timeTaken, difficulty } = req.body;
            let score = 10, wrongCount = 0;
            if (answers) answers.forEach(p => { if (p.leftId !== p.rightId) wrongCount++; });
            score = Math.max(0, score - wrongCount);

            if (userId) {
                const reqSQL = new sql.Request();
                reqSQL.input('sid', userId).input('s', score).input('t', timeTaken);
                // Thêm input Difficulty
                reqSQL.input('diff', sql.NVarChar, difficulty || 'Normal'); 

                // Câu lệnh INSERT mới (Bỏ Stars, thêm Difficulty)
                await reqSQL.query("INSERT INTO PlayHistory (StudentID, GameID, Score, TimeTaken, PlayedAt, Difficulty) VALUES (@sid, 1, @s, @t, GETDATE(), @diff)");
            }
            res.json({ success: true, isPassed: score >= 5, score });
        } catch (err) { console.error(err); res.status(500).json({ success: false }); }
    },

    // --- ROUND 2: SẮP XẾP CÂU ---
    getRound2Data: async (req, res) => {
        try {
            const { unitId } = req.params;
            const request = new sql.Request();
            request.input('TopicPattern', sql.NVarChar, `Unit ${unitId}:%`);
            const result = await request.query(`SELECT TOP 10 o.OptionID, o.OptionContent FROM QuestionOptions o JOIN Questions q ON o.QuestionID = q.QuestionID JOIN Topics t ON q.TopicID = t.TopicID WHERE t.TopicName LIKE @TopicPattern AND q.QuestionType = 'scramble' ORDER BY NEWID()`);
            if (result.recordset.length === 0) return res.status(404).json({ success: false, message: "No data" });
            res.json({ success: true, totalSentences: result.recordset.length, data: result.recordset });
        } catch (err) { res.status(500).json({ success: false }); }
    },

    submitRound2: async (req, res) => {
        try {
            const { userId, score, timeTaken, difficulty } = req.body;
            if (userId) {
                const reqSQL = new sql.Request();
                reqSQL.input('sid', userId).input('s', score).input('t', timeTaken);
                reqSQL.input('diff', sql.NVarChar, difficulty || 'Normal');

                await reqSQL.query("INSERT INTO PlayHistory (StudentID, GameID, Score, TimeTaken, PlayedAt, Difficulty) VALUES (@sid, 2, @s, @t, GETDATE(), @diff)");
            }
            res.json({ success: true, isPassed: score >= 5 });
        } catch (err) { res.status(500).json({ success: false }); }
    },

    // --- ROUND 3: TRẮC NGHIỆM ---
    getRound3Data: async (req, res) => {
        try {
            const { unitId } = req.params;
            const request = new sql.Request();
            request.input('TopicPattern', sql.NVarChar, `Unit ${unitId}:%`);

            const qResult = await request.query(`
                SELECT TOP 10 q.QuestionID, q.QuestionText 
                FROM Questions q JOIN Topics t ON q.TopicID = t.TopicID 
                WHERE t.TopicName LIKE @TopicPattern AND q.QuestionType = 'multiple_choice' 
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
    },

    submitRound3: async (req, res) => {
        try {
            // Log body để debug nếu cần
            // console.log("Submit R3:", req.body);
            const { userId, answers, timeTaken, difficulty } = req.body;
            let score = 0;
            
            if (answers && answers.length > 0) {
                const selectedIds = answers.map(a => a.selectedOptionId).filter(id => id);
                if (selectedIds.length > 0) {
                    const result = await new sql.Request().query(`
                        SELECT COUNT(*) as Cnt FROM QuestionOptions 
                        WHERE OptionID IN (${selectedIds.join(',')}) AND (IsCorrect = 1 OR IsCorrect = 'true')
                    `);
                    score = result.recordset[0].Cnt;
                }
            }

            if (userId) {
                const reqSQL = new sql.Request();
                reqSQL.input('sid', userId).input('s', score).input('t', timeTaken);
                reqSQL.input('diff', sql.NVarChar, difficulty || 'Normal');

                await reqSQL.query("INSERT INTO PlayHistory (StudentID, GameID, Score, TimeTaken, PlayedAt, Difficulty) VALUES (@sid, 3, @s, @t, GETDATE(), @diff)");
            }
            res.json({ success: true, isPassed: score >= 5, score, total: 10 });
        } catch (err) { console.error(err); res.status(500).json({ success: false }); }
    },

    // --- ROUND 4: ĐIỀN TỪ ---
    getRound4Data: async (req, res) => {
        try {
            const { unitId } = req.params;
            const request = new sql.Request();
            request.input('TopicPattern', sql.NVarChar, `Unit ${unitId}:%`);
            const qResult = await request.query(`SELECT TOP 10 q.QuestionID, q.QuestionText, q.CorrectAnswer FROM Questions q JOIN Topics t ON q.TopicID = t.TopicID WHERE t.TopicName LIKE @TopicPattern AND q.QuestionType = 'fill_in_blank' ORDER BY NEWID()`);
            if (qResult.recordset.length === 0) return res.status(404).json({ success: false, message: "No data" });
            const data = qResult.recordset.map(q => ({ id: q.QuestionID, question: q.QuestionText, correctWord: q.CorrectAnswer }));
            res.json({ success: true, data });
        } catch (err) { res.status(500).json({ success: false }); }
    },

    submitRound4: async (req, res) => {
        try {
            const { userId, score, timeTaken, difficulty } = req.body;
            if (userId) {
                const reqSQL = new sql.Request();
                reqSQL.input('sid', sql.Int, userId);
                reqSQL.input('s', sql.Int, score);
                reqSQL.input('t', sql.Int, timeTaken);
                reqSQL.input('diff', sql.NVarChar, difficulty || 'Normal');
                
                // 1. Lưu điểm R4 (Có Difficulty)
                await reqSQL.query(`INSERT INTO PlayHistory (StudentID, GameID, Score, TimeTaken, PlayedAt, Difficulty) VALUES (@sid, 4, @s, @t, GETDATE(), @diff)`);

                // 2. Tính TỔNG
                const historyResult = await reqSQL.query(`SELECT GameID, Score, TimeTaken FROM PlayHistory WHERE StudentID = @sid ORDER BY PlayedAt DESC`);
                const gameResults = {};
                historyResult.recordset.forEach(row => {
                    if (!gameResults[row.GameID]) gameResults[row.GameID] = { score: row.Score, time: row.TimeTaken };
                });
                let totalScore = 0, totalTime = 0;
                [1, 2, 3, 4].forEach(gid => {
                    if (gameResults[gid]) { totalScore += gameResults[gid].score || 0; totalTime += gameResults[gid].time || 0; }
                });

                res.json({ success: true, isPassed: score >= 5, roundScore: score, totalScore: totalScore, totalTime: totalTime });
            } else { res.json({ success: false, message: "User ID missing" }); }
        } catch (err) { console.error(err); res.status(500).json({ success: false }); }
    }
};

module.exports = gameController;