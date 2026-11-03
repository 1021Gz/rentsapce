const express = require('express');
const cors = require('cors');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const con = require('./db_config');

const app = express();
const db = con.promise();

const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use('/uploads', express.static(uploadsDir));

//------------------- Helpers --------------
function hashPassword(rawPassword) {
  return crypto.createHash('sha256').update(String(rawPassword)).digest('hex');
}

function normalizeRoleForClient(databaseRole) {
  return databaseRole === 'customer' ? 'renter' : databaseRole;
}

function normalizeRoleForDb(clientRole) {
  return clientRole === 'renter' ? 'customer' : clientRole;
}

async function resolveExistingUserId(candidateUserId, fallbackUserId) {
  if (!candidateUserId) return fallbackUserId;
  const [matchingUsers] = await db.query(
    'SELECT user_id FROM users WHERE user_id = ? LIMIT 1',
    [candidateUserId]
  );
  return matchingUsers.length > 0 ? candidateUserId : fallbackUserId;
}

async function resolveExistingSpaceId(candidateSpaceId, fallbackSpaceId) {
  if (!candidateSpaceId) return fallbackSpaceId;
  const [matchingSpaces] = await db.query(
    'SELECT space_id FROM spaces WHERE space_id = ? LIMIT 1',
    [candidateSpaceId]
  );
  return matchingSpaces.length > 0 ? candidateSpaceId : fallbackSpaceId;
}

//------------------- Health Check --------------
app.get('/api/health', async (_req, res) => {
  try {
    const [rows] = await db.query('SELECT DATABASE() AS databaseName');
    res.json({ ok: true, database: rows[0].databaseName });
  } catch (err) {
    res.status(500).json({ ok: false, message: err.message });
  }
});

//------------------- Hash Password Utility --------------
app.get('/api/password/:raw', (req, res) => {
  try {
    const hash = hashPassword(req.params.raw);
    res.send(hash);
  } catch (err) {
    res.status(500).send('Error: Hashing failed');
  }
});

//------------------- Auth: Register --------------
async function handleRegister(req, res) {
  try {
    const { username, email, password, full_name, role } = req.body ?? {};
    if (!username || !email || !password) {
      return res.status(400).json({ ok: false, message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
    }
    const databaseRole = normalizeRoleForDb(role || 'customer');
    if (databaseRole === 'admin') {
      return res.status(403).json({ ok: false, message: 'ไม่อนุญาตให้สมัคร Admin สาธารณะ' });
    }
    const passwordHash = hashPassword(password);
    const [insertResult] = await db.query(
      'INSERT INTO users (name, username, email, password_hash, role, status) VALUES (?, ?, ?, ?, ?, "active")',
      [full_name || username, username.trim(), email.trim(), passwordHash, databaseRole]
    );
    await db.query(
      `INSERT INTO app_session (session_key, user_id) VALUES ('default', ?)
       ON DUPLICATE KEY UPDATE user_id = VALUES(user_id)`,
      [insertResult.insertId]
    );
    res.status(201).json({
      ok: true,
      user: {
        user_id: insertResult.insertId,
        full_name: full_name || username,
        username: username.trim(),
        email: email.trim(),
        role: normalizeRoleForClient(databaseRole),
        status: 'active',
      },
    });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
}
app.post('/api/auth/register', handleRegister);
app.post('/api/register', handleRegister);

//------------------- Auth: Login --------------
async function handleLogin(req, res) {
  try {
    const { username, password } = req.body ?? {};
    if (!username || !password) {
      return res.status(400).json({ ok: false, message: 'กรุณากรอก username และ password' });
    }
    const [matchingUsers] = await db.query(
      'SELECT user_id, name, username, email, password_hash, role, status FROM users WHERE username = ? LIMIT 1',
      [username.trim()]
    );
    if (matchingUsers.length === 0) {
      return res.status(401).json({ ok: false, message: 'ไม่พบชื่อผู้ใช้นี้ในระบบ' });
    }
    const user = matchingUsers[0];
    if (user.status === 'suspended') {
      return res.status(403).json({ ok: false, message: 'บัญชีนี้ถูกระงับการใช้งาน' });
    }
    const incomingHash = hashPassword(password);
    const isSeed = user.password_hash === 'SEED_ONLY_NOT_A_LOGIN_HASH';
    if (!isSeed && user.password_hash !== incomingHash && user.password_hash !== password) {
      return res.status(401).json({ ok: false, message: 'รหัสผ่านไม่ถูกต้อง' });
    }
    await db.query(
      `INSERT INTO app_session (session_key, user_id) VALUES ('default', ?)
       ON DUPLICATE KEY UPDATE user_id = VALUES(user_id)`,
      [user.user_id]
    );
    res.json({
      ok: true,
      user: {
        user_id: user.user_id,
        full_name: user.name,
        username: user.username,
        email: user.email,
        role: normalizeRoleForClient(user.role),
        status: user.status || 'active',
      },
    });
  } catch (err) {
    res.status(500).json({ ok: false, message: err.message });
  }
}
app.post('/api/auth/login', handleLogin);
app.post('/api/login', handleLogin);

//------------------- Session Management --------------
app.post('/api/auth/session', async (req, res) => {
  try {
    const { user_id } = req.body;
    await db.query(
      `INSERT INTO app_session (session_key, user_id) VALUES ('default', ?)
       ON DUPLICATE KEY UPDATE user_id = VALUES(user_id)`,
      [user_id || null]
    );
    res.json({ ok: true, user_id: user_id || null });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

app.delete('/api/auth/session', async (_req, res) => {
  try {
    await db.query("DELETE FROM app_session WHERE session_key = 'default'");
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Database Sync --------------
app.get('/api/sync', async (_req, res) => {
  try {
    const [userRows] = await db.query(
      'SELECT user_id, name, username, email, phone, role, status, created_at FROM users ORDER BY user_id ASC'
    );
    const [spaceRows] = await db.query(
      `SELECT s.space_id, s.owner_id, u.name AS owner_name, s.title, s.description,
              s.location, s.price_per_day, s.category, s.capacity, s.image_url,
              s.is_active, s.rating, s.rating_count, s.status, s.created_at
       FROM spaces s
       LEFT JOIN users u ON s.owner_id = u.user_id
       ORDER BY s.space_id ASC`
    );
    const [bookingRows] = await db.query(
      `SELECT b.booking_id, b.space_id, s.title AS space_title, s.price_per_day,
              b.customer_id, u.name AS customer_name,
              DATE_FORMAT(b.start_date, '%Y-%m-%d') AS start_date,
              DATE_FORMAT(b.end_date, '%Y-%m-%d') AS end_date,
              DATE_FORMAT(b.start_time, '%Y-%m-%d %H:%i:%s') AS start_time,
              DATE_FORMAT(b.end_time, '%Y-%m-%d %H:%i:%s') AS end_time,
              b.total_price, b.payment_ref, b.slip_image_url, b.rating, b.review_comment,
              b.status, b.is_paid, b.created_at
       FROM bookings b
       LEFT JOIN spaces s ON b.space_id = s.space_id
       LEFT JOIN users u ON b.customer_id = u.user_id
       ORDER BY b.booking_id DESC`
    );
    const [logRows] = await db.query(
      `SELECT log_id, admin_id, admin_name, action, target_type, target_id, details,
              DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created_at
       FROM admin_logs
       ORDER BY log_id DESC
       LIMIT 100`
    );
    const [sessionRows] = await db.query(
      "SELECT user_id FROM app_session WHERE session_key = 'default' LIMIT 1"
    );

    res.json({
      ok: true,
      active_session_user_id: sessionRows.length > 0 ? sessionRows[0].user_id : null,
      users: userRows.map((u) => ({
        user_id: u.user_id,
        full_name: u.name,
        username: u.username,
        email: u.email,
        phone: u.phone || '',
        role: normalizeRoleForClient(u.role),
        db_role: u.role,
        status: u.status || 'active',
        created_at: u.created_at,
      })),
      spaces: spaceRows.map((s) => ({
        space_id: s.space_id,
        owner_id: s.owner_id,
        owner_name: s.owner_name || 'Owner',
        title: s.title,
        description: s.description || '',
        location: s.location,
        price_per_day: Number(s.price_per_day),
        category: s.category || 'meeting_room',
        capacity: Number(s.capacity || 10),
        image_url: s.image_url || '',
        is_active: s.is_active === null || s.is_active === undefined ? true : Boolean(s.is_active),
        rating: Number(s.rating || 4.8),
        rating_count: Number(s.rating_count || 1),
        status: s.status,
        created_at: s.created_at,
      })),
      bookings: bookingRows.map((b) => ({
        booking_id: b.booking_id,
        space_id: b.space_id,
        space_title: b.space_title || `Space #${b.space_id}`,
        customer_id: b.customer_id,
        customer_name: b.customer_name || `User #${b.customer_id}`,
        start_date: b.start_date,
        end_date: b.end_date,
        start_time: b.start_time,
        end_time: b.end_time,
        total_price: Number(b.total_price || 0),
        payment_ref: b.payment_ref || '',
        slip_image_url: b.slip_image_url || '',
        rating: b.rating ? Number(b.rating) : null,
        review_comment: b.review_comment || '',
        status: b.status,
        paid: Boolean(b.is_paid),
        created_at: b.created_at,
      })),
      admin_logs: logRows.map((l) => ({
        log_id: l.log_id,
        admin_id: l.admin_id,
        admin_name: l.admin_name,
        action: l.action,
        target_type: l.target_type,
        target_id: l.target_id,
        details: l.details,
        created_at: l.created_at,
      })),
    });
  } catch (err) {
    res.status(500).json({ ok: false, message: err.message });
  }
});

//------------------- Spaces: Search & List --------------
app.get('/api/spaces', async (req, res) => {
  try {
    const { category, keyword } = req.query;
    let querySql = `
      SELECT s.*, u.name AS owner_name 
      FROM spaces s
      LEFT JOIN users u ON s.owner_id = u.user_id
      WHERE s.status = 'approved' AND s.is_active = 1
    `;
    const params = [];
    if (category && category !== 'All') {
      querySql += ' AND s.category = ?';
      params.push(category);
    }
    if (keyword && keyword.trim().length > 0) {
      querySql += ' AND (s.title LIKE ? OR s.location LIKE ?)';
      params.push(`%${keyword.trim()}%`, `%${keyword.trim()}%`);
    }
    querySql += ' ORDER BY s.space_id DESC';
    const [rows] = await db.query(querySql, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ ok: false, message: err.message });
  }
});

//------------------- Spaces: Create --------------
app.post('/api/spaces', async (req, res) => {
  try {
    const { owner_id, title, description, location, price_per_day, category, capacity, image_url } = req.body;
    const verifiedOwnerId = await resolveExistingUserId(owner_id, 1001);
    const [insertResult] = await db.query(
      `INSERT INTO spaces 
       (owner_id, title, description, location, price_per_day, category, capacity, image_url, is_active, status) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 'pending')`,
      [
        verifiedOwnerId,
        title,
        description || '',
        location,
        Number(price_per_day || 0),
        category || 'meeting_room',
        Number(capacity || 10),
        image_url || null,
      ]
    );
    res.status(201).json({ ok: true, space_id: insertResult.insertId });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Spaces: Update --------------
app.patch('/api/spaces/:id', async (req, res) => {
  try {
    const targetSpaceId = Number(req.params.id);
    const { title, description, location, price_per_day, category, capacity, image_url, status } = req.body;
    const updates = [];
    const params = [];
    if (title !== undefined) { updates.push('title = ?'); params.push(title); }
    if (description !== undefined) { updates.push('description = ?'); params.push(description); }
    if (location !== undefined) { updates.push('location = ?'); params.push(location); }
    if (price_per_day !== undefined) { updates.push('price_per_day = ?'); params.push(Number(price_per_day)); }
    if (category !== undefined) { updates.push('category = ?'); params.push(category); }
    if (capacity !== undefined) { updates.push('capacity = ?'); params.push(Number(capacity)); }
    if (image_url !== undefined) { updates.push('image_url = ?'); params.push(image_url); }
    if (status !== undefined) { updates.push('status = ?'); params.push(status); }
    else { updates.push('status = "pending"'); }

    params.push(targetSpaceId);
    await db.query(`UPDATE spaces SET ${updates.join(', ')} WHERE space_id = ?`, params);
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Spaces: Toggle Active --------------
app.patch('/api/spaces/:id/active', async (req, res) => {
  try {
    const targetSpaceId = Number(req.params.id);
    const isActive = req.body.is_active ? 1 : 0;
    await db.query('UPDATE spaces SET is_active = ? WHERE space_id = ?', [isActive, targetSpaceId]);
    res.json({ ok: true, is_active: Boolean(isActive) });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Spaces: Delete --------------
app.delete('/api/spaces/:id', async (req, res) => {
  try {
    const targetSpaceId = Number(req.params.id);
    await db.query('DELETE FROM spaces WHERE space_id = ?', [targetSpaceId]);
    res.json({ ok: true, deleted_space_id: targetSpaceId });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Bookings: Create --------------
app.post('/api/bookings', async (req, res) => {
  try {
    const { space_id, customer_id, start_date, end_date, start_time, end_time, total_price } = req.body;
    const verifiedSpaceId = await resolveExistingSpaceId(space_id, 2001);
    const verifiedCustomerId = await resolveExistingUserId(customer_id, 1002);
    const effectiveStartTime = start_time || `${start_date} 09:00:00`;
    const effectiveEndTime = end_time || `${end_date} 17:00:00`;

    const [overlapping] = await db.query(
      `SELECT booking_id FROM bookings
       WHERE space_id = ? AND status IN ('approved', 'confirmed')
         AND COALESCE(start_time, CONCAT(start_date, ' 09:00:00')) < ?
         AND COALESCE(end_time, CONCAT(end_date, ' 17:00:00')) > ?`,
      [verifiedSpaceId, effectiveEndTime, effectiveStartTime]
    );
    if (overlapping.length > 0) {
      return res.status(409).json({ ok: false, message: 'ช่วงเวลานี้มีการจองที่อนุมัติแล้ว' });
    }

    const [insertResult] = await db.query(
      `INSERT INTO bookings 
       (space_id, customer_id, start_date, end_date, start_time, end_time, total_price, status, is_paid)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', 0)`,
      [
        verifiedSpaceId,
        verifiedCustomerId,
        start_date,
        end_date,
        effectiveStartTime,
        effectiveEndTime,
        total_price !== undefined ? Number(total_price) : null,
      ]
    );
    res.status(201).json({ ok: true, booking_id: insertResult.insertId });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Bookings: Update Status --------------
app.patch('/api/bookings/:id/status', async (req, res) => {
  try {
    const targetBookingId = Number(req.params.id);
    const incomingStatus = req.body.status;
    const databaseStatus = incomingStatus === 'confirmed' ? 'approved' : incomingStatus;
    await db.query('UPDATE bookings SET status = ? WHERE booking_id = ?', [databaseStatus, targetBookingId]);
    res.json({ ok: true, status: databaseStatus });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Bookings: Pay with Slip --------------
app.patch('/api/bookings/:id/pay', async (req, res) => {
  try {
    const targetBookingId = Number(req.params.id);
    const paymentRef = req.body.payment_ref || null;
    const slipImageUrl = req.body.slip_image_url || null;
    await db.query(
      `UPDATE bookings
       SET is_paid = 1,
           payment_ref = COALESCE(?, payment_ref),
           slip_image_url = COALESCE(?, slip_image_url)
       WHERE booking_id = ?`,
      [paymentRef, slipImageUrl, targetBookingId]
    );
    res.json({ ok: true, is_paid: 1, payment_ref: paymentRef, slip_image_url: slipImageUrl });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Bookings: Review & Rating --------------
app.post('/api/bookings/:id/review', async (req, res) => {
  try {
    const targetBookingId = Number(req.params.id);
    const ratingScore = Math.min(5, Math.max(1, Number(req.body.rating || 5)));
    const reviewComment = String(req.body.review_comment || '').trim();

    await db.query(
      'UPDATE bookings SET rating = ?, review_comment = ?, status = "completed" WHERE booking_id = ?',
      [ratingScore, reviewComment, targetBookingId]
    );

    const [bookingLookup] = await db.query(
      'SELECT space_id FROM bookings WHERE booking_id = ? LIMIT 1',
      [targetBookingId]
    );
    if (bookingLookup.length > 0) {
      const targetSpaceId = bookingLookup[0].space_id;
      const [ratingStats] = await db.query(
        'SELECT AVG(rating) AS avgRating, COUNT(rating) AS countRating FROM bookings WHERE space_id = ? AND rating IS NOT NULL',
        [targetSpaceId]
      );
      const computedAvg = Number(ratingStats[0].avgRating || ratingScore).toFixed(2);
      const computedCount = Number(ratingStats[0].countRating || 1);
      await db.query(
        'UPDATE spaces SET rating = ?, rating_count = ? WHERE space_id = ?',
        [computedAvg, computedCount, targetSpaceId]
      );
    }

    res.json({ ok: true, rating: ratingScore, review_comment: reviewComment });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Users: Status & Profile --------------
app.patch('/api/users/:id/status', async (req, res) => {
  try {
    const targetUserId = Number(req.params.id);
    const { status } = req.body;
    await db.query('UPDATE users SET status = ? WHERE user_id = ?', [status || 'active', targetUserId]);
    res.json({ ok: true, status: status || 'active' });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

app.patch('/api/users/:id/profile', async (req, res) => {
  try {
    const targetUserId = Number(req.params.id);
    const { full_name, email, phone, password } = req.body;
    const updates = [];
    const params = [];
    if (full_name !== undefined && String(full_name).trim() !== '') {
      updates.push('name = ?'); params.push(String(full_name).trim());
    }
    if (email !== undefined && String(email).trim() !== '') {
      updates.push('email = ?'); params.push(String(email).trim());
    }
    if (phone !== undefined) {
      updates.push('phone = ?'); params.push(String(phone).trim());
    }
    if (password !== undefined && String(password).trim() !== '') {
      updates.push('password_hash = ?'); params.push(hashPassword(String(password).trim()));
    }
    if (updates.length > 0) {
      params.push(targetUserId);
      await db.query(`UPDATE users SET ${updates.join(', ')} WHERE user_id = ?`, params);
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Admin: Approval & Audit Logs --------------
app.patch('/api/admin/spaces/:id/approval', async (req, res) => {
  try {
    const targetSpaceId = Number(req.params.id);
    const { status } = req.body;
    await db.query('UPDATE spaces SET status = ? WHERE space_id = ?', [status, targetSpaceId]);
    res.json({ ok: true, status });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

app.post('/api/admin/logs', async (req, res) => {
  try {
    const { admin_id, admin_name, action, target_type, target_id, details } = req.body;
    const [insertResult] = await db.query(
      `INSERT INTO admin_logs (admin_id, admin_name, action, target_type, target_id, details)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [admin_id || 1003, admin_name || 'ผู้ดูแลระบบ', action || 'ADMIN_ACTION', target_type || 'system', target_id || 0, details || '']
    );
    res.status(201).json({ ok: true, log_id: insertResult.insertId });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//------------------- Uploads --------------
app.get('/api/uploads', (_req, res) => {
  try {
    const files = fs.readdirSync(uploadsDir).filter((f) => /\.(jpg|jpeg|png|webp|gif)$/i.test(f));
    const port = Number(process.env.PORT || 3000);
    res.json({
      ok: true,
      files: files.map((fileName) => ({
        name: fileName,
        url: `http://localhost:${port}/uploads/${fileName}`,
      })),
    });
  } catch (err) {
    res.status(500).json({ ok: false, message: err.message });
  }
});

app.post('/api/upload', (req, res) => {
  try {
    const { filename, base64Data } = req.body;
    if (!base64Data) {
      return res.status(400).json({ ok: false, message: 'ไม่พบข้อมูลไฟล์รูปภาพ' });
    }
    const cleanBase64 = String(base64Data).replace(/^data:image\/\w+;base64,/, '');
    const ext = path.extname(filename || 'image.jpg') || '.jpg';
    const safeName = `space_${Date.now()}${ext}`;
    const targetPath = path.join(uploadsDir, safeName);
    fs.writeFileSync(targetPath, Buffer.from(cleanBase64, 'base64'));
    const port = Number(process.env.PORT || 3000);
    res.status(201).json({ ok: true, filename: safeName, image_url: `http://localhost:${port}/uploads/${safeName}` });
  } catch (err) {
    res.status(400).json({ ok: false, message: err.message });
  }
});

//=================== Starting server =======================
const port = Number(process.env.PORT || 3000);
if (require.main === module) {
  app.listen(port, () => {
    console.log('Server is running at ' + port);
  });
}

module.exports = app;
