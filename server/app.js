const express = require('express');
const cors = require('cors');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const pool = require('./db_config');

let argon2;
try {
  argon2 = require('@node-rs/argon2');
} catch (error) {
  // Use crypto fallback if argon2 is not available
}

let jwt;
try {
  jwt = require('jsonwebtoken');
} catch (error) {
  // Fallback token if jwt is not available
}

const JWT_KEY = process.env.JWT_SECRET || 'rentspace-dev-jwt-secret';

const app = express();
const db = pool.promise();
const uploadsDir = path.join(__dirname, 'uploads');

if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use('/uploads', express.static(uploadsDir));

// ---------------- Helper Functions ----------------
function hashPassword(plainText) {
  if (argon2) {
    try {
      return argon2.hashSync(String(plainText));
    } catch (err) {}
  }
  return crypto.createHash('sha256').update(String(plainText)).digest('hex');
}

function verifyPassword(storedHash, plainPassword) {
  if (storedHash && storedHash.startsWith('$argon2') && argon2) {
    try {
      return argon2.verifySync(storedHash, plainPassword);
    } catch (err) {}
  }
  const sha = crypto.createHash('sha256').update(String(plainPassword)).digest('hex');
  return storedHash === plainPassword || storedHash === sha;
}

// ---------------- 1. Health & Sync ----------------
app.get('/api/health', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT DATABASE() AS databaseName');
    res.json({ ok: true, database: rows[0].databaseName });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get('/api/sync', async (req, res) => {
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

// ---------------- 2. Authentication ----------------
app.post(['/api/register', '/api/auth/register'], async (req, res) => {
  try {
    const { username, email, password, full_name, role = 'customer' } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ ok: false, message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }
    const userRole = role === 'renter' ? 'customer' : role;
    const name = full_name || username;
    const hashedPassword = hashPassword(password);

    const sql = `
      INSERT INTO users (name, username, email, password_hash, role, status)
      VALUES (?, ?, ?, ?, ?, 'active')
      ON DUPLICATE KEY UPDATE
        user_id = LAST_INSERT_ID(user_id),
        name = VALUES(name),
        email = VALUES(email),
        password_hash = VALUES(password_hash),
        role = VALUES(role),
        status = 'active'
    `;
    const [insertResult] = await db.query(sql, [
      name,
      username.trim(),
      email.trim(),
      hashedPassword,
      userRole,
    ]);

    res.status(201).json({
      ok: true,
      user: {
        user_id: insertResult.insertId,
        username,
        email,
        role: role === 'customer' ? 'renter' : role,
      },
    });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.post(['/api/login', '/api/auth/login'], async (req, res) => {
  try {
    const { username, password } = req.body;
    const [rows] = await db.query('SELECT * FROM users WHERE username = ? LIMIT 1', [username]);

    if (rows.length === 0) {
      return res.status(401).json({ ok: false, message: 'Invalid username or password' });
    }

    const account = rows[0];
    const isMatched = verifyPassword(account.password_hash, password);
    if (!isMatched) {
      return res.status(401).json({ ok: false, message: 'Invalid username or password' });
    }

    const clientRole = account.role === 'customer' ? 'renter' : account.role;
    let token = `token_${account.user_id}_${Date.now()}`;
    if (jwt) {
      token = jwt.sign(
        { id: account.user_id, username: account.username, role: clientRole },
        JWT_KEY,
        { expiresIn: '8h' }
      );
    }

    res.json({
      ok: true,
      token,
      user: {
        user_id: account.user_id,
        username: account.username,
        role: clientRole,
        name: account.name,
      },
    });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// ---------------- 3. Space Management ----------------
app.get('/api/spaces', async (req, res) => {
  try {
    const { keyword, category, status } = req.query;
    let sql = 'SELECT * FROM spaces WHERE 1=1';
    const params = [];

    if (status) {
      sql += ' AND status = ?';
      params.push(status);
    }
    if (category) {
      sql += ' AND category = ?';
      params.push(category);
    }
    if (keyword) {
      sql += ' AND (title LIKE ? OR description LIKE ? OR location LIKE ?)';
      params.push(`%${keyword}%`, `%${keyword}%`, `%${keyword}%`);
    }

    const [spaces] = await db.query(sql, params);
    res.json(spaces);
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get('/api/spaces/:id', async (req, res) => {
  try {
    const [spaces] = await db.query('SELECT * FROM spaces WHERE space_id = ?', [req.params.id]);
    if (spaces.length === 0) {
      return res.status(404).json({ ok: false, message: 'Space not found' });
    }
    res.json(spaces[0]);
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post('/api/spaces', async (req, res) => {
  try {
    const {
      owner_id = 1001,
      title,
      description = '',
      location,
      price_per_day = 500,
      category = 'general',
      capacity = 10,
      image_url = '',
    } = req.body;

    const sql = `
      INSERT INTO spaces (owner_id, title, description, location, price_per_day, category, capacity, image_url, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    `;
    const [insertResult] = await db.query(sql, [
      owner_id,
      title,
      description,
      location,
      price_per_day,
      category,
      capacity,
      image_url,
    ]);

    res.status(201).json({ ok: true, space_id: insertResult.insertId });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.patch('/api/spaces/:id', async (req, res) => {
  try {
    const allowed = ['title', 'description', 'price_per_day', 'location', 'capacity', 'image_url', 'status'];
    const updates = [];
    const values = [];

    for (const key of allowed) {
      if (req.body[key] !== undefined) {
        updates.push(`${key} = ?`);
        values.push(req.body[key]);
      }
    }

    if (updates.length > 0) {
      values.push(req.params.id);
      await db.query(`UPDATE spaces SET ${updates.join(', ')} WHERE space_id = ?`, values);
    }

    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.patch('/api/spaces/:id/active', async (req, res) => {
  const { is_active } = req.body || {};
  if (typeof is_active !== 'boolean') {
    return res.status(400).json({ ok: false, message: 'is_active must be a boolean' });
  }
  try {
    const [updateResult] = await db.query('UPDATE spaces SET is_active = ? WHERE space_id = ?', [
      Number(is_active),
      req.params.id,
    ]);
    if (updateResult.affectedRows === 0) {
      return res.status(404).json({ ok: false, message: 'Space not found' });
    }
    res.json({ ok: true, is_active: Number(is_active) });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
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

// ---------------- 4. Bookings & Reviews ----------------
app.get('/api/bookings', async (req, res) => {
  try {
    const { user_id, owner_id } = req.query;
    let sql = `
      SELECT b.*, s.title AS space_title, s.location, s.image_url, u.name AS customer_name
      FROM bookings b
      JOIN spaces s ON b.space_id = s.space_id
      JOIN users u ON b.customer_id = u.user_id
      WHERE 1=1
    `;
    const params = [];

    if (user_id) {
      sql += ' AND b.customer_id = ?';
      params.push(user_id);
    }
    if (owner_id) {
      sql += ' AND s.owner_id = ?';
      params.push(owner_id);
    }

    sql += ' ORDER BY b.booking_id DESC';
    const [bookings] = await db.query(sql, params);
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post('/api/bookings', async (req, res) => {
  try {
    const {
      space_id,
      customer_id = 1002,
      start_date,
      end_date,
      start_time,
      end_time,
      total_price = 0,
    } = req.body;

    const sql = `
      INSERT INTO bookings (space_id, customer_id, start_date, end_date, start_time, end_time, total_price, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
    `;
    const [insertResult] = await db.query(sql, [
      space_id,
      customer_id,
      start_date,
      end_date,
      start_time,
      end_time,
      total_price,
    ]);

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
    const { payment_ref = `PAY-${Date.now()}`, slip_image_url = '' } = req.body;
    const sql = `
      UPDATE bookings
      SET is_paid = 1, payment_ref = ?, slip_image_url = ?, status = 'confirmed'
      WHERE booking_id = ?
    `;
    await db.query(sql, [payment_ref, slip_image_url, req.params.id]);
    res.json({ ok: true, is_paid: 1, payment_ref });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.post('/api/bookings/:id/review', async (req, res) => {
  try {
    const { rating = 5, review_comment = '' } = req.body;
    const sql = 'UPDATE bookings SET rating = ?, review_comment = ? WHERE booking_id = ?';
    await db.query(sql, [rating, review_comment, req.params.id]);
    res.json({ ok: true, rating: Number(rating), review_comment });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

// ---------------- 5. Admin & Uploads ----------------
app.post('/api/upload', async (req, res) => {
  const { filename, base64Data } = req.body || {};
  if (!filename || !base64Data) {
    return res.status(400).json({ ok: false, message: 'filename and base64Data are required' });
  }

  const ext = path.extname(filename).toLowerCase();
  const allowedExts = ['.png', '.jpg', '.jpeg', '.webp'];
  if (!allowedExts.includes(ext)) {
    return res.status(400).json({ ok: false, message: 'Supported images: png, jpg, jpeg, webp' });
  }

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
    res.status(201).json({
      ok: true,
      filename: storedName,
      url: `${req.protocol}://${req.get('host')}/uploads/${storedName}`,
    });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get('/api/uploads', (req, res) => {
  try {
    const files = fs.readdirSync(uploadsDir);
    const images = files
      .filter((file) => /\.(jpg|jpeg|png|webp)$/i.test(file))
      .map((name) => ({
        name,
        url: `http://localhost:${process.env.PORT || 3000}/uploads/${name}`,
      }));
    res.json({ ok: true, files: images });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post('/api/admin/logs', async (req, res) => {
  try {
    const {
      admin_id = 1003,
      admin_name = 'Admin',
      action = 'LOG',
      target_type = 'system',
      target_id = 0,
      details = '',
    } = req.body;

    const sql = `
      INSERT INTO admin_logs (admin_id, admin_name, action, target_type, target_id, details)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    const [insertResult] = await db.query(sql, [
      admin_id,
      admin_name,
      action,
      target_type,
      target_id,
      details,
    ]);

    res.status(201).json({ ok: true, log_id: insertResult.insertId });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

app.get('/api/admin/stats', async (req, res) => {
  try {
    const [[usersRow]] = await db.query('SELECT COUNT(*) AS total_users FROM users');
    const [[spacesRow]] = await db.query(
      'SELECT COUNT(*) AS total_spaces, SUM(CASE WHEN status = "pending" THEN 1 ELSE 0 END) AS pending_spaces FROM spaces'
    );
    const [[bookingsRow]] = await db.query(
      'SELECT COUNT(*) AS total_bookings, COALESCE(SUM(total_price), 0) AS total_revenue FROM bookings'
    );

    res.json({
      ok: true,
      stats: {
        total_users: Number(usersRow.total_users),
        total_spaces: Number(spacesRow.total_spaces),
        pending_spaces: Number(spacesRow.pending_spaces || 0),
        total_bookings: Number(bookingsRow.total_bookings),
        total_revenue: Number(bookingsRow.total_revenue),
      },
    });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.patch('/api/admin/users/:id/status', async (req, res) => {
  try {
    const { status } = req.body || {};
    if (!['active', 'suspended'].includes(status)) {
      return res.status(400).json({ ok: false, message: 'status must be active or suspended' });
    }

    const [updateResult] = await db.query('UPDATE users SET status = ? WHERE user_id = ?', [
      status,
      req.params.id,
    ]);
    if (updateResult.affectedRows === 0) {
      return res.status(404).json({ ok: false, message: 'User not found' });
    }

    res.json({ ok: true, user_id: Number(req.params.id), status });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// ---------------- Starting Server ----------------
const port = Number(process.env.PORT || 3000);
if (require.main === module) {
  app.listen(port, () => {
    console.log(`RentSpace Simple API Server running on port ${port}`);
  });
}

module.exports = app;
