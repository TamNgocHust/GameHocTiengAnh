const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();
app.use(cors()); // Cho phép web (frontend) gọi vào server này

// === CẤU HÌNH KẾT NỐI DATABASE ===
const dbConfig= {
    user: 'GameUser',
    password: '123456',
    
    // 1. Chỉ điền tên máy tính vào đây
    server: 'DESKTOP-HRMHVJB', 
    
    database: 'GameHocTiengAnh1',
    
    options: {
        encrypt: false, 
        trustServerCertificate: true,
        // 2. Điền tên instance vào đây (SQLEXPRESS)
        instanceName: 'SQLEXPRESS' 
    }
    // LƯU Ý: Khi dùng instanceName, KHÔNG cần khai báo port: 1433 
    // (Trừ khi bạn đã cố định port trong SQL Config Manager)
};

// === 2. API TỪ VỰNG (Đã sửa lỗi nhận nhầm Unit 1 thành Unit 10) ===
app.get('/api/vocab/:unitId', async (req, res) => {
    try {
        const unitId = req.params.unitId;
        const pool = await sql.connect(dbConfig);
        
        // SỬA LỖI: Thêm dấu hai chấm ":" vào sau số Unit
        // Để khi tìm "Unit 1:", nó sẽ không bị nhầm sang "Unit 10:", "Unit 11:"
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
        res.status(500).send(err.message);
    }
});
// === 3. API NGỮ PHÁP ===
app.get('/api/grammar/:unitId', async (req, res) => {
    try {
        const unitId = req.params.unitId;
        const pool = await sql.connect(dbConfig);
        
        const topicPattern = 'Unit ' + unitId + ':%'; // Thêm dấu hai chấm tương tự

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
        res.status(500).send(err.message);
    }
});

// === KHỞI ĐỘNG SERVER ===
const PORT = 5000;
app.listen(PORT, () => {
    console.log(`Server Backend đang chạy tại: http://localhost:${PORT}`);
});