import 'package:flutter/material.dart';

class UserAccount {
  int userId;
  final String username;
  String email;
  String password;
  String fullName;
  String phone;
  final String role;
  String status;
  final DateTime createdAt;

  UserAccount({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.phone = '',
    this.role = 'renter',
    this.status = 'active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime(2026, 11, 1, 9, 0);
}

class SpaceItem {
  int id;
  final int ownerId;
  final String ownerName;
  String name;
  String category;
  String location;
  String address;
  double pricePerHour;
  int capacity;
  double rating;
  List<String> imageUrls;
  String description;
  String approvalStatus;
  bool isActive;
  final DateTime createdAt;

  SpaceItem({
    required this.id,
    this.ownerId = 1001,
    this.ownerName = 'ภูมิ ศรีสุข',
    required this.name,
    required this.category,
    this.location = 'อารีย์',
    required this.address,
    required this.pricePerHour,
    required this.capacity,
    this.rating = 4.8,
    String? imageUrl,
    List<String>? imageUrls,
    required this.description,
    this.approvalStatus = 'approved',
    this.isActive = true,
    DateTime? createdAt,
  }) : imageUrls = imageUrls ??
           (imageUrl != null && imageUrl.isNotEmpty
               ? [imageUrl]
               : ['assets/images/meeting.jpg']),
       createdAt = createdAt ?? DateTime(2026, 11, 1, 10, 0);

  String get imageUrl => imageUrls.isNotEmpty
      ? imageUrls.first
      : 'assets/images/meeting.jpg';

  String get categoryLabel => formatCategoryLabel(category);

  static String formatCategoryLabel(String key) {
    switch (key) {
      case 'study_room':
      case 'ห้องอ่านหนังสือ':
        return 'ห้องอ่านหนังสือ';
      case 'meeting_room':
      case 'ห้องประชุม':
        return 'ห้องประชุม';
      case 'music_room':
      case 'ห้องซ้อมดนตรี':
        return 'ห้องซ้อมดนตรี';
      case 'studio':
      case 'สตูดิโอ':
        return 'สตูดิโอ';
      case 'event_space':
      case 'พื้นที่จัดเวิร์กช็อป':
        return 'พื้นที่จัดเวิร์กช็อป';
      default:
        return 'อื่นๆ';
    }
  }
}

class BookingItem {
  int id;
  final int renterId;
  final int spaceId;
  final String spaceName;
  final String renterName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double totalPrice;
  String status;
  bool paid;
  String paymentRef;
  String slipImageUrl;
  int? rating;
  String reviewComment;
  final DateTime createdAt;

  BookingItem({
    required this.id,
    this.renterId = 1002,
    this.spaceId = 2001,
    required this.spaceName,
    required this.renterName,
    required this.startDateTime,
    required this.endDateTime,
    required this.totalPrice,
    this.status = 'pending',
    this.paid = false,
    this.paymentRef = '',
    this.slipImageUrl = '',
    this.rating,
    this.reviewComment = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime(2026, 11, 2, 11, 0);

  String get startTime => formatDateTimeDisplay(startDateTime);
  String get endTime => formatDateTimeDisplay(endDateTime);

  double get durationHours =>
      endDateTime.difference(startDateTime).inMinutes / 60.0;

  static String formatDateTimeDisplay(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}

class AdminLogEntry {
  int logId;
  final int adminId;
  final String adminName;
  final String action;
  final String targetType;
  final int targetId;
  final String details;
  final DateTime createdAt;

  AdminLogEntry({
    required this.logId,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedTime => BookingItem.formatDateTimeDisplay(createdAt);
}

List<UserAccount> createInitialUsers() => [
  UserAccount(
    userId: 1001,
    username: 'owner01',
    email: 'owner01@rentspace.test',
    password: 'password',
    fullName: 'ภูมิ ศรีสุข',
    phone: '089-876-5432',
    role: 'owner',
    status: 'active',
  ),
  UserAccount(
    userId: 1002,
    username: 'renter01',
    email: 'renter01@rentspace.test',
    password: 'password',
    fullName: 'ณัฐ วงศ์ดี',
    phone: '081-234-5678',
    role: 'renter',
    status: 'active',
  ),
  UserAccount(
    userId: 1003,
    username: 'admin01',
    email: 'admin01@rentspace.test',
    password: 'password',
    fullName: 'ผู้ดูแลระบบ',
    phone: '02-999-8888',
    role: 'admin',
    status: 'active',
  ),
  UserAccount(
    userId: 1004,
    username: 'mint_k',
    email: 'mint@rentspace.test',
    password: 'password',
    fullName: 'มินท์ กมลวรรณ',
    phone: '082-333-4444',
    role: 'renter',
    status: 'active',
  ),
  UserAccount(
    userId: 1005,
    username: 'owner02',
    email: 'owner02@rentspace.test',
    password: 'password',
    fullName: 'แพรว ใจงาม',
    phone: '086-555-7777',
    role: 'owner',
    status: 'suspended',
  ),
  // Demo accounts for tests & backward-compatibility
  UserAccount(
    userId: 1,
    username: 'demo_customer',
    email: 'customer@example.test',
    password: 'password123',
    fullName: 'ลูกค้าตัวอย่าง (Renter)',
    role: 'renter',
  ),
  UserAccount(
    userId: 2,
    username: 'demo_owner',
    email: 'owner@example.test',
    password: 'password123',
    fullName: 'เจ้าของตัวอย่าง (Owner)',
    role: 'owner',
  ),
  UserAccount(
    userId: 3,
    username: 'demo_admin',
    email: 'admin@example.test',
    password: 'password123',
    fullName: 'ผู้ดูแลระบบ (Admin)',
    role: 'admin',
  ),
];

List<SpaceItem> createInitialSpaces() => [
  SpaceItem(
    id: 1,
    ownerId: 1001,
    ownerName: 'ภูมิ ศรีสุข',
    name: 'ห้องประชุมสว่างใจ',
    category: 'meeting_room',
    location: 'อารีย์',
    address: '88 ซ.อารีย์ 4 พญาไท กรุงเทพฯ',
    pricePerHour: 350.00,
    capacity: 10,
    rating: 4.7,
    imageUrls: ['assets/images/meeting.jpg'],
    description:
        'ห้องประชุมพร้อมจอ TV 65 นิ้ว ไวท์บอร์ด แอร์เย็นสบาย และระบบประชุมออนไลน์ครบครัน',
    approvalStatus: 'approved',
    isActive: true,
  ),
  SpaceItem(
    id: 2,
    ownerId: 1001,
    ownerName: 'ภูมิ ศรีสุข',
    name: 'The Quiet Nook (ห้องอ่านหนังสือ)',
    category: 'study_room',
    location: 'สามย่าน',
    address: '12 ถ.พระราม 4 ปทุมวัน กรุงเทพฯ',
    pricePerHour: 120.00,
    capacity: 4,
    rating: 4.8,
    imageUrls: ['assets/images/study.jpg'],
    description:
        'ห้องอ่านหนังสือเงียบสงบ แสงธรรมชาติ มี Wi-Fi ความเร็วสูง และปลั๊กไฟทุกโต๊ะ เหมาะกับการติวสอบ',
    approvalStatus: 'approved',
    isActive: true,
  ),
  SpaceItem(
    id: 3,
    ownerId: 1005,
    ownerName: 'แพรว ใจงาม',
    name: 'Amp Room Studio (ห้องซ้อมดนตรี)',
    category: 'music_room',
    location: 'ลาดพร้าว',
    address: '201 ถ.ลาดพร้าว จตุจักร กรุงเทพฯ',
    pricePerHour: 250.00,
    capacity: 6,
    rating: 4.9,
    imageUrls: ['assets/images/music.jpg'],
    description:
        'ห้องซ้อมเก็บเสียงมาตรฐาน มีกลองชุด แอมป์กีตาร์ แอมป์เบส และไมค์ครบชุด พร้อมบันทึกเสียง',
    approvalStatus: 'approved',
    isActive: true,
  ),
  SpaceItem(
    id: 4,
    ownerId: 1005,
    ownerName: 'แพรว ใจงาม',
    name: 'White Box Photo (สตูดิโอ)',
    category: 'studio',
    location: 'บางนา',
    address: '45 ถ.บางนา-ตราด บางนา กรุงเทพฯ',
    pricePerHour: 600.00,
    capacity: 8,
    rating: 4.6,
    imageUrls: ['assets/images/studio.jpg'],
    description:
        'สตูดิโอถ่ายภาพฉากขาว ไฟ Softbox 2 ชุด พื้นที่ 60 ตร.ม. พร้อมห้องแต่งตัว',
    approvalStatus: 'approved',
    isActive: true,
  ),
  SpaceItem(
    id: 5,
    ownerId: 1001,
    ownerName: 'ภูมิ ศรีสุข',
    name: 'พื้นที่จัดเวิร์กช็อป',
    category: 'event_space',
    location: 'เชียงใหม่',
    address: 'นิมมานเหมินท์ ซอย 5 เชียงใหม่',
    pricePerHour: 3200.00,
    capacity: 30,
    rating: 4.5,
    imageUrls: ['assets/images/meeting.jpg'],
    description:
        'พื้นที่อเนกประสงค์สำหรับกิจกรรมกลุ่ม เวิร์กช็อป และสัมมนาขนาดย่อม',
    approvalStatus: 'pending',
    isActive: true,
  ),
];

List<BookingItem> createInitialBookings() => [
  BookingItem(
    id: 1,
    renterId: 1002,
    spaceId: 2,
    spaceName: 'The Quiet Nook (ห้องอ่านหนังสือ)',
    renterName: 'ณัฐ วงศ์ดี',
    startDateTime: DateTime(2026, 11, 6, 13, 0),
    endDateTime: DateTime(2026, 11, 6, 17, 0),
    totalPrice: 480.00,
    status: 'confirmed',
    paid: false,
  ),
  BookingItem(
    id: 2,
    renterId: 1002,
    spaceId: 1,
    spaceName: 'ห้องประชุมสว่างใจ',
    renterName: 'ณัฐ วงศ์ดี',
    startDateTime: DateTime(2026, 11, 8, 10, 0),
    endDateTime: DateTime(2026, 11, 8, 12, 0),
    totalPrice: 700.00,
    status: 'confirmed',
    paid: false,
  ),
  BookingItem(
    id: 3,
    renterId: 1002,
    spaceId: 3,
    spaceName: 'Amp Room Studio (ห้องซ้อมดนตรี)',
    renterName: 'ณัฐ วงศ์ดี',
    startDateTime: DateTime(2026, 11, 10, 18, 0),
    endDateTime: DateTime(2026, 11, 10, 20, 0),
    totalPrice: 500.00,
    status: 'pending',
    paid: false,
  ),
  BookingItem(
    id: 4,
    renterId: 1002,
    spaceId: 2,
    spaceName: 'The Quiet Nook (ห้องอ่านหนังสือ)',
    renterName: 'ณัฐ วงศ์ดี',
    startDateTime: DateTime(2026, 10, 28, 13, 0),
    endDateTime: DateTime(2026, 10, 28, 16, 0),
    totalPrice: 360.00,
    status: 'completed',
    paid: true,
  ),
];

List<AdminLogEntry> createInitialLogs() => [
  AdminLogEntry(
    logId: 1,
    adminId: 1003,
    adminName: 'ผู้ดูแลระบบ',
    action: 'APPROVE_SPACE',
    targetType: 'space',
    targetId: 2001,
    details: 'อนุมัติประกาศ Sage Meeting Room',
    createdAt: DateTime(2026, 11, 1, 10, 30),
  ),
  AdminLogEntry(
    logId: 2,
    adminId: 1003,
    adminName: 'ผู้ดูแลระบบ',
    action: 'APPROVE_SPACE',
    targetType: 'space',
    targetId: 2002,
    details: 'อนุมัติประกาศ The Quiet Nook',
    createdAt: DateTime(2026, 11, 1, 11, 0),
  ),
];

List<UserAccount> globalUsers = createInitialUsers();
List<SpaceItem> globalSpaces = createInitialSpaces();
List<BookingItem> globalBookings = createInitialBookings();
List<AdminLogEntry> globalAdminLogs = createInitialLogs();
UserAccount? currentSessionUser = globalUsers.firstWhere(
  (u) => u.username == 'renter01',
);
bool isDatabaseSynced = false;

void resetMockDatabase() {
  globalUsers = createInitialUsers();
  globalSpaces = createInitialSpaces();
  globalBookings = createInitialBookings();
  globalAdminLogs = createInitialLogs();
  currentSessionUser = globalUsers.firstWhere(
    (u) => u.username == 'renter01',
  );
  isDatabaseSynced = false;
}

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = isDark ? const Color(0xFF1B382B) : const Color(0xFFE4F0E8);
        fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E633D);
        label = 'ยืนยันแล้ว';
        break;
      case 'approved':
        bg = isDark ? const Color(0xFF1B382B) : const Color(0xFFE4F0E8);
        fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E633D);
        label = 'อนุมัติแล้ว';
        break;
      case 'completed':
        bg = isDark ? const Color(0xFF1B382B) : const Color(0xFFE4F0E8);
        fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E633D);
        label = 'สำเร็จ';
        break;
      case 'pending':
        bg = isDark ? const Color(0xFF3D2C1A) : const Color(0xFFFCE8CF);
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFF8A4C00);
        label = 'รอตอบ';
        break;
      case 'rejected':
        bg = isDark ? const Color(0xFF3B1818) : const Color(0xFFFDE8E8);
        fg = isDark ? const Color(0xFFF87171) : const Color(0xFFC53030);
        label = 'ปฏิเสธ';
        break;
      case 'cancelled':
        bg = isDark ? const Color(0xFF3B1818) : const Color(0xFFFDE8E8);
        fg = isDark ? const Color(0xFFF87171) : const Color(0xFFC53030);
        label = 'ยกเลิกแล้ว';
        break;
      case 'hidden':
        bg = isDark ? const Color(0xFF283248) : const Color(0xFFFDE8E8);
        fg = isDark ? const Color(0xFF94A3B8) : const Color(0xFFC53030);
        label = 'ซ่อนอยู่';
        break;
      default:
        bg = isDark ? const Color(0xFF283248) : Colors.grey.shade200;
        fg = isDark ? Colors.white70 : Colors.black87;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class RentSpaceImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const RentSpaceImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      imageWidget = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/images/meeting.jpg', width: width, height: height, fit: fit),
      );
    } else {
      imageWidget = Image.asset(
        path.isNotEmpty ? path : 'assets/images/meeting.jpg',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/images/meeting.jpg', width: width, height: height, fit: fit),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }
}
