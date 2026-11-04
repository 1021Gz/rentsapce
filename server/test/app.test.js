const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../app');
const con = require('../db_config');
const database = con.promise();

let server;
let base;
const suffix = Date.now().toString(36).slice(-6);
const createdSpaceIds = new Set();
const createdBookingIds = new Set();
const createdUserIds = new Set();
const createdLogIds = new Set();
const createdFiles = new Set();

test.before(async () => {
  await database.query('SELECT 1');
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}/api`;
});

test.after(async () => {
  for (const logId of createdLogIds) {
    await database.query('DELETE FROM admin_logs WHERE log_id = ?', [logId]);
  }
  for (const bId of createdBookingIds) {
    await database.query('DELETE FROM bookings WHERE booking_id = ?', [bId]);
  }
  for (const sId of createdSpaceIds) {
    await database.query('DELETE FROM spaces WHERE space_id = ?', [sId]);
  }
  for (const uId of createdUserIds) {
    await database.query('DELETE FROM users WHERE user_id = ?', [uId]);
  }
  for (const filePath of createdFiles) {
    try {
      fs.unlinkSync(filePath);
    } catch (_) {}
  }
  if (server) {
    server.closeAllConnections();
    await new Promise((resolve) => server.close(resolve));
  }
  await database.end();
});

test('1. Health check returns OK and database connection', async () => {
  const res = await fetch(`${base}/health`);
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.ok, true);
  assert(typeof data.database === 'string');
});

test('2. Hash password utility works', async () => {
  const res = await fetch(`${base}/password/test1234`);
  assert.equal(res.status, 200);
  const hash = await res.text();
  assert(hash.length >= 64);
});

test('3. Register new customer account', async () => {
  const username = `u_${suffix}`;
  const res = await fetch(`${base}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username,
      email: `${username}@test.com`,
      password: 'password123',
      full_name: 'Test Customer',
      role: 'customer',
    }),
  });
  assert.equal(res.status, 201);
  const data = await res.json();
  assert.equal(data.ok, true);
  assert.equal(data.user.username, username);
  createdUserIds.add(data.user.user_id);
});

test('4. Login existing user returns JWT token and profile data', async () => {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'owner01',
      password: 'password',
    }),
  });
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.ok, true);
  assert(typeof data.token === 'string');
  assert.equal(data.user.username, 'owner01');
});

test('5. Sync returns users, spaces, bookings, and admin logs', async () => {
  const res = await fetch(`${base}/sync`);
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.ok, true);
  assert(Array.isArray(data.users));
  assert(Array.isArray(data.spaces));
  assert(Array.isArray(data.bookings));
  assert(Array.isArray(data.admin_logs));
});

test('6. Create, update, toggle active, and search spaces', async () => {
  const title = `Space-${suffix}`;
  const createRes = await fetch(`${base}/spaces`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      owner_id: 1001,
      title,
      description: 'Test space description',
      location: 'Ari, Bangkok',
      price_per_day: 500,
      category: 'meeting_room',
      capacity: 8,
      image_url: 'http://localhost:3000/uploads/meeting.jpg',
    }),
  });
  assert.equal(createRes.status, 201);
  const createData = await createRes.json();
  const spaceId = createData.space_id;
  createdSpaceIds.add(spaceId);

  // Update space
  const updateRes = await fetch(`${base}/spaces/${spaceId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ price_per_day: 600, status: 'approved' }),
  });
  assert.equal(updateRes.status, 200);

  // Toggle active
  const toggleRes = await fetch(`${base}/spaces/${spaceId}/active`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ is_active: true }),
  });
  assert.equal(toggleRes.status, 200);

  // Search
  const searchRes = await fetch(`${base}/spaces?keyword=${suffix}`);
  assert.equal(searchRes.status, 200);
  const searchList = await searchRes.json();
  assert(searchList.some((s) => s.space_id === spaceId));
});

test('7. Create booking, confirm, pay with slip, and submit review', async () => {
  const [spaces] = await database.query('SELECT space_id FROM spaces LIMIT 1');
  const spaceId = spaces[0].space_id;

  const bookRes = await fetch(`${base}/bookings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      space_id: spaceId,
      customer_id: 1002,
      start_date: '2026-12-25',
      end_date: '2026-12-25',
      start_time: '2026-12-25 10:00:00',
      end_time: '2026-12-25 12:00:00',
      total_price: 700,
    }),
  });
  assert.equal(bookRes.status, 201);
  const bookData = await bookRes.json();
  const bookingId = bookData.booking_id;
  createdBookingIds.add(bookingId);

  // Confirm booking
  const confirmRes = await fetch(`${base}/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: 'confirmed' }),
  });
  assert.equal(confirmRes.status, 200);

  // Pay with slip
  const payRes = await fetch(`${base}/bookings/${bookingId}/pay`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      payment_ref: `SLIP-${suffix}`,
      slip_image_url: 'http://localhost:3000/uploads/meeting.jpg',
    }),
  });
  assert.equal(payRes.status, 200);
  const payData = await payRes.json();
  assert.equal(payData.is_paid, 1);

  // Submit review
  const reviewRes = await fetch(`${base}/bookings/${bookingId}/review`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      rating: 5,
      review_comment: 'Excellent space from test suite',
    }),
  });
  assert.equal(reviewRes.status, 200);

  // List bookings by user_id
  const listRes = await fetch(`${base}/bookings?user_id=1002`);
  assert.equal(listRes.status, 200);
  const bookingsList = await listRes.json();
  assert(bookingsList.some((b) => b.booking_id === bookingId));
});

test('8. Space detail, admin approval, admin logs, and image upload', async () => {
  const [spaces] = await database.query('SELECT space_id FROM spaces LIMIT 1');
  const spaceId = spaces[0].space_id;

  // Get space detail by ID
  const detailRes = await fetch(`${base}/spaces/${spaceId}`);
  assert.equal(detailRes.status, 200);
  const detailData = await detailRes.json();
  assert.equal(detailData.space_id, spaceId);

  // Admin approve space
  const approveRes = await fetch(`${base}/admin/spaces/${spaceId}/approval`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: 'approved' }),
  });
  assert.equal(approveRes.status, 200);

  // Record admin log
  const logRes = await fetch(`${base}/admin/logs`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      admin_id: 1003,
      admin_name: 'Admin Test',
      action: 'APPROVE_SPACE',
      target_type: 'space',
      target_id: spaceId,
      details: 'Approved in test suite',
    }),
  });
  assert.equal(logRes.status, 201);
  const logData = await logRes.json();
  createdLogIds.add(logData.log_id);

  // Upload image (1x1 PNG base64)
  const uploadRes = await fetch(`${base}/upload`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      filename: 'test.png',
      base64Data:
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    }),
  });
  assert.equal(uploadRes.status, 201);
  const uploadData = await uploadRes.json();
  createdFiles.add(path.join(__dirname, '..', 'uploads', uploadData.filename));

  // List uploaded images
  const uploadsListRes = await fetch(`${base}/uploads`);
  assert.equal(uploadsListRes.status, 200);
  const uploadsListData = await uploadsListRes.json();
  assert.equal(uploadsListData.ok, true);
  assert(Array.isArray(uploadsListData.files));
});
