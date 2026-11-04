# RentSpace Database Server

Express + MySQL REST API for the RentSpace Flutter Application.

## Setup (XAMPP)

1. Start **MySQL** in XAMPP Control Panel.
2. Open a terminal:

```powershell
cd server
npm install
npm run db:init
npm run dev
```

Database defaults: `127.0.0.1:3306`, user `root`, empty password, database `rent_space`.
Change the connection settings in `db_config.js` if your XAMPP password or database differs.
`schema.sql` creates the complete schema (`users`, `spaces`, `bookings`, `admin_logs`) and adds sample seed data.

## Endpoints

- `POST /api/auth/register` (or `/api/register`): register a new customer/owner account
- `POST /api/auth/login` (or `/api/login`): body `{ "username", "password" }`, returns `{ ok, token, user }`
- `GET /api/sync`: full snapshot of users, spaces, bookings, and admin logs
- `GET /api/spaces`: spaces list (supports `?keyword=...`, `?category=...`, `?status=...`)
- `GET /api/spaces/:id`: get single space details
- `POST /api/spaces`: create new space listing
- `PATCH /api/spaces/:id`: update space listing details
- `PATCH /api/spaces/:id/active`: toggle active status (`{ "is_active": true/false }`)
- `PATCH /api/admin/spaces/:id/approval`: admin approve/reject space
- `GET /api/bookings`: list bookings (supports `?user_id=...` & `?owner_id=...`)
- `POST /api/bookings`: create booking
- `PATCH /api/bookings/:id/status`: approve/confirm/reject/cancel booking
- `PATCH /api/bookings/:id/pay`: record payment reference & slip image URL
- `POST /api/bookings/:id/review`: submit 1-5 star rating & review comment
- `POST /api/admin/logs`: record admin action audit logs
- `GET /api/uploads`: list uploaded images from `server/uploads/`
- `POST /api/upload`: upload image file as base64
- `GET /api/password/:raw`: hash password with Argon2id
- `GET /api/health`: database connectivity health check

## Run and test

```powershell
npm start
npm test
```

`npm run dev` enables automatic restart when files change (`node --watch app.js`).
`npm run db:init` resets and repopulates the `rent_space` database using `schema.sql`.
`npm test` runs the automated API test suite (`test/app.test.js`) using Node's native test runner.

## Supporting files

- `app.js`: Main Express API application and routes
- `db_config.js`: MySQL connection pool configuration
- `init_db.js`: Database initialization script
- `schema.sql`: Complete DDL schema and initial seed data
- `test/app.test.js`: Automated API test suite
