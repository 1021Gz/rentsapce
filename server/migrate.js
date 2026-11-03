const fs = require("node:fs");
const path = require("node:path");
const db = require("./rent-space/src/config/db");

async function migrateDatabase() {
  try {
    const uploadsDir = path.join(__dirname, "uploads");
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    await db.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS status ENUM('active', 'suspended') NOT NULL DEFAULT 'active'
    `);
    await db.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS phone VARCHAR(30) DEFAULT ''
    `);

    await db.query(`
      ALTER TABLE spaces 
      MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'hidden') NOT NULL DEFAULT 'pending'
    `);
    await db.query(`
      ALTER TABLE spaces 
      ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'meeting_room'
    `);
    await db.query(`
      ALTER TABLE spaces 
      ADD COLUMN IF NOT EXISTS capacity INT DEFAULT 10
    `);
    await db.query(`
      ALTER TABLE spaces 
      ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT NULL
    `);
    await db.query(`
      ALTER TABLE spaces 
      ADD COLUMN IF NOT EXISTS is_active TINYINT(1) NOT NULL DEFAULT 1
    `);
    await db.query(`
      ALTER TABLE spaces 
      ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) NOT NULL DEFAULT 4.80
    `);
    await db.query(`
      ALTER TABLE spaces 
      ADD COLUMN IF NOT EXISTS rating_count INT NOT NULL DEFAULT 1
    `);

    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS is_paid TINYINT(1) NOT NULL DEFAULT 0
    `);
    await db.query(`
      ALTER TABLE bookings 
      MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'cancelled', 'confirmed', 'completed') NOT NULL DEFAULT 'pending'
    `);
    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS start_time DATETIME DEFAULT NULL
    `);
    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS end_time DATETIME DEFAULT NULL
    `);
    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS total_price DECIMAL(10,2) DEFAULT NULL
    `);
    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS payment_ref VARCHAR(100) DEFAULT NULL
    `);
    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS slip_image_url TEXT DEFAULT NULL
    `);
    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS rating INT DEFAULT NULL
    `);
    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS review_comment TEXT DEFAULT NULL
    `);

    await db.query(`
      UPDATE bookings 
      SET start_time = CONCAT(DATE_FORMAT(start_date, '%Y-%m-%d'), ' 09:00:00'),
          end_time = CONCAT(DATE_FORMAT(end_date, '%Y-%m-%d'), ' 17:00:00')
      WHERE start_time IS NULL OR end_time IS NULL
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS admin_logs (
        log_id INT(11) NOT NULL AUTO_INCREMENT,
        admin_id INT(11) NOT NULL DEFAULT 1003,
        admin_name VARCHAR(100) NOT NULL,
        action VARCHAR(100) NOT NULL,
        target_type VARCHAR(50) NOT NULL,
        target_id INT(11) NOT NULL,
        details TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (log_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS app_session (
        session_key VARCHAR(50) NOT NULL,
        user_id INT(11) DEFAULT NULL,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (session_key)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    `);

    console.log("All 10-feature database migrations applied successfully.");
  } catch (caughtError) {
    console.error("Migration error:", caughtError);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
}

migrateDatabase();
