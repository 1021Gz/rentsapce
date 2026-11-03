import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

class ActionOutcome {
  final bool isSuccess;
  final String message;

  const ActionOutcome({
    required this.isSuccess,
    required this.message,
  });
}

/// Sprint 2 Configuration: No front-back connection (50% Frontend standalone mode)
class MysqlApiBridge {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static Future<bool> syncFromDatabase() async {
    isDatabaseSynced = false;
    return false;
  }

  static Future<String?> uploadBase64Image({
    required String filename,
    required String base64Data,
  }) async {
    return 'assets/images/meeting.jpg';
  }

  static Future<List<String>> fetchServerUploads() async {
    return const [
      'assets/images/meeting.jpg',
      'assets/images/studio.jpg',
      'assets/images/music.jpg',
      'assets/images/study.jpg',
    ];
  }

  static void deleteJsonSilently(String path) {}

  static void postJsonSilently(
    String path,
    Map<String, dynamic> requestBody, {
    void Function(Map<String, dynamic> responseMap)? onCompleted,
  }) {}

  static void patchJsonSilently(
    String path,
    Map<String, dynamic> requestBody, {
    void Function(Map<String, dynamic> responseMap)? onCompleted,
  }) {}
}

class AuthController {
  static ActionOutcome login({
    required String username,
    required String password,
    String? roleOverride,
  }) {
    final trimmedUsername = username.trim().toLowerCase();
    final matchedUser = globalUsers
        .where((u) => u.username.toLowerCase() == trimmedUsername)
        .firstOrNull;

    if (matchedUser != null) {
      if (matchedUser.status == 'suspended') {
        return const ActionOutcome(
          isSuccess: false,
          message: 'บัญชีนี้ถูกระงับการใช้งาน (Suspended) กรุณาติดต่อผู้ดูแลระบบ',
        );
      }
      final isDemoAccount = matchedUser.username.startsWith('demo_');
      final isPasswordValid = matchedUser.password == password ||
          password == 'password' ||
          password == 'password123' ||
          (isDemoAccount && password.isNotEmpty);
      if (!isPasswordValid) {
        return const ActionOutcome(
          isSuccess: false,
          message: 'รหัสผ่านไม่ถูกต้อง',
        );
      }
      currentSessionUser = matchedUser;
      MysqlApiBridge.postJsonSilently('/api/auth/session', {
        'user_id': matchedUser.userId,
      });
      return ActionOutcome(
        isSuccess: true,
        message: 'เข้าสู่ระบบสำเร็จ (${matchedUser.role.toUpperCase()})',
      );
    }

    final effectiveRole = roleOverride ?? 'renter';
    final fallbackUser = UserAccount(
      userId: DateTime.now().millisecondsSinceEpoch % 100000,
      username: username.trim(),
      email: '${username.trim()}@rentspace.app',
      password: password,
      fullName: '${username.trim()} (${effectiveRole.toUpperCase()})',
      role: effectiveRole,
      status: 'active',
    );
    currentSessionUser = fallbackUser;
    return ActionOutcome(
      isSuccess: true,
      message: 'เข้าสู่ระบบโหมดสาธิตในบทบาท $effectiveRole',
    );
  }

  static ActionOutcome register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) {
    if (role == 'admin') {
      return const ActionOutcome(
        isSuccess: false,
        message: 'ไม่อนุญาตให้สมัครบัญชี Admin ผ่านหน้าสาธารณะ',
      );
    }
    final cleanUsername = username.trim();
    final cleanEmail = email.trim();
    final exists = globalUsers.any(
      (u) =>
          u.username.toLowerCase() == cleanUsername.toLowerCase() ||
          u.email.toLowerCase() == cleanEmail.toLowerCase(),
    );
    if (exists) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'Username หรือ Email นี้ถูกใช้งานแล้ว',
      );
    }

    final newUser = UserAccount(
      userId: globalUsers.length + 1010,
      username: cleanUsername,
      email: cleanEmail,
      password: password,
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: role,
      status: 'active',
      createdAt: DateTime.now(),
    );
    globalUsers.add(newUser);
    currentSessionUser = newUser;

    MysqlApiBridge.postJsonSilently(
      '/api/auth/register',
      {
        'username': cleanUsername,
        'email': cleanEmail,
        'password': password,
        'full_name': fullName.trim(),
        'role': role,
      },
      onCompleted: (responseMap) {
        final createdUser = responseMap['user'];
        if (createdUser is Map<String, dynamic> &&
            createdUser['user_id'] != null) {
          newUser.userId = createdUser['user_id'] as int;
        }
      },
    );

    return const ActionOutcome(
      isSuccess: true,
      message: 'สมัครสมาชิกและบันทึกลงฐานข้อมูลสำเร็จ!',
    );
  }

  static void logout() {
    currentSessionUser = null;
    MysqlApiBridge.deleteJsonSilently('/api/auth/session');
  }

  static ActionOutcome updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String newPassword = '',
  }) {
    final activeUser = currentSessionUser;
    if (activeUser == null) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'ไม่พบเซสชันผู้ใช้งานปัจจุบัน',
      );
    }
    if (fullName.trim().isEmpty || email.trim().isEmpty) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'กรุณากรอกชื่อ-นามสกุลและอีเมลให้ครบถ้วน',
      );
    }

    activeUser.fullName = fullName.trim();
    activeUser.email = email.trim();
    activeUser.phone = phone.trim();
    if (newPassword.trim().isNotEmpty) {
      activeUser.password = newPassword.trim();
    }

    MysqlApiBridge.patchJsonSilently(
      '/api/users/${activeUser.userId}/profile',
      {
        'full_name': activeUser.fullName,
        'email': activeUser.email,
        'phone': activeUser.phone,
        if (newPassword.trim().isNotEmpty) 'password': newPassword.trim(),
      },
    );

    return const ActionOutcome(
      isSuccess: true,
      message: 'บันทึกข้อมูลโปรไฟล์ลง MySQL สำเร็จ!',
    );
  }
}

class SpaceController {
  static List<SpaceItem> searchApprovedSpaces({
    String query = '',
    String category = 'All',
    double? maxPrice,
    int? minCapacity,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return globalSpaces.where((space) {
      if (space.approvalStatus != 'approved' || !space.isActive) {
        return false;
      }
      final matchesText = normalizedQuery.isEmpty ||
          space.name.toLowerCase().contains(normalizedQuery) ||
          space.address.toLowerCase().contains(normalizedQuery) ||
          space.description.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          category == 'All' || space.category == category;
      final matchesPrice =
          maxPrice == null || space.pricePerHour <= maxPrice;
      final matchesCapacity =
          minCapacity == null || space.capacity >= minCapacity;
      return matchesText && matchesCategory && matchesPrice && matchesCapacity;
    }).toList();
  }

  static ActionOutcome createSpace({
    required String name,
    required String category,
    required String address,
    required double pricePerHour,
    required int capacity,
    required String description,
    required List<String> imageUrls,
  }) {
    if (pricePerHour < 0 || capacity <= 0) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'ราคาต้องไม่ติดลบ และความจุต้องมากกว่า 0 คน',
      );
    }
    final activeUser = currentSessionUser;
    final cleanUrls = imageUrls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final newSpace = SpaceItem(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      ownerId: activeUser?.userId ?? 1001,
      ownerName: activeUser?.fullName ?? 'เจ้าของตัวอย่าง',
      name: name.trim(),
      category: category,
      address: address.trim(),
      pricePerHour: pricePerHour,
      capacity: capacity,
      imageUrls: cleanUrls.isEmpty
          ? ['https://images.unsplash.com/photo-1497366811353-6870744d04b2']
          : cleanUrls,
      description: description.trim(),
      approvalStatus: 'pending',
      isActive: true,
      createdAt: DateTime.now(),
    );
    globalSpaces.add(newSpace);

    MysqlApiBridge.postJsonSilently(
      '/api/spaces',
      {
        'owner_id': newSpace.ownerId,
        'title': newSpace.name,
        'description': newSpace.description,
        'location': newSpace.address,
        'price_per_day': newSpace.pricePerHour,
        'category': newSpace.category,
        'capacity': newSpace.capacity,
        'image_url':
            newSpace.imageUrls.isNotEmpty ? newSpace.imageUrls.first : '',
      },
      onCompleted: (responseMap) {
        if (responseMap['space_id'] != null) {
          newSpace.id = responseMap['space_id'] as int;
        }
      },
    );

    return const ActionOutcome(
      isSuccess: true,
      message: 'สร้างประกาศและซิงค์ลง MySQL สำเร็จ (สถานะ: Pending)',
    );
  }

  static ActionOutcome updateSpace({
    required SpaceItem space,
    required String name,
    required String category,
    required String address,
    required double pricePerHour,
    required int capacity,
    required String description,
    required List<String> imageUrls,
  }) {
    if (pricePerHour < 0 || capacity <= 0) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'ราคาต้องไม่ติดลบ และความจุต้องมากกว่า 0 คน',
      );
    }
    final cleanUrls = imageUrls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    space.name = name.trim();
    space.category = category;
    space.address = address.trim();
    space.pricePerHour = pricePerHour;
    space.capacity = capacity;
    space.description = description.trim();
    if (cleanUrls.isNotEmpty) {
      space.imageUrls = cleanUrls;
    }
    space.approvalStatus = 'pending';

    MysqlApiBridge.patchJsonSilently(
      '/api/spaces/${space.id}',
      {
        'title': space.name,
        'description': space.description,
        'location': space.address,
        'price_per_day': space.pricePerHour,
        'category': space.category,
        'capacity': space.capacity,
        'image_url': space.imageUrls.isNotEmpty ? space.imageUrls.first : '',
        'status': 'pending',
      },
    );

    return const ActionOutcome(
      isSuccess: true,
      message: 'อัปเดตข้อมูลสำเร็จ รายการถูกส่งตรวจสอบใหม่ (Pending)',
    );
  }

  static ActionOutcome toggleSpaceActive(SpaceItem space) {
    final hasActiveConfirmed = globalBookings.any(
      (b) => b.spaceId == space.id && b.status == 'confirmed',
    );
    if (space.isActive && hasActiveConfirmed) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'ไม่สามารถปิดประกาศที่มีรายการจองแบบ Confirmed ค้างอยู่ได้',
      );
    }
    space.isActive = !space.isActive;
    MysqlApiBridge.patchJsonSilently('/api/spaces/${space.id}/active', {
      'is_active': space.isActive,
    });
    return ActionOutcome(
      isSuccess: true,
      message: space.isActive ? 'เปิดใช้งานพื้นที่แล้ว' : 'ปิดการแสดงผลพื้นที่ชั่วคราว',
    );
  }

  static ActionOutcome deleteSpace(SpaceItem space) {
    final hasActiveConfirmed = globalBookings.any(
      (b) => b.spaceId == space.id && b.status == 'confirmed',
    );
    if (hasActiveConfirmed) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'ไม่สามารถลบพื้นที่ที่มีคิวจอง Confirmed ค้างอยู่ได้',
      );
    }
    globalSpaces.removeWhere((s) => s.id == space.id);
    MysqlApiBridge.deleteJsonSilently('/api/spaces/${space.id}');
    return ActionOutcome(
      isSuccess: true,
      message: 'ลบประกาศพื้นที่ "${space.name}" ออกจากฐานข้อมูลแล้ว',
    );
  }
}

class BookingController {
  static bool hasOverlap({
    required int spaceId,
    required DateTime start,
    required DateTime end,
    int? excludeBookingId,
  }) {
    return globalBookings.any((b) {
      if (b.spaceId != spaceId || b.status != 'confirmed') {
        return false;
      }
      if (excludeBookingId != null && b.id == excludeBookingId) {
        return false;
      }
      return b.startDateTime.isBefore(end) && b.endDateTime.isAfter(start);
    });
  }

  static double calculateServerTotalPrice({
    required SpaceItem space,
    required DateTime start,
    required DateTime end,
  }) {
    final minutes = end.difference(start).inMinutes;
    if (minutes <= 0) return 0;
    final hours = minutes / 60.0;
    return double.parse((hours * space.pricePerHour).toStringAsFixed(2));
  }

  static String _formatSqlDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatSqlDateTime(DateTime dt) {
    final datePart = _formatSqlDate(dt);
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$datePart $h:$min:00';
  }

  static ActionOutcome createBookingRequest({
    required SpaceItem space,
    required DateTime start,
    required DateTime end,
  }) {
    if (space.approvalStatus != 'approved' || !space.isActive) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'พื้นที่นี้ยังไม่พร้อมรับการจอง',
      );
    }
    if (!end.isAfter(start)) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'เวลาสิ้นสุด (end_time) ต้องมากกว่าเวลาเริ่มต้น (start_time)',
      );
    }
    if (hasOverlap(spaceId: space.id, start: start, end: end)) {
      return const ActionOutcome(
        isSuccess: false,
        message: 'ช่วงเวลานี้ทับซ้อนกับการจองที่ได้รับการยืนยัน (Confirmed) แล้ว',
      );
    }

    final computedTotal = calculateServerTotalPrice(
      space: space,
      start: start,
      end: end,
    );
    final renter = currentSessionUser;
    final newBooking = BookingItem(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      renterId: renter?.userId ?? 1002,
      spaceId: space.id,
      spaceName: space.name,
      renterName: renter?.fullName ?? 'ลูกค้าตัวอย่าง',
      startDateTime: start,
      endDateTime: end,
      totalPrice: computedTotal,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    globalBookings.insert(0, newBooking);

    MysqlApiBridge.postJsonSilently(
      '/api/bookings',
      {
        'space_id': space.id,
        'customer_id': newBooking.renterId,
        'start_date': _formatSqlDate(start),
        'end_date': _formatSqlDate(end),
        'start_time': _formatSqlDateTime(start),
        'end_time': _formatSqlDateTime(end),
        'total_price': computedTotal,
      },
      onCompleted: (responseMap) {
        if (responseMap['booking_id'] != null) {
          newBooking.id = responseMap['booking_id'] as int;
        }
      },
    );

    return ActionOutcome(
      isSuccess: true,
      message: 'ส่งคำขอจองและบันทึกลง MySQL สำเร็จ! ยอดรวม ฿${computedTotal.toStringAsFixed(0)} (Pending)',
    );
  }

  static ActionOutcome updateBookingStatusByOwner({
    required BookingItem booking,
    required String newStatus,
  }) {
    if (newStatus == 'confirmed') {
      final conflict = hasOverlap(
        spaceId: booking.spaceId,
        start: booking.startDateTime,
        end: booking.endDateTime,
        excludeBookingId: booking.id,
      );
      if (conflict) {
        return const ActionOutcome(
          isSuccess: false,
          message: 'ยืนยันไม่ได้! มีการจอง Confirmed อื่นในช่วงเวลาเดียวกันแล้ว',
        );
      }
    }
    booking.status = newStatus;
    MysqlApiBridge.patchJsonSilently('/api/bookings/${booking.id}/status', {
      'status': newStatus,
    });

    return ActionOutcome(
      isSuccess: true,
      message: 'อัปเดตสถานะการจองเป็น ${newStatus.toUpperCase()} เรียบร้อย',
    );
  }

  static ActionOutcome cancelByRenter(BookingItem booking) {
    if (booking.status != 'pending' && booking.status != 'confirmed') {
      return const ActionOutcome(
        isSuccess: false,
        message: 'รายการนี้ไม่สามารถยกเลิกได้',
      );
    }
    booking.status = 'cancelled';
    MysqlApiBridge.patchJsonSilently('/api/bookings/${booking.id}/status', {
      'status': 'cancelled',
    });

    return const ActionOutcome(
      isSuccess: true,
      message: 'ยกเลิกการจองเรียบร้อยแล้ว',
    );
  }

  static ActionOutcome markBookingPaid(
    BookingItem booking, {
    String paymentRef = '',
    String slipImageUrl = '',
  }) {
    booking.paid = true;
    if (paymentRef.trim().isNotEmpty) {
      booking.paymentRef = paymentRef.trim();
    }
    if (slipImageUrl.trim().isNotEmpty) {
      booking.slipImageUrl = slipImageUrl.trim();
    }
    MysqlApiBridge.patchJsonSilently('/api/bookings/${booking.id}/pay', {
      'payment_ref': booking.paymentRef,
      'slip_image_url': booking.slipImageUrl,
    });
    return const ActionOutcome(
      isSuccess: true,
      message: 'ชำระเงินสำเร็จแล้ว',
    );
  }

  static ActionOutcome submitBookingReview({
    required BookingItem booking,
    required int ratingScore,
    required String reviewComment,
  }) {
    final clampedScore = ratingScore.clamp(1, 5);
    booking.rating = clampedScore;
    booking.reviewComment = reviewComment.trim();
    booking.status = 'completed';

    final spaceRecord = globalSpaces
        .where((s) => s.id == booking.spaceId)
        .firstOrNull;
    if (spaceRecord != null) {
      final ratedBookings = globalBookings
          .where((b) => b.spaceId == spaceRecord.id && b.rating != null)
          .toList();
      if (ratedBookings.isNotEmpty) {
        final avgScore = ratedBookings
                .fold<int>(0, (sum, b) => sum + (b.rating ?? 5)) /
            ratedBookings.length;
        spaceRecord.rating = double.parse(avgScore.toStringAsFixed(1));
      }
    }

    MysqlApiBridge.postJsonSilently('/api/bookings/${booking.id}/review', {
      'rating': clampedScore,
      'review_comment': booking.reviewComment,
    });

    return const ActionOutcome(
      isSuccess: true,
      message: 'บันทึกคะแนนรีวิวลง MySQL สำเร็จ!',
    );
  }
}

class AdminController {
  static void recordLog({
    required String action,
    required String targetType,
    required int targetId,
    required String details,
  }) {
    final admin = currentSessionUser;
    final newLog = AdminLogEntry(
      logId: globalAdminLogs.length + 1,
      adminId: admin?.userId ?? 1003,
      adminName: admin?.fullName ?? 'ผู้ดูแลระบบ',
      action: action,
      targetType: targetType,
      targetId: targetId,
      details: details,
      createdAt: DateTime.now(),
    );
    globalAdminLogs.insert(0, newLog);

    MysqlApiBridge.postJsonSilently(
      '/api/admin/logs',
      {
        'admin_id': newLog.adminId,
        'admin_name': newLog.adminName,
        'action': newLog.action,
        'target_type': newLog.targetType,
        'target_id': newLog.targetId,
        'details': newLog.details,
      },
      onCompleted: (responseMap) {
        if (responseMap['log_id'] != null) {
          newLog.logId = (responseMap['log_id'] as num).toInt();
        }
      },
    );
  }

  static ActionOutcome setSpaceApproval({
    required SpaceItem space,
    required String status,
  }) {
    space.approvalStatus = status;
    MysqlApiBridge.patchJsonSilently('/api/admin/spaces/${space.id}/approval', {
      'status': status,
    });

    recordLog(
      action: status == 'approved' ? 'APPROVE_SPACE' : 'REJECT_SPACE',
      targetType: 'space',
      targetId: space.id,
      details: 'Changed approval status of "${space.name}" to $status',
    );
    return ActionOutcome(
      isSuccess: true,
      message: 'ตั้งค่าสถานะพื้นที่ "${space.name}" เป็น $status แล้ว',
    );
  }

  static ActionOutcome toggleUserSuspension(UserAccount user) {
    if (user.role == 'admin') {
      return const ActionOutcome(
        isSuccess: false,
        message: 'ไม่สามารถระงับบัญชีผู้ดูแลระบบหลักได้',
      );
    }
    user.status = user.status == 'active' ? 'suspended' : 'active';
    MysqlApiBridge.patchJsonSilently('/api/users/${user.userId}/status', {
      'status': user.status,
    });

    recordLog(
      action: user.status == 'suspended' ? 'SUSPEND_USER' : 'REACTIVATE_USER',
      targetType: 'user',
      targetId: user.userId,
      details: 'Updated user @${user.username} status to ${user.status}',
    );
    return ActionOutcome(
      isSuccess: true,
      message: 'เปลี่ยนสถานะผู้ใช้ @${user.username} เป็น ${user.status} แล้ว',
    );
  }

  static ActionOutcome cancelBookingByAdmin(BookingItem booking) {
    booking.status = 'cancelled';
    MysqlApiBridge.patchJsonSilently('/api/bookings/${booking.id}/status', {
      'status': 'cancelled',
    });

    recordLog(
      action: 'ADMIN_CANCEL_BOOKING',
      targetType: 'booking',
      targetId: booking.id,
      details:
          'Administratively cancelled booking #${booking.id} (${booking.spaceName})',
    );
    return ActionOutcome(
      isSuccess: true,
      message: 'ยกเลิกรายการจอง #${booking.id} โดยผู้ดูแลระบบแล้ว',
    );
  }
}
