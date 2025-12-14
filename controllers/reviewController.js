const { connectDB, sql } = require('../config/db');

// 1. Lấy danh sách Từ Vựng theo Unit
exports.getVocabulary = async (req, res) => {
    try {
        const { unitId } = req.params;
        const pool = await connectDB();

        // Tạo pattern tìm kiếm: "Unit 1:%" 
        // (Để tránh tìm nhầm sang Unit 10, 11...)
        const topicPattern = 'Unit ' + unitId + ':%'; 

        const result = await pool.request()
            .input('TopicParam', sql.NVarChar, topicPattern)
            .query(`
                SELECT Word, Meaning, Pronunciation, Example, WordType 
                FROM Vocabulary 
                WHERE TopicID = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE @TopicParam)
            `);

        res.json(result.recordset);

    } catch (err) {
        console.error('Lỗi Vocab:', err);
        res.status(500).json({ error: err.message });
    }
};

// 2. Lấy danh sách Ngữ Pháp theo Unit
exports.getGrammar = async (req, res) => {
    try {
        const { unitId } = req.params;
        const pool = await connectDB();

        const topicPattern = 'Unit ' + unitId + ':%';

        const result = await pool.request()
            .input('TopicParam', sql.NVarChar, topicPattern)
            .query(`
                SELECT GrammarName, Structure, Usage, Example
                FROM Grammar 
                WHERE TopicID = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE @TopicParam)
            `);

        res.json(result.recordset);

    } catch (err) {
        console.error('Lỗi Grammar:', err);
        res.status(500).json({ error: err.message });
    }
};