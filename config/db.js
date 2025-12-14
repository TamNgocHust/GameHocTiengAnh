const sql = require('mssql');

const config = {
    user: 'GameUser',
    password: '123456',
    server: 'DESKTOP-HRMHVJB', // Tên máy tính của bạn
    database: 'GameHocTiengAnh1',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        instanceName: 'SQLEXPRESS' // Tên instance SQL
    }
};

async function connectDB() {
    try {
        let pool = await sql.connect(config);
        console.log("--> Đã kết nối Database thành công!");
        return pool;
    } catch (err) {
        console.log("--> Lỗi kết nối Database: ", err);
    }
}

// Xuất cả hàm connect và đối tượng sql để các file khác dùng
module.exports = { connectDB, sql };