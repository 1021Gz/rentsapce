const mysql = require("mysql2");
const pool = mysql.createPool({
   host: 'localhost',
   user: 'root',
   password: '',
   database: 'rent_space'
});

module.exports = pool;
