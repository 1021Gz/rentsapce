# RentSpace (Sprint 2)

> **Sprint 2 Scope**: Complete DB, Complete Backend, API Test, 50% Frontend (No front-back connection)

An hourly space rental application built with **Flutter** (Frontend) and **Node.js / Express + MySQL** (Backend).

---

## 📁 Project Structure

```text
rentspace/
├── rentspace/                                     # Flutter Frontend (50% UI Standalone)
│   ├── lib/                                       # UI Screens (50% Standalone) & Mock Data
│   └── pubspec.yaml                               # Flutter dependencies (name: rentspace)
│
├── server/                                        # Express.js REST API + MySQL Database
│   ├── app.js                                     # Express server (argon2id & JWT)
│   ├── db_config.js                               # MySQL2 connection setup
│   ├── init_db.js                                 # Database auto-initialization script
│   ├── schema.sql                                 # Complete DDL schema & sample seeds
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

### 2. Run API Tests (Sprint 2 Requirement)

- **Run in VS Code LiteClient**:
  Open the **LiteClient** tab in the VS Code sidebar and send any of the pre-configured requests under the `RentSpace API (Sprint 2)` collection.
- **Run automated E2E API test**:
  ```powershell
  npm test
  ```

### 3. Run Frontend (50% UI Standalone - No Backend Connection)

```powershell
cd ../rentspace
flutter pub get
flutter run
```
*(Model, Controllers, Unit tests, and Complete frontend are scheduled for Sprint 3; Widget tests and full app connection are scheduled for Sprint 4).*
