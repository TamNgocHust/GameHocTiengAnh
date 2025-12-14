const sql = require('mssql');

const config = {
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

async function testConnection() {
    try {
        console.log(`⏳ Đang kết nối tới ${config.server}\\${config.options.instanceName}...`);
        
        let pool = await sql.connect(config);
        console.log("✅ Kết nối thành công!");

        // Test query
        const result = await pool.request().query('SELECT @@VERSION as version');
        console.log("🖥️ Phiên bản SQL Server:", result.recordset[0].version);

        await pool.close();
        console.log("🔒 Đã đóng kết nối.");

    } catch (err) {
        console.error("❌ KẾT NỐI THẤT BẠI:", err.message);
        
        if (err.code === 'ESOCKET') {
             console.log("💡 Gợi ý: Hãy đảm bảo service 'SQL Server Browser' đang chạy (Running) vì bạn đang dùng tên máy cụ thể.");
        }
    }
}

testConnection();