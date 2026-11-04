const express = require('express');
const cors = require('cors');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const con = require('./db_config');

// Prevent process crash if XAMPP MySQL is not yet started
con.on('error', (err) => {
  console.error('MySQL connection error:', err.message);
});

const app = express();
const db = con.promise();
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use('/uploads', express.static(uploadsDir));

function hashPassword(passwordString) {
  return crypto.createHash('sha256').update(String(passwordString)).digest('hex');
}

//------------------- 1. Health & Sync -------------------
app.get('/api/health', async (_req, res) => {
  try {
    const [rows] = await db.query('SELECT DATABASE() AS databaseName');
    res.json({ ok: true, database: rows[0].databaseName });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get('/api/sync', async (_req, res) => {
  try {
    const [users] = await db.query('SELECT user_id, name, username, email, role, status FROM users');
    const [spaces] = await db.query('SELECT * FROM spaces');
    const [bookings] = await db.query('SELECT * FROM bookings');
    const [adminLogs] = await db.query('SELECT * FROM admin_logs ORDER BY log_id DESC LIMIT 50');
    res.json({ ok: true, users, spaces, bookings, admin_logs: adminLogs });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get('/api/password/:raw', (req, res) => {
  res.send(hashPassword(req.params.raw));
});

//------------------- 2. Auth (Register & Login) -------------------
app.post(['/api/register', '/api/auth/register'], async (req, res) => {
  try {
    const { username, email, password, full_name, role = 'customer' } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ ok: false, message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }
    const userRole = role === 'renter' ? 'customer' : role;
    const [insertResult] = await db.query(
      'INSERT INTO users (name, username, email, password_hash, role, status) VALUES (?, ?, ?, ?, ?, "active")',
      [full_name || username, username.trim(), email.trim(), hashPassword(password), userRole]
    );
    res.status(201).json({
      ok: true,
      user: { user_id: insertResult.insertId, username, email, role: role === 'customer' ? 'renter' : role },
    });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.post(['/api/login', '/api/auth/login'], async (req, res) => {
  try {
    const { username, password } = req.body;
    const [matchingUsers] = await db.query('SELECT * FROM users WHERE username = ? LIMIT 1', [username]);
    if (matchingUsers.length === 0) {
      return res.status(401).json({ ok: false, message: 'Invalid username or password' });
    }
    const targetUser = matchingUsers[0];
    const incomingHash = hashPassword(password);
    const passwordMatched = targetUser.password_hash === incomingHash || targetUser.password_hash === password;
    if (!passwordMatched) {
      return res.status(401).json({ ok: false, message: 'Invalid username or password' });
    }
    const clientRole = targetUser.role === 'customer' ? 'renter' : targetUser.role;
    res.json({
      ok: true,
      token: `token_${targetUser.user_id}_${Date.now()}`,
      user: { user_id: targetUser.user_id, username: targetUser.username, role: clientRole, name: targetUser.name },
    });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

//------------------- 3. Spaces -------------------
app.get('/api/spaces', async (req, res) => {
  try {
    const { keyword, category, status } = req.query;
    let querySql = 'SELECT * FROM spaces WHERE 1=1';
    const queryParams = [];
    if (status) {
      querySql += ' AND status = ?';
      queryParams.push(status);
    }
    if (category) {
      querySql += ' AND category = ?';
      queryParams.push(category);
    }
    if (keyword) {
      querySql += ' AND (title LIKE ? OR description LIKE ? OR location LIKE ?)';
      const keywordPattern = `%${keyword}%`;
      queryParams.push(keywordPattern, keywordPattern, keywordPattern);
    }
    const [spaceRows] = await db.query(querySql, queryParams);
    res.json(spaceRows);
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get('/api/spaces/:id', async (req, res) => {
  try {
    const [spaceRows] = await db.query('SELECT * FROM spaces WHERE space_id = ?', [req.params.id]);
    if (spaceRows.length === 0) return res.status(404).json({ ok: false, message: 'Space not found' });
    res.json(spaceRows[0]);
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post('/api/spaces', async (req, res) => {
  try {
    const { owner_id, title, description, location, price_per_day, category, capacity, image_url } = req.body;
    const [insertResult] = await db.query(
      `INSERT INTO spaces (owner_id, title, description, location, price_per_day, category, capacity, image_url, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [owner_id || 1001, title, description, location, price_per_day || 500, category || 'general', capacity || 10, image_url || '']
    );
    res.status(201).json({ ok: true, space_id: insertResult.insertId });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.patch('/api/spaces/:id', async (req, res) => {
  try {
    const { title, description, price_per_day, location, capacity, image_url, status } = req.body;
    const updateAssignments = [];
    const updateValues = [];
    if (title) { updateAssignments.push('title = ?'); updateValues.push(title); }
    if (description) { updateAssignments.push('description = ?'); updateValues.push(description); }
    if (price_per_day) { updateAssignments.push('price_per_day = ?'); updateValues.push(price_per_day); }
    if (location) { updateAssignments.push('location = ?'); updateValues.push(location); }
    if (capacity) { updateAssignments.push('capacity = ?'); updateValues.push(capacity); }
    if (image_url) { updateAssignments.push('image_url = ?'); updateValues.push(image_url); }
    if (status) { updateAssignments.push('status = ?'); updateValues.push(status); }

    if (updateAssignments.length > 0) {
      updateValues.push(req.params.id);
      await db.query(`UPDATE spaces SET ${updateAssignments.join(', ')} WHERE space_id = ?`, updateValues);
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.patch('/api/admin/spaces/:id/approval', async (req, res) => {
  try {
    const { status = 'approved' } = req.body;
    await db.query('UPDATE spaces SET status = ? WHERE space_id = ?', [status, req.params.id]);
    res.json({ ok: true, status });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

//------------------- 4. Bookings, Payments, Reviews -------------------
app.get('/api/bookings', async (req, res) => {
  try {
    const { user_id, owner_id } = req.query;
    let querySql = `
      SELECT b.*, s.title AS space_title, s.location, s.image_url, u.name AS customer_name
      FROM bookings b
      JOIN spaces s ON b.space_id = s.space_id
      JOIN users u ON b.customer_id = u.user_id
      WHERE 1=1
    `;
    const queryParams = [];
    if (user_id) { querySql += ' AND b.customer_id = ?'; queryParams.push(user_id); }
    if (owner_id) { querySql += ' AND s.owner_id = ?'; queryParams.push(owner_id); }
    querySql += ' ORDER BY b.booking_id DESC';
    const [bookingRows] = await db.query(querySql, queryParams);
    res.json(bookingRows);
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post('/api/bookings', async (req, res) => {
  try {
    const { space_id, customer_id, start_date, end_date, start_time, end_time, total_price } = req.body;
    const [insertResult] = await db.query(
      `INSERT INTO bookings (space_id, customer_id, start_date, end_date, start_time, end_time, total_price, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [space_id, customer_id || 1002, start_date, end_date, start_time, end_time, total_price || 0]
    );
    res.status(201).json({ ok: true, booking_id: insertResult.insertId });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.patch('/api/bookings/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    await db.query('UPDATE bookings SET status = ? WHERE booking_id = ?', [status, req.params.id]);
    res.json({ ok: true, status });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.patch('/api/bookings/:id/pay', async (req, res) => {
  try {
    const { payment_ref, slip_image_url } = req.body;
    await db.query(
      'UPDATE bookings SET is_paid = 1, payment_ref = ?, slip_image_url = ?, status = "confirmed" WHERE booking_id = ?',
      [payment_ref || `PAY-${Date.now()}`, slip_image_url || '', req.params.id]
    );
    res.json({ ok: true, is_paid: 1, payment_ref });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.post('/api/bookings/:id/review', async (req, res) => {
  try {
    const { rating = 5, review_comment = '' } = req.body;
    await db.query('UPDATE bookings SET rating = ?, review_comment = ? WHERE booking_id = ?', [
      rating,
      review_comment,
      req.params.id,
    ]);
    res.json({ ok: true, rating: Number(rating), review_comment });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

//------------------- 5. Uploads & Admin -------------------
app.get('/api/uploads', (_req, res) => {
  try {
    const fileNames = fs.readdirSync(uploadsDir).filter((singleFile) => /\.(jpg|jpeg|png|webp)$/i.test(singleFile));
    const serverPort = process.env.PORT || 3000;
    const fileEntries = fileNames.map((singleName) => ({
      name: singleName,
      url: `http://localhost:${serverPort}/uploads/${singleName}`,
    }));
    res.json({ ok: true, files: fileEntries });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post('/api/admin/logs', async (req, res) => {
  try {
    const { admin_id = 1003, admin_name = 'Admin', action = 'LOG', target_type = 'system', target_id = 0, details = '' } = req.body;
    const [insertResult] = await db.query(
      'INSERT INTO admin_logs (admin_id, admin_name, action, target_type, target_id, details) VALUES (?, ?, ?, ?, ?, ?)',
      [admin_id, admin_name, action, target_type, target_id, details]
    );
    res.status(201).json({ ok: true, log_id: insertResult.insertId });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

//=================== Starting server =======================
const port = Number(process.env.PORT || 3000);
if (require.main === module) {
  app.listen(port, () => {
    console.log('RentSpace Simple API Server running on port ' + port);
  });
}

module.exports = app;
