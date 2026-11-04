class UserAccount {
  int userId;
  final String username;
  String email;
  String password;
  String fullName;
  String phone;
  final String role;
  String status;

  UserAccount({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.phone = '',
    this.role = 'renter',
    this.status = 'active',
  });
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
    List<String>? imageUrls,
    required this.description,
    this.approvalStatus = 'approved',
    this.isActive = true,
  }) : imageUrls = imageUrls ?? ['assets/images/meeting.jpg'];

  String get imageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : 'assets/images/meeting.jpg';

  String get categoryLabel {
    switch (category) {
      case 'meeting_room':
      case 'ห้องประชุม':
        return 'ห้องประชุม';
      case 'study_room':
      case 'ห้องอ่านหนังสือ':
        return 'ห้องอ่านหนังสือ';
      case 'music_room':
      case 'ห้องซ้อมดนตรี':
        return 'ห้องซ้อมดนตรี';
      case 'studio':
      case 'สตูดิโอ':
        return 'สตูดิโอ';
      default:
        return 'พื้นที่อเนกประสงค์';
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

  BookingItem({
    required this.id,
    this.renterId = 1002,
    this.spaceId = 1,
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
  });

  String get startTime => formatDt(startDateTime);
  String get endTime => formatDt(endDateTime);

  static String formatDt(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

  String get formattedTime => BookingItem.formatDt(createdAt);
}

List<UserAccount> createInitialUsers() => [
      UserAccount(
        userId: 1001,
        username: 'owner01',
        email: 'owner01@rentspace.test',
        password: 'password',
        fullName: 'ภูมิ ศรีสุข (เจ้าของ)',
        phone: '089-876-5432',
        role: 'owner',
      ),
      UserAccount(
        userId: 1002,
        username: 'renter01',
        email: 'renter01@rentspace.test',
        password: 'password',
        fullName: 'ณัฐ วงศ์ดี (ผู้เช่า)',
        phone: '081-234-5678',
        role: 'renter',
      ),
      UserAccount(
        userId: 1003,
        username: 'admin01',
        email: 'admin01@rentspace.test',
        password: 'password',
        fullName: 'ผู้ดูแลระบบ (Admin)',
        phone: '02-999-8888',
        role: 'admin',
      ),
    ];

List<SpaceItem> createInitialSpaces() => [
      SpaceItem(
        id: 1,
        ownerId: 1001,
        name: 'ห้องประชุมสว่างใจ',
        category: 'meeting_room',
        location: 'อารีย์ กรุงเทพฯ',
        address: '123 ซอยอารีย์ 1 แขวงพญาไท',
        pricePerHour: 350.0,
        capacity: 10,
        rating: 4.8,
        description: 'ห้องประชุมขนาดกะทัดรัด พร้อมจอโปรเจกเตอร์ ไวท์บอร์ด และ Wi-Fi ความเร็วสูง',
        imageUrls: ['assets/images/meeting.jpg'],
        approvalStatus: 'approved',
      ),
      SpaceItem(
        id: 2,
        ownerId: 1001,
        name: 'สตูดิโอถ่ายภาพธรรมชาติ',
        category: 'studio',
        location: 'ทองหล่อ กรุงเทพฯ',
        address: '45/8 สุขุมวิท 55',
        pricePerHour: 600.0,
        capacity: 15,
        rating: 4.9,
        description: 'สตูดิโอแสงธรรมชาติ เพดานสูง พร้อมไฟต่อเนื่อง และฉากหลังหลากสี',
        imageUrls: ['assets/images/studio.jpg'],
        approvalStatus: 'approved',
      ),
      SpaceItem(
        id: 3,
        ownerId: 1001,
        name: 'ห้องซ้อมดนตรี Rhythm Box',
        category: 'music_room',
        location: 'ลาดพร้าว กรุงเทพฯ',
        address: '88 ลาดพร้าว ซอย 15',
        pricePerHour: 450.0,
        capacity: 6,
        rating: 4.7,
        description: 'ห้องซ้อมดนตรีเก็บเสียงมาตรฐาน พร้อมกลองชุด แอมป์กีตาร์ และไมโครโฟน',
        imageUrls: ['assets/images/music.jpg'],
        approvalStatus: 'approved',
      ),
      SpaceItem(
        id: 4,
        ownerId: 1001,
        name: 'พื้นที่จัดสัมมนา The Hub',
        category: 'study_room',
        location: 'สยาม กรุงเทพฯ',
        address: '99 ถนนพระราม 1',
        pricePerHour: 800.0,
        capacity: 30,
        rating: 4.6,
        description: 'พื้นที่จัดเวิร์กช็อปและสัมมนา รองรับได้สูงสุด 30 ที่นั่ง',
        imageUrls: ['assets/images/study.jpg'],
        approvalStatus: 'pending',
      ),
    ];

List<BookingItem> createInitialBookings() => [
      BookingItem(
        id: 1,
        renterId: 1002,
        spaceId: 1,
        spaceName: 'ห้องประชุมสว่างใจ',
        renterName: 'ณัฐ วงศ์ดี',
        startDateTime: DateTime(2026, 11, 5, 10, 0),
        endDateTime: DateTime(2026, 11, 5, 12, 0),
        totalPrice: 700.0,
        status: 'confirmed',
        paid: true,
        paymentRef: 'PAY-1001',
      ),
      BookingItem(
        id: 2,
        renterId: 1002,
        spaceId: 2,
        spaceName: 'สตูดิโอถ่ายภาพธรรมชาติ',
        renterName: 'ณัฐ วงศ์ดี',
        startDateTime: DateTime(2026, 11, 6, 13, 0),
        endDateTime: DateTime(2026, 11, 6, 15, 0),
        totalPrice: 1200.0,
        status: 'pending',
        paid: false,
      ),
    ];

List<AdminLogEntry> createInitialAdminLogs() => [
      AdminLogEntry(
        logId: 1,
        adminId: 1003,
        adminName: 'ผู้ดูแลระบบ',
        action: 'APPROVE_SPACE',
        targetType: 'space',
        targetId: 1,
        details: 'อนุมัติห้องประชุมสว่างใจ',
      ),
    ];
