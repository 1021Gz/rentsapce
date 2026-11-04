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

test.before(async () => {
  await database.query('SELECT 1');
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}/api`;
});

test.after(async () => {
  for (const bId of createdBookingIds) {
    await database.query('DELETE FROM bookings WHERE booking_id = ?', [bId]);
  }
  for (const sId of createdSpaceIds) {
    await database.query('DELETE FROM spaces WHERE space_id = ?', [sId]);
  }
  for (const uId of createdUserIds) {
    await database.query('DELETE FROM users WHERE user_id = ?', [uId]);
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
});
