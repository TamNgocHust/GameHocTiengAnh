const sql = require('mssql');

// Lấy danh sách Từ vựng theo Unit
const getVocab = async (req, res) => {
    try {
        const { unitId } = req.params; // Lấy ID từ link (VD: /vocab/1)
        
        // Nếu không có ID hoặc ID = 0 (tránh lỗi logic)
        if (!unitId) return res.json([]);

        const request = new sql.Request();
        request.input('id', sql.Int, unitId);

        // Gọi Database
        const result = await request.query(`
            SELECT * FROM Vocabulary 
            WHERE TopicID = @id
        `);

        res.json(result.recordset);
    } catch (error) {
        console.error("Lỗi lấy từ vựng:", error);
        res.status(500).json({ message: "Lỗi Server khi lấy từ vựng" });
    }
};

// Lấy danh sách Ngữ pháp theo Unit
const getGrammar = async (req, res) => {
    try {
        const { unitId } = req.params;

        if (!unitId) return res.json([]);

        const request = new sql.Request();
        request.input('id', sql.Int, unitId);

        const result = await request.query(`
            SELECT * FROM Grammar 
            WHERE TopicID = @id
        `);

        res.json(result.recordset);
    } catch (error) {
        console.error("Lỗi lấy ngữ pháp:", error);
        res.status(500).json({ message: "Lỗi Server khi lấy ngữ pháp" });
    }
};

// Xuất hàm ra để route sử dụng (QUAN TRỌNG)
module.exports = {
    getVocab,
    getGrammar
};