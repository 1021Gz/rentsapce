# RentSpace (Sprint 2)

> **Sprint 2 Scope**: Complete DB, Complete Backend, API Test, 50% Frontend (No front-back connection)

An hourly space rental application built with **Flutter** (Frontend) and **Node.js / Express + MySQL** (Backend).

---

## 📁 Project Structure

```text
rentspace/
├── rentspace/               # Flutter Frontend (50% UI Standalone)
│   ├── lib/                 # UI Screens (Standalone) & Mock Data
│   └── pubspec.yaml         # Flutter dependencies (name: rentspace)
│
└── server/                  # Express.js REST API + MySQL Database
    ├── app.js               # Express server (argon2id & JWT)
    ├── db_config.js         # MySQL2 connection setup
    ├── init_db.js           # Database auto-initialization script
    ├── schema.sql           # Complete DDL schema & sample seeds
    ├── test/app.test.js     # Automated API test suite (npm test)
    └── package.json         # npm scripts & dependencies
```

---

## 🚀 Getting Started

### 1. Database & Backend Setup

1. Start **MySQL** in XAMPP Control Panel.
2. Open a terminal in the `server` directory:

```powershell
cd server
npm install
npm run db:init
npm start
```
*API server will listen on `http://localhost:3000`.*

### 2. Run API Tests (Sprint 2 Requirement)

```powershell
cd server
npm test
```

### 3. Run Frontend (50% UI Standalone - No Backend Connection)

```powershell
cd ../rentspace
flutter pub get
flutter run
```
*(Model, Controllers, Unit tests, and Complete frontend are scheduled for Sprint 3; Widget tests and full app connection are scheduled for Sprint 4).*
