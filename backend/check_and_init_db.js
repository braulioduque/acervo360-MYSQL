const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env'), override: true });

async function init() {
  const connectionConfig = {
    host: process.env.DB_HOST || '127.0.0.1',
    user: process.env.DB_USER || 'acervo360_user',
    password: process.env.DB_PASS || 'Bw8gjlinux*',
    database: process.env.DB_NAME || 'acervo360_db',
    port: parseInt(process.env.DB_PORT || '3306'),
    multipleStatements: true
  };

  console.log(`Connecting to ${connectionConfig.host}:${connectionConfig.port} as ${connectionConfig.user}...`);

  let connection;
  try {
    connection = await mysql.createConnection(connectionConfig);
    console.log('✅ Connected successfully.');

    // Check if tables exist
    const [rows] = await connection.query("SHOW TABLES LIKE 'profiles'");
    if (rows.length === 0) {
      console.log('📦 No tables found. Initializing schema from init.sql...');
      const sql = fs.readFileSync(path.join(__dirname, 'init.sql'), 'utf8');
      
      // Remove comments and split by semicolon might be tricky, 
      // but multipleStatements: true allows executing the whole file if it's valid.
      await connection.query(sql);
      console.log('✨ Schema initialized successfully.');
    } else {
      console.log('✅ Database schema already exists.');
    }

  } catch (err) {
    console.error('❌ Error:', err.message);
    if (err.code === 'ER_ACCESS_DENIED_ERROR') {
      console.log('💡 TIP: Check if the user has permissions to connect from this host or if the password is correct.');
    }
  } finally {
    if (connection) await connection.end();
  }
}

init();
