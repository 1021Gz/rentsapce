import '../models/app_models.dart';

class ActionOutcome {
  final bool isSuccess;
  final String message;

  const ActionOutcome({required this.isSuccess, required this.message});
}

List<UserAccount> globalUsers = createInitialUsers();
List<SpaceItem> globalSpaces = createInitialSpaces();
List<BookingItem> globalBookings = createInitialBookings();

UserAccount? currentUser = globalUsers[1]; // default: renter01

void resetMockDatabase() {
  globalUsers = createInitialUsers();
  globalSpaces = createInitialSpaces();
  globalBookings = createInitialBookings();
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
  }) {
    if (username.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      return const ActionOutcome(isSuccess: false, message: 'กรุณากรอกข้อมูลให้ครบถ้วน');
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
      role: 'renter',
    );

    globalUsers.add(newUser);
    currentUser = newUser;
    return const ActionOutcome(isSuccess: true, message: 'สร้างบัญชีสำเร็จ');
  }

  static void logout() {
    currentUser = null;
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
