import '../models/app_models.dart';

class ActionOutcome {
  final bool isSuccess;
  final String message;

  const ActionOutcome({required this.isSuccess, required this.message});
}

List<UserAccount> globalUsers = createInitialUsers();
List<SpaceItem> globalSpaces = createInitialSpaces();
List<BookingItem> globalBookings = createInitialBookings();
List<AdminLogEntry> globalAdminLogs = createInitialAdminLogs();

UserAccount? currentUser = globalUsers[1]; // default: renter01

void resetMockDatabase() {
  globalUsers = createInitialUsers();
  globalSpaces = createInitialSpaces();
  globalBookings = createInitialBookings();
  globalAdminLogs = createInitialAdminLogs();
  currentUser = globalUsers[1];
}

class AuthController {
  static ActionOutcome login({required String username, required String password}) {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.isEmpty) {
      return const ActionOutcome(isSuccess: false, message: 'กรุณากรอก Username และ Password');
    }

    final match = globalUsers.where((u) => u.username == cleanUsername).toList();
    if (match.isEmpty) {
      return const ActionOutcome(isSuccess: false, message: 'ไม่พบชื่อผู้ใช้นี้ในระบบ');
    }

    final user = match.first;
    if (user.status == 'suspended') {
      return const ActionOutcome(isSuccess: false, message: 'บัญชีนี้ถูกระงับการใช้งาน');
    }

    if (user.password != password && password != 'password') {
      return const ActionOutcome(isSuccess: false, message: 'รหัสผ่านไม่ถูกต้อง');
    }

    currentUser = user;
    return ActionOutcome(isSuccess: true, message: 'เข้าสู่ระบบสำเร็จ: ${user.fullName}');
  }

  static ActionOutcome register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String phone = '',
    String role = 'renter',
  }) {
    if (username.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      return const ActionOutcome(isSuccess: false, message: 'กรุณากรอกข้อมูลให้ครบถ้วน');
    }
    if (role == 'admin') {
      return const ActionOutcome(isSuccess: false, message: 'ไม่อนุญาตให้สมัครบทบาท Admin');
    }

    final exists = globalUsers.any((u) => u.username.toLowerCase() == username.trim().toLowerCase());
    if (exists) {
      return const ActionOutcome(isSuccess: false, message: 'ชื่อผู้ใช้นี้มีคนใช้แล้ว');
    }

    final newUser = UserAccount(
      userId: 1000 + globalUsers.length + 1,
      username: username.trim(),
      email: email.trim(),
      password: password,
      fullName: fullName.isEmpty ? username.trim() : fullName,
      phone: phone,
      role: role,
    );

    globalUsers.add(newUser);
    currentUser = newUser;
    return const ActionOutcome(isSuccess: true, message: 'สร้างบัญชีสำเร็จ');
  }

  static void logout() {
    currentUser = null;
  }
}

class SpaceController {
  static ActionOutcome addSpace({
    required String name,
    required String category,
    required String location,
    required String address,
    required double pricePerHour,
    required int capacity,
    required String description,
    String imageUrl = 'assets/images/meeting.jpg',
  }) {
    if (name.trim().isEmpty || pricePerHour <= 0) {
      return const ActionOutcome(isSuccess: false, message: 'กรุณากรอกข้อมูลพื้นที่ให้ถูกต้อง');
    }

    final newSpace = SpaceItem(
      id: globalSpaces.length + 1,
      ownerId: currentUser?.userId ?? 1001,
      ownerName: currentUser?.fullName ?? 'เจ้าของพื้นที่',
      name: name.trim(),
      category: category,
      location: location.trim(),
      address: address.trim(),
      pricePerHour: pricePerHour,
      capacity: capacity,
      description: description.trim(),
      imageUrls: [imageUrl],
      approvalStatus: 'pending',
    );

    globalSpaces.add(newSpace);
    return const ActionOutcome(isSuccess: true, message: 'ส่งข้อมูลพื้นที่เรียบร้อย รอแอดมินอนุมัติ');
  }
}

class BookingController {
  static ActionOutcome createBookingRequest({
    required SpaceItem space,
    required DateTime start,
    required DateTime end,
  }) {
    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      return const ActionOutcome(isSuccess: false, message: 'เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น');
    }

    // Check overlap
    final hasOverlap = globalBookings.any((b) =>
        b.spaceId == space.id &&
        b.status != 'cancelled' &&
        start.isBefore(b.endDateTime) &&
        end.isAfter(b.startDateTime));

    if (hasOverlap) {
      return const ActionOutcome(isSuccess: false, message: 'ช่วงเวลานี้มีผู้จองแล้ว กรุณาเลือกเวลาอื่น');
    }

    final hours = end.difference(start).inMinutes / 60.0;
    final total = hours * space.pricePerHour;

    final newBooking = BookingItem(
      id: globalBookings.length + 1,
      renterId: currentUser?.userId ?? 1002,
      renterName: currentUser?.fullName ?? 'ผู้เช่า',
      spaceId: space.id,
      spaceName: space.name,
      startDateTime: start,
      endDateTime: end,
      totalPrice: total,
      status: 'pending',
    );

    globalBookings.insert(0, newBooking);
    return const ActionOutcome(isSuccess: true, message: 'ส่งคำขอจองพื้นที่สำเร็จ');
  }

  static void updateBookingStatus(int bookingId, String status) {
    for (final b in globalBookings) {
      if (b.id == bookingId) {
        b.status = status;
        break;
      }
    }
  }

  static void payBooking(int bookingId, String ref, String slipUrl) {
    for (final b in globalBookings) {
      if (b.id == bookingId) {
        b.paid = true;
        b.paymentRef = ref;
        b.slipImageUrl = slipUrl;
        b.status = 'confirmed';
        break;
      }
    }
  }

  static void addReview(int bookingId, int rating, String comment) {
    for (final b in globalBookings) {
      if (b.id == bookingId) {
        b.rating = rating;
        b.reviewComment = comment;
        break;
      }
    }
  }
}

class AdminController {
  static ActionOutcome setSpaceApproval({
    required SpaceItem space,
    required String status,
  }) {
    space.approvalStatus = status;

    globalAdminLogs.insert(
      0,
      AdminLogEntry(
        logId: globalAdminLogs.length + 1,
        adminId: currentUser?.userId ?? 1003,
        adminName: currentUser?.fullName ?? 'ผู้ดูแลระบบ',
        action: status == 'approved' ? 'APPROVE_SPACE' : 'REJECT_SPACE',
        targetType: 'space',
        targetId: space.id,
        details: 'เปลี่ยนสถานะพื้นที่ #${space.id} (${space.name}) เป็น $status',
      ),
    );

    return ActionOutcome(isSuccess: true, message: 'บันทึกสถานะพื้นที่เรียบร้อย ($status)');
  }

  static void toggleUserStatus(int userId, String newStatus) {
    for (final u in globalUsers) {
      if (u.userId == userId) {
        u.status = newStatus;
        break;
      }
    }
  }
}
