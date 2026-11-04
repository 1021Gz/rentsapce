const http = require("node:http");

const BASE_URL = process.env.API_BASE_URL || "http://localhost:3000";

function sendJsonRequest(method, path, bodyData = null) {
  return new Promise((resolve, reject) => {
    const targetUrl = new URL(path, BASE_URL);
    const payloadString = bodyData ? JSON.stringify(bodyData) : null;
    const options = {
      hostname: targetUrl.hostname,
      port: targetUrl.port,
      path: targetUrl.pathname + targetUrl.search,
      method,
      headers: {
        "Content-Type": "application/json",
      },
    };
    if (payloadString) {
      options.headers["Content-Length"] = Buffer.byteLength(payloadString);
    }

    const req = http.request(options, (res) => {
      let rawResponse = "";
      res.on("data", (chunk) => {
        rawResponse += chunk;
      });
      res.on("end", () => {
        try {
          const parsed = rawResponse ? JSON.parse(rawResponse) : {};
          resolve({ statusCode: res.statusCode, body: parsed });
        } catch (parseErr) {
          reject(parseErr);
        }
      });
    });

    req.on("error", reject);
    if (payloadString) {
      req.write(payloadString);
    }
    req.end();
  });
}

async function runApiTestSuite() {
  console.log("==================================================");
  console.log("RentSpace Sprint 2 — Backend API Automated Tests");
  console.log("==================================================");

  let passedCount = 0;
  function assertCheck(testName, condition, details = "") {
    if (!condition) {
      throw new Error(`FAILED: ${testName} ${details}`);
    }
    passedCount += 1;
    console.log(`[PASS] ${passedCount}. ${testName}`);
  }

  // 1. Health Check
  const healthRes = await sendJsonRequest("GET", "/api/health");
  assertCheck(
    "GET /api/health returns database connection status",
    healthRes.statusCode === 200 && healthRes.body.ok === true
  );

  // 2. Sync Initial Snapshot
  const syncRes = await sendJsonRequest("GET", "/api/sync");
  assertCheck(
    "GET /api/sync returns users, spaces, bookings, admin_logs",
    syncRes.statusCode === 200 &&
      Array.isArray(syncRes.body.users) &&
      Array.isArray(syncRes.body.spaces) &&
      Array.isArray(syncRes.body.bookings)
  );

  // 3. Uploads Listing
  const uploadsRes = await sendJsonRequest("GET", "/api/uploads");
  assertCheck(
    "GET /api/uploads returns static image list from server/uploads",
    uploadsRes.statusCode === 200 && Array.isArray(uploadsRes.body.files)
  );

  // 4. Create Space (Owner)
  const createSpaceRes = await sendJsonRequest("POST", "/api/spaces", {
    owner_id: 1001,
    title: "Sprint2 API Test Space",
    description: "Automated API test room",
    location: "Bangkok",
    price_per_day: 650,
    category: "meeting_room",
    capacity: 12,
    image_url: "http://localhost:3000/uploads/meeting.jpg",
  });
  const testSpaceId = createSpaceRes.body.space_id;
  assertCheck(
    "POST /api/spaces creates a new space in MySQL",
    createSpaceRes.statusCode === 201 && Boolean(testSpaceId)
  );

  // 5. Update Space (Owner)
  const updateSpaceRes = await sendJsonRequest(
    "PATCH",
    `/api/spaces/${testSpaceId}`,
    {
      title: "Sprint2 API Test Space (Updated)",
      price_per_day: 750,
    }
  );
  assertCheck(
    "PATCH /api/spaces/:id updates space details",
    updateSpaceRes.statusCode === 200 && updateSpaceRes.body.ok === true
  );

  // 6. Approve Space (Admin)
  const approveSpaceRes = await sendJsonRequest(
    "PATCH",
    `/api/admin/spaces/${testSpaceId}/approval`,
    { status: "approved" }
  );
  assertCheck(
    "PATCH /api/admin/spaces/:id/approval approves space",
    approveSpaceRes.statusCode === 200 &&
      approveSpaceRes.body.status === "approved"
  );

  // 7. Create Booking (Renter)
  const createBookingRes = await sendJsonRequest("POST", "/api/bookings", {
    space_id: testSpaceId,
    customer_id: 1002,
    start_date: "2026-12-10",
    end_date: "2026-12-10",
    start_time: "2026-12-10 10:00:00",
    end_time: "2026-12-10 12:00:00",
    total_price: 1500,
  });
  const testBookingId = createBookingRes.body.booking_id;
  assertCheck(
    "POST /api/bookings creates an hourly booking in MySQL",
    createBookingRes.statusCode === 201 && Boolean(testBookingId)
  );

  // 8. Confirm Booking (Owner)
  const confirmBookingRes = await sendJsonRequest(
    "PATCH",
    `/api/bookings/${testBookingId}/status`,
    { status: "confirmed" }
  );
  assertCheck(
    "PATCH /api/bookings/:id/status confirms booking",
    confirmBookingRes.statusCode === 200 && confirmBookingRes.body.ok === true
  );

  // 9. Pay Booking with Slip (Renter)
  const payBookingRes = await sendJsonRequest(
    "PATCH",
    `/api/bookings/${testBookingId}/pay`,
    {
      payment_ref: "SLIP-API-TEST-999",
      slip_image_url: "http://localhost:3000/uploads/meeting.jpg",
    }
  );
  assertCheck(
    "PATCH /api/bookings/:id/pay records payment_ref and slip_image_url",
    payBookingRes.statusCode === 200 && payBookingRes.body.is_paid === 1
  );

  // 10. Submit Review (Renter)
  const reviewRes = await sendJsonRequest(
    "POST",
    `/api/bookings/${testBookingId}/review`,
    {
      rating: 5,
      review_comment: "Great space tested via automated API suite",
    }
  );
  assertCheck(
    "POST /api/bookings/:id/review saves rating and recalculates space score",
    reviewRes.statusCode === 200 && reviewRes.body.rating === 5
  );

  // Cleanup temporary test rows
  const pool = require("./db_config");
  const db = pool.promise();
  await db.query("DELETE FROM bookings WHERE booking_id = ?", [testBookingId]);
  await db.query("DELETE FROM spaces WHERE space_id = ?", [testSpaceId]);
  await pool.end();

  console.log("==================================================");
  console.log(`ALL ${passedCount} API TESTS PASSED SUCCESSFULLY!`);
  console.log("==================================================");
}

runApiTestSuite().catch((err) => {
  console.error("API Test Error:", err.message);
  process.exitCode = 1;
});
