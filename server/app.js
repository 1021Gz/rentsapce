const express = require('express');
const cors = require('cors');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const pool = require('./db_config');

const argon2 = (() => { try { return require('@node-rs/argon2'); } catch {} })();
const jwt = (() => { try { return require('jsonwebtoken'); } catch {} })();
const JWT_KEY = process.env.JWT_SECRET || 'rentspace-dev-jwt-secret';

const app = express();
const db = pool.promise();
const uploadsDir = path.join(__dirname, 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });

app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use('/uploads', express.static(uploadsDir));
pool.on('error', (err) => console.error('MySQL pool error:', err.message));

//------------------- Password Hashing & Verify -------------------
const hashPassword = (raw) =>
  argon2 ? argon2.hashSync(String(raw)) : crypto.createHash('sha256').update(String(raw)).digest('hex');

const verifyPassword = (stored, plain) => {
  if (stored && stored.startsWith('$argon2') && argon2) {
    try { return argon2.verifySync(stored, plain); } catch {}
  }
  const sha = crypto.createHash('sha256').update(String(plain)).digest('hex');
  return stored === plain || stored === sha;
};

//------------------- 1. Health & Sync -------------------
app.get('/api/health', async (_req, res) => {
  try {
    const [rows] = await db.query('SELECT DATABASE() AS databaseName');
    res.json({ ok: true, database: rows[0].databaseName });
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.get('/api/sync', async (_req, res) => {
  try {
    const [users] = await db.query('SELECT user_id, name, username, email, role, status FROM users');
    const [spaces] = await db.query('SELECT * FROM spaces');
    const [bookings] = await db.query('SELECT * FROM bookings');
    const [adminLogs] = await db.query('SELECT * FROM admin_logs ORDER BY log_id DESC LIMIT 50');
    res.json({ ok: true, users, spaces, bookings, admin_logs: adminLogs });
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.get('/api/password/:raw', (req, res) => res.send(hashPassword(req.params.raw)));

//------------------- 2. Auth (Register & Login) -------------------
app.post(['/api/register', '/api/auth/register'], async (req, res) => {
  try {
    const { username, email, password, full_name, role = 'customer' } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ ok: false, message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }
    const userRole = role === 'renter' ? 'customer' : role;
    const [insertResult] = await db.query(
      `INSERT INTO users (name, username, email, password_hash, role, status)
       VALUES (?, ?, ?, ?, ?, 'active')
       ON DUPLICATE KEY UPDATE
         user_id = LAST_INSERT_ID(user_id),
         name = VALUES(name),
         email = VALUES(email),
         password_hash = VALUES(password_hash),
         role = VALUES(role),
         status = 'active'`,
      [full_name || username, username.trim(), email.trim(), hashPassword(password), userRole]
    );
    res.status(201).json({
      ok: true,
      user: { user_id: insertResult.insertId, username, email, role: role === 'customer' ? 'renter' : role },
    });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

app.post(['/api/login', '/api/auth/login'], async (req, res) => {
  try {
    const { username, password } = req.body;
    const [matching] = await db.query('SELECT * FROM users WHERE username = ? LIMIT 1', [username]);
    if (matching.length === 0 || !verifyPassword(matching[0].password_hash, password)) {
      return res.status(401).json({ ok: false, message: 'Invalid username or password' });
    }
    const targetUser = matching[0];
    const clientRole = targetUser.role === 'customer' ? 'renter' : targetUser.role;
    const token = jwt
      ? jwt.sign({ id: targetUser.user_id, username: targetUser.username, role: clientRole }, JWT_KEY, { expiresIn: '8h' })
      : `token_${targetUser.user_id}_${Date.now()}`;
    res.json({
      ok: true,
      token,
      user: { user_id: targetUser.user_id, username: targetUser.username, role: clientRole, name: targetUser.name },
    });
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

//------------------- 3. Spaces -------------------
app.get('/api/spaces', async (req, res) => {
  try {
    const { keyword, category, status } = req.query;
    let sql = 'SELECT * FROM spaces WHERE 1=1';
    const params = [];
    if (status) { sql += ' AND status = ?'; params.push(status); }
    if (category) { sql += ' AND category = ?'; params.push(category); }
    if (keyword) {
      sql += ' AND (title LIKE ? OR description LIKE ? OR location LIKE ?)';
      params.push(`%${keyword}%`, `%${keyword}%`, `%${keyword}%`);
    }
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.get('/api/spaces/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM spaces WHERE space_id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ ok: false, message: 'Space not found' });
    res.json(rows[0]);
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.post('/api/spaces', async (req, res) => {
  try {
    const { owner_id = 1001, title, description = '', location, price_per_day = 500, category = 'general', capacity = 10, image_url = '' } = req.body;
    const [insertResult] = await db.query(
      `INSERT INTO spaces (owner_id, title, description, location, price_per_day, category, capacity, image_url, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [owner_id, title, description, location, price_per_day, category, capacity, image_url]
    );
    res.status(201).json({ ok: true, space_id: insertResult.insertId });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

app.patch('/api/spaces/:id', async (req, res) => {
  try {
    const fields = ['title', 'description', 'price_per_day', 'location', 'capacity', 'image_url', 'status'];
    const updates = fields.filter((k) => req.body[k] !== undefined);
    if (updates.length > 0) {
      const sql = `UPDATE spaces SET ${updates.map((k) => `${k} = ?`).join(', ')} WHERE space_id = ?`;
      await db.query(sql, [...updates.map((k) => req.body[k]), req.params.id]);
    }
    res.json({ ok: true });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

app.patch('/api/spaces/:id/active', async (req, res) => {
  const { is_active } = req.body || {};
  if (typeof is_active !== 'boolean') return res.status(400).json({ ok: false, message: 'is_active must be a boolean' });
  try {
    const [updateResult] = await db.query('UPDATE spaces SET is_active = ? WHERE space_id = ?', [Number(is_active), req.params.id]);
    if (updateResult.affectedRows === 0) return res.status(404).json({ ok: false, message: 'Space not found' });
    res.json({ ok: true, is_active: Number(is_active) });
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.patch('/api/admin/spaces/:id/approval', async (req, res) => {
  try {
    const { status = 'approved' } = req.body;
    await db.query('UPDATE spaces SET status = ? WHERE space_id = ?', [status, req.params.id]);
    res.json({ ok: true, status });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

//------------------- 4. Bookings, Payments, Reviews -------------------
app.get('/api/bookings', async (req, res) => {
  try {
    const { user_id, owner_id } = req.query;
    let sql = `SELECT b.*, s.title AS space_title, s.location, s.image_url, u.name AS customer_name
               FROM bookings b JOIN spaces s ON b.space_id = s.space_id JOIN users u ON b.customer_id = u.user_id WHERE 1=1`;
    const params = [];
    if (user_id) { sql += ' AND b.customer_id = ?'; params.push(user_id); }
    if (owner_id) { sql += ' AND s.owner_id = ?'; params.push(owner_id); }
    sql += ' ORDER BY b.booking_id DESC';
    const [rows] = await db.query(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.post('/api/bookings', async (req, res) => {
  try {
    const { space_id, customer_id = 1002, start_date, end_date, start_time, end_time, total_price = 0 } = req.body;
    const [insertResult] = await db.query(
      `INSERT INTO bookings (space_id, customer_id, start_date, end_date, start_time, end_time, total_price, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [space_id, customer_id, start_date, end_date, start_time, end_time, total_price]
    );
    res.status(201).json({ ok: true, booking_id: insertResult.insertId });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

app.patch('/api/bookings/:id/status', async (req, res) => {
  try {
    await db.query('UPDATE bookings SET status = ? WHERE booking_id = ?', [req.body.status, req.params.id]);
    res.json({ ok: true, status: req.body.status });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

app.patch('/api/bookings/:id/pay', async (req, res) => {
  try {
    const { payment_ref = `PAY-${Date.now()}`, slip_image_url = '' } = req.body;
    await db.query(
      'UPDATE bookings SET is_paid = 1, payment_ref = ?, slip_image_url = ?, status = "confirmed" WHERE booking_id = ?',
      [payment_ref, slip_image_url, req.params.id]
    );
    res.json({ ok: true, is_paid: 1, payment_ref });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

app.post('/api/bookings/:id/review', async (req, res) => {
  try {
    const { rating = 5, review_comment = '' } = req.body;
    await db.query('UPDATE bookings SET rating = ?, review_comment = ? WHERE booking_id = ?', [rating, review_comment, req.params.id]);
    res.json({ ok: true, rating: Number(rating), review_comment });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

//------------------- 5. Uploads, Admin Logs & Stats -------------------
app.post('/api/upload', async (req, res) => {
  const { filename, base64Data } = req.body || {};
  if (!filename || !base64Data) return res.status(400).json({ ok: false, message: 'filename and base64Data are required' });
  const ext = path.extname(filename).toLowerCase();
  if (!['.png', '.jpg', '.jpeg', '.webp'].includes(ext)) return res.status(400).json({ ok: false, message: 'Supported images: png, jpg, jpeg, webp' });
  try {
    const bytes = Buffer.from(base64Data, 'base64');
    const isPng = bytes.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex'));
    const isJpeg = bytes.subarray(0, 3).equals(Buffer.from('ffd8ff', 'hex'));
    const isWebp = bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP';
    if (!(ext === '.png' ? isPng : ext === '.webp' ? isWebp : isJpeg)) {
      return res.status(400).json({ ok: false, message: 'Image content does not match filename extension' });
    }
    const storedName = `${crypto.randomUUID()}${ext}`;
    await fs.promises.writeFile(path.join(uploadsDir, storedName), bytes);
    res.status(201).json({ ok: true, filename: storedName, url: `${req.protocol}://${req.get('host')}/uploads/${storedName}` });
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.get('/api/uploads', (_req, res) => {
  try {
    const files = fs.readdirSync(uploadsDir).filter((f) => /\.(jpg|jpeg|png|webp)$/i.test(f)).map((name) => ({
      name,
      url: `http://localhost:${process.env.PORT || 3000}/uploads/${name}`,
    }));
    res.json({ ok: true, files });
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.post('/api/admin/logs', async (req, res) => {
  try {
    const { admin_id = 1003, admin_name = 'Admin', action = 'LOG', target_type = 'system', target_id = 0, details = '' } = req.body;
    const [result] = await db.query(
      'INSERT INTO admin_logs (admin_id, admin_name, action, target_type, target_id, details) VALUES (?, ?, ?, ?, ?, ?)',
      [admin_id, admin_name, action, target_type, target_id, details]
    );
    res.status(201).json({ ok: true, log_id: result.insertId });
  } catch (err) { res.status(400).json({ ok: false, error: err.message }); }
});

app.get('/api/admin/stats', async (_req, res) => {
  try {
    const [[users]] = await db.query('SELECT COUNT(*) AS total_users FROM users');
    const [[spaces]] = await db.query('SELECT COUNT(*) AS total_spaces, SUM(CASE WHEN status = "pending" THEN 1 ELSE 0 END) AS pending_spaces FROM spaces');
    const [[bookings]] = await db.query('SELECT COUNT(*) AS total_bookings, COALESCE(SUM(total_price), 0) AS total_revenue FROM bookings');
    res.json({
      ok: true,
      stats: {
        total_users: Number(users.total_users),
        total_spaces: Number(spaces.total_spaces),
        pending_spaces: Number(spaces.pending_spaces || 0),
        total_bookings: Number(bookings.total_bookings),
        total_revenue: Number(bookings.total_revenue),
      },
    });
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

app.patch('/api/admin/users/:id/status', async (req, res) => {
  try {
    const { status } = req.body || {};
    if (!['active', 'suspended'].includes(status)) return res.status(400).json({ ok: false, message: 'status must be active or suspended' });
    const [result] = await db.query('UPDATE users SET status = ? WHERE user_id = ?', [status, req.params.id]);
    if (result.affectedRows === 0) return res.status(404).json({ ok: false, message: 'User not found' });
    res.json({ ok: true, user_id: Number(req.params.id), status });
  } catch (err) { res.status(500).json({ ok: false, error: err.message }); }
});

//=================== Starting server =======================
const port = Number(process.env.PORT || 3000);
if (require.main === module) {
  app.listen(port, () => console.log('RentSpace Simple API Server running on port ' + port));
}

module.exports = app;
