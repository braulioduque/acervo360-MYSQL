const path = require('path');
const fs = require('fs');

console.log('--- DIAGNÓSTICO DE AMBIENTE ---');
console.log('Pasta do script:', __dirname);
console.log('Pasta de trabalho (CWD):', process.cwd());

const envPath = path.join(__dirname, '.env');
console.log('Procurando .env em:', envPath);

if (fs.existsSync(envPath)) {
  console.log('.env ENCONTRADO.');
  const dotenv = require('dotenv').config({ path: envPath });
  if (dotenv.error) {
    console.error('Erro ao carregar .env:', dotenv.error);
  } else {
    console.log('.env carregado com sucesso.');
  }
} else {
  console.log('.env NÃO ENCONTRADO na pasta do backend.');
}

console.log('\n--- VARIÁVEIS DE AMBIENTE ---');
console.log('DB_HOST:', process.env.DB_HOST);
console.log('DB_PORT:', process.env.DB_PORT);
console.log('DB_USER:', process.env.DB_USER);
console.log('DB_NAME:', process.env.DB_NAME);

console.log('\n--- TESTE DE CONEXÃO ---');
const mysql = require('mysql2/promise');

async function testConn() {
  try {
    const host = process.env.DB_HOST || 'localhost';
    console.log(`Tentando conectar a ${host}...`);
    const conn = await mysql.createConnection({
      host: host,
      user: process.env.DB_USER || 'acervo360_user',
      password: process.env.DB_PASS || 'Bw8gjlinux*',
      database: process.env.DB_NAME || 'acervo360_db',
      port: process.env.DB_PORT || 3306
    });
    console.log('✅ CONEXÃO COM SUCESSO!');
    await conn.end();
  } catch (err) {
    console.error('❌ FALHA NA CONEXÃO:', err.message);
    if (err.message.includes('ENOTFOUND')) {
      console.log('\nDIAGNÓSTICO: O host definido não foi encontrado no DNS.');
    }
  }
}

testConn();
