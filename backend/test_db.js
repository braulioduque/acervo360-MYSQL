const mysql = require('mysql2/promise');
require('dotenv').config({ path: '../.env' });

async function test() {
  const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'acervo360_db',
    port: parseInt(process.env.DB_PORT || '3306'),
  });

  try {
    const [rows] = await pool.query('SELECT name FROM clubs LIMIT 5');
    console.log(JSON.stringify(rows));
  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

test();
