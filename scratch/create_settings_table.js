const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env'), override: true });

async function run() {
  const connectionConfig = {
    host: process.env.DB_HOST || '127.0.0.1',
    user: process.env.DB_USER || 'acervo360_user',
    password: process.env.DB_PASS || 'Bw8gjlinux*',
    database: process.env.DB_NAME || 'acervo360_db',
    port: parseInt(process.env.DB_PORT || '3306'),
    multipleStatements: true
  };

  console.log(`Connecting to ${connectionConfig.host}:${connectionConfig.port}...`);

  let connection;
  try {
    connection = await mysql.createConnection(connectionConfig);
    
    const sql = `
      CREATE TABLE IF NOT EXISTS app_settings (
          id INT PRIMARY KEY,
          cr_days INT DEFAULT 90,
          craf_days INT DEFAULT 90,
          gte_days INT DEFAULT 45,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      );
      INSERT IGNORE INTO app_settings (id, cr_days, craf_days, gte_days) VALUES (1, 90, 90, 45);
    `;
    
    await connection.query(sql);
    console.log('✅ Table app_settings created and initialized.');

  } catch (err) {
    console.error('❌ Error:', err.message);
  } finally {
    if (connection) await connection.end();
  }
}

run();
