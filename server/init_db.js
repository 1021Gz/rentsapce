const fs = require('node:fs/promises');
const path = require('node:path');
const mysql = require('mysql2/promise');

async function main() {
  const sql = await fs.readFile(path.join(__dirname, 'schema.sql'), 'utf8');
  const con = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
  });
  try {
    await con.query(sql);
    console.log('Database rent_space was replaced using schema.sql.');
  } finally {
    await con.end();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
