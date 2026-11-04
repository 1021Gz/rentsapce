SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS rent_space.app_session;
DROP TABLE IF EXISTS rent_space.admin_logs;
DROP TABLE IF EXISTS rent_space.bookings;
DROP TABLE IF EXISTS rent_space.spaces;
DROP TABLE IF EXISTS rent_space.users;
SET FOREIGN_KEY_CHECKS=1;

CREATE DATABASE IF NOT EXISTS `rent_space` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `rent_space`;

-- --------------------------------------------------------
-- Table structure for table `users`
-- --------------------------------------------------------
CREATE TABLE `users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone` varchar(30) DEFAULT '',
  `password_hash` varchar(255) NOT NULL,
  `role` enum('customer','owner','admin') NOT NULL DEFAULT 'customer',
  `status` enum('active','suspended') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for table `spaces`
-- --------------------------------------------------------
CREATE TABLE `spaces` (
  `space_id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `location` varchar(255) NOT NULL,
  `price_per_day` decimal(10,2) NOT NULL,
  `category` varchar(50) DEFAULT 'meeting_room',
  `capacity` int(11) DEFAULT 10,
  `image_url` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `rating` decimal(3,2) NOT NULL DEFAULT 4.80,
  `rating_count` int(11) NOT NULL DEFAULT 1,
  `status` enum('pending','approved','rejected','hidden') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`space_id`),
  KEY `owner_id` (`owner_id`),
  CONSTRAINT `spaces_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for table `bookings`
-- --------------------------------------------------------
CREATE TABLE `bookings` (
  `booking_id` int(11) NOT NULL AUTO_INCREMENT,
  `space_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `total_price` decimal(10,2) DEFAULT NULL,
  `status` enum('pending','approved','rejected','cancelled','confirmed','completed') NOT NULL DEFAULT 'pending',
  `is_paid` tinyint(1) NOT NULL DEFAULT 0,
  `payment_ref` varchar(100) DEFAULT NULL,
  `slip_image_url` text DEFAULT NULL,
  `rating` int(11) DEFAULT NULL,
  `review_comment` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`booking_id`),
  KEY `space_id` (`space_id`),
  KEY `customer_id` (`customer_id`),
  CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`space_id`) REFERENCES `spaces` (`space_id`),
  CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for table `admin_logs`
-- --------------------------------------------------------
CREATE TABLE `admin_logs` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` int(11) NOT NULL DEFAULT 1003,
  `admin_name` varchar(100) NOT NULL,
  `action` varchar(100) NOT NULL,
  `target_type` varchar(50) NOT NULL,
  `target_id` int(11) NOT NULL,
  `details` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



-- --------------------------------------------------------
-- Dumping data for tables
-- --------------------------------------------------------
INSERT INTO `users` (`user_id`, `name`, `username`, `email`, `phone`, `password_hash`, `role`, `status`) VALUES
(1001, 'ภูมิ ศรีสุข (Owner)', 'owner01', 'owner01@rentspace.test', '089-876-5432', '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 'owner', 'active'),
(1002, 'ณัฐ วงศ์ดี (Renter)', 'renter01', 'renter01@rentspace.test', '081-234-5678', '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 'customer', 'active'),
(1003, 'ผู้ดูแลระบบ (Admin)', 'admin01', 'admin01@rentspace.test', '02-999-8888', '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 'admin', 'active'),
(1004, 'มินท์ กมลวรรณ', 'mint_k', 'mint@rentspace.test', '082-333-4444', '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 'customer', 'active'),
(1005, 'แพรว ใจงาม', 'owner02', 'owner02@rentspace.test', '086-555-7777', '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 'owner', 'suspended');

INSERT INTO `spaces` (`space_id`, `owner_id`, `title`, `description`, `location`, `price_per_day`, `category`, `capacity`, `image_url`, `is_active`, `rating`, `rating_count`, `status`) VALUES
(2001, 1001, 'ห้องประชุมสว่างใจ', 'ห้องประชุมพร้อมจอสมาร์ททีวีและอินเทอร์เน็ตความเร็วสูง', '88 ซ.อารีย์ 4 พญาไท กรุงเทพฯ', 350.00, 'meeting_room', 10, 'http://localhost:3000/uploads/meeting.jpg', 1, 4.80, 2, 'approved'),
(2002, 1001, 'The Quiet Nook (ห้องอ่านหนังสือ)', 'ห้องอ่านหนังสือเงียบสงบ แสงธรรมชาติ เหมาะสำหรับอ่านหนังสือหรือติวสอบ', '12 ถ.พระราม 4 ปทุมวัน กรุงเทพฯ', 120.00, 'study_room', 4, 'http://localhost:3000/uploads/study.jpg', 1, 4.90, 3, 'approved'),
(2003, 1001, 'Amp Room Studio (ห้องซ้อมดนตรี)', 'ห้องซ้อมเก็บเสียงมาตรฐาน มีกลองชุด แอมป์ และไมค์ครบชุด', '201 ถ.ลาดพร้าว จตุจักร กรุงเทพฯ', 250.00, 'music_room', 6, 'http://localhost:3000/uploads/music.jpg', 1, 4.70, 1, 'approved'),
(2004, 1005, 'White Box Photo (สตูดิโอ)', 'สตูดิโอถ่ายภาพฉากขาว ไฟ Softbox 2 ชุด พร้อมห้องแต่งตัว', '45 ถ.บางนา-ตราด บางนา กรุงเทพฯ', 600.00, 'studio', 8, 'http://localhost:3000/uploads/studio.jpg', 1, 4.60, 1, 'approved'),
(2005, 1001, 'พื้นที่จัดเวิร์กช็อป', 'พื้นที่อเนกประสงค์สำหรับกิจกรรมกลุ่ม เวิร์กช็อป และสัมมนา', 'เชียงใหม่ นิมมานเหมินท์', 3200.00, 'event_space', 30, 'http://localhost:3000/uploads/meeting.jpg', 1, 4.50, 1, 'pending');

INSERT INTO `bookings` (`booking_id`, `space_id`, `customer_id`, `start_date`, `end_date`, `start_time`, `end_time`, `total_price`, `status`, `is_paid`, `payment_ref`, `slip_image_url`, `rating`, `review_comment`) VALUES
(3001, 2001, 1002, '2026-11-15', '2026-11-15', '2026-11-15 10:00:00', '2026-11-15 12:00:00', 700.00, 'confirmed', 1, 'SLIP-3001-A', 'http://localhost:3000/uploads/meeting.jpg', 5, 'ห้องดีมาก แอร์เย็น สะอาด'),
(3002, 2002, 1002, '2026-11-20', '2026-11-20', '2026-11-20 13:00:00', '2026-11-20 17:00:00', 480.00, 'confirmed', 0, NULL, NULL, NULL, NULL);

INSERT INTO `admin_logs` (`log_id`, `admin_id`, `admin_name`, `action`, `target_type`, `target_id`, `details`) VALUES
(1, 1003, 'ผู้ดูแลระบบ', 'APPROVE_SPACE', 'space', 2001, 'อนุมัติประกาศ ห้องประชุมสว่างใจ'),
(2, 1003, 'ผู้ดูแลระบบ', 'APPROVE_SPACE', 'space', 2002, 'อนุมัติประกาศ The Quiet Nook');

COMMIT;
