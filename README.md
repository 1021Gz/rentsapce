# RentSpace (Sprint 2)

> **Sprint 2 Scope**: Complete DB, Complete Backend, API Test, 50% Frontend (No front-back connection)

An hourly space rental application built with **Flutter** (Frontend) and **Node.js / Express + MySQL** (Backend).

---

## 📂 Project Structure

```text
rentspace/
├── rentspace/                                     # Flutter Frontend (50% UI Standalone)
│   ├── lib/                                       # UI Screens, Controllers & Models
│   ├── test/                                      # Widget and unit tests
│   └── pubspec.yaml                               # Flutter dependencies
│
├── server/                                        # Express.js REST API + MySQL Database
│   ├── app.js                                     # Express server entry point
│   ├── db_config.js                               # MySQL2 connection setup
│   ├── init_db.js                                 # Database auto-initialization script
│   ├── schema.sql                                 # Complete DDL schema & sample seeds
│   ├── test/app.test.js                           # Node.js native test suite (npm test)
│   ├── test-api.js                                # Automated E2E API test suite
│   ├── RentSpace_Sprint2_Postman_Collection.json  # Postman Collection v2.1
│   ├── RentSpace_LiteClient_Collection.json       # LiteClient Collection
│   └── package.json                               # npm scripts & dependencies
│
└── .liteclient/                                   # Pre-configured LiteClient requests
    ├── collections.json                           # 15 ready-to-use API requests in VS Code
    └── environments.json                          # Local port 3000 environment
```

---

## 🚀 Getting Started

### 1. Database & Backend Setup

1. Start **Apache** and **MySQL** in XAMPP Control Panel.
2. Open a terminal in the `server` directory:

```powershell
cd server
npm install
npm run db:init
npm start
```
*API server will listen on `http://localhost:3000`.*

### 2. Run API Tests

- **Run native test suite (Node test runner)**:
  ```powershell
  npm test
  ```
- **Run automated E2E API test**:
  ```powershell
  npm run test:api
  ```
- **Run in VS Code LiteClient**:
  Open the **LiteClient** tab in the VS Code sidebar and send any of the 15 pre-configured requests under the `RentSpace API (Sprint 2)` collection.

### 3. Run Frontend (Standalone UI)

```powershell
cd ../rentspace
flutter pub get
flutter run -d chrome
```

Run frontend tests:
```powershell
flutter test
```
