# RentSpace Database Server

Express + MySQL REST API for the RentSpace Flutter Application.

## Setup (XAMPP)

1. Start **Apache** and **MySQL** in XAMPP Control Panel.
2. Open a terminal:

```powershell
cd server
npm install
npm run db:init
npm run dev
```

Database defaults: `127.0.0.1:3306`, user `root`, empty password, database `rent_space`.
Change the connection settings in `db_config.js` if your XAMPP password or port differs.
`schema.sql` creates the complete schema (`users`, `spaces`, `bookings`, `admin_logs`, `app_session`) and adds sample seed data.

## Endpoints

- `POST /api/auth/register` (or `/api/register`): body `{ "username", "email", "password", "full_name", "role": "customer" }`
- `POST /api/auth/login` (or `/api/login`): body `{ "username", "password" }`, returns `{ ok, user }`
- `GET /api/sync`: full snapshot of users, spaces, bookings, and admin logs
- `GET /api/spaces`: approved and active spaces list (supports `?keyword=...` & `?category=...`)
- `POST /api/spaces`: create new space listing
- `PATCH /api/spaces/:id`: update space listing details
- `PATCH /api/spaces/:id/active`: toggle active status (`{ "is_active": true/false }`)
- `DELETE /api/spaces/:id`: delete space listing
- `POST /api/bookings`: create hourly booking with overlap conflict protection
- `PATCH /api/bookings/:id/status`: approve/confirm/reject/cancel booking
- `PATCH /api/bookings/:id/pay`: record payment reference & slip image URL
- `POST /api/bookings/:id/review`: submit 1-5 star rating & review comment
- `PATCH /api/users/:id/profile`: update user profile and password
- `PATCH /api/admin/spaces/:id/approval`: admin approve/reject space
- `POST /api/admin/logs`: record admin action audit logs
- `GET /api/uploads`: list uploaded images from `server/uploads/`
- `POST /api/upload`: upload image file as base64
- `GET /api/password/:raw`: hash password with SHA-256
- `GET /api/health`: database connectivity health check

## Run and test

```powershell
npm start
npm test
```

`npm run dev` enables automatic restart when files change (`node --watch app.js`).
`npm run db:init` resets and repopulates the `rent_space` database using `schema.sql`.
`npm test` runs the automated API test suite (`test-api.js`).

## Supporting files

- `app.js`: Main Express API application and routes
- `db_config.js`: MySQL connection configuration
- `init_db.js`: Database initialization script
- `schema.sql`: Complete DDL schema and initial seed data
- `test-api.js`: Automated API test suite
- `RentSpace_LiteClient_Collection.json`: LiteClient API test collection
- `RentSpace_Sprint2_Postman_Collection.json`: Postman API test collection
