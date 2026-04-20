const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

async function test() {
  const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || '',
    database: process.env.DB_NAME || 'acervo360_db',
    port: parseInt(process.env.DB_PORT || '3366'),
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
