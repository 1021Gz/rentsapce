import '../data/app_store.dart';
import '../models/domain.dart';

class BookingController {
  BookingController(this.store);
  final AppStore store;
  static const minDurationMinutes = 60;
  static const maxDurationMinutes = 12 * 60;
  static const maxBookingDays = 14;

  static String? durationError(int start, int end) {
    if (start < 0 || end > 1440 || end <= start) {
      return 'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม';
    }
    final minutes = end - start;
    if (minutes < minDurationMinutes) {
      return 'จองขั้นต่ำ $minDurationMinutes นาที';
    }
    if (minutes > maxDurationMinutes) {
      return 'จองได้ไม่เกิน ${maxDurationMinutes ~/ 60} ชั่วโมงต่อครั้ง';
    }
    return null;
  }

  static void validateDuration(int start, int end) {
    final message = durationError(start, end);
    if (message != null) throw DomainError(message);
  }

  static int rent(int price, int start, int end, {int days = 1}) {
    if (price <= 0 || start < 0 || end > 1440 || end <= start || days < 1) {
      throw DomainError('ราคาและช่วงเวลาไม่ถูกต้อง');
    }
    return price * ((end - start) / 60).ceil() * days;
  }

  List<(int, int)> hourlySlots(Space space, DateTime date) {
    final day = space.availability.days[date.weekday - 1];
    if (!day.open) return const [];
    return [
      for (var minute = day.start; minute + 60 <= day.end; minute += 60)
        (minute, minute + 60),
    ];
  }

  bool isSlotAvailable(
    String spaceId,
    DateTime date,
    int start,
    int end, {
    int days = 1,
  }) {
    if (days < 1 || days > maxBookingDays) return false;
    final space = store.space(spaceId);
    return atMinute(date, start).isAfter(store.clock()) &&
        space.availability.acceptsRange(date, start, end, days: days) &&
        !store.conflicts(spaceId, date, start, end, days: days);
  }

  List<String> busySlotLabels(String spaceId, DateTime date) {
    final targetDay = dateOnly(date);
    final booked =
        store.bookings
            .where(
              (b) =>
                  b.spaceId == spaceId &&
                  b.status.holdsTime &&
                  b.coversDate(targetDay),
            )
            .toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return [
      for (final b in booked)
        'คิวจอง ${timeLabel(b.startMinutes)}–${timeLabel(b.endMinutes)}${b.days > 1 ? ' (${b.days} วัน)' : ''}',
      ..._blockedLabelsOnDate(store.space(spaceId), targetDay),
    ];
  }

  List<String> _blockedLabelsOnDate(Space space, DateTime targetDay) {
    final dayEnd = targetDay.add(const Duration(days: 1));
    return [
      for (final block in space.availability.blocks)
        if (block.start.isBefore(dayEnd) && block.end.isAfter(targetDay))
          'ปิดพื้นที่ (${block.reason})',
    ];
  }

  (int, int) selectOrExtendSlot({
    required String spaceId,
    required DateTime date,
    required int currentStart,
    required int currentEnd,
    required int slotStart,
    required int slotEnd,
  }) {
    if (slotStart == currentEnd &&
        _canSelectRange(spaceId, date, currentStart, slotEnd)) {
      return (currentStart, slotEnd);
    }
    if (slotEnd == currentStart &&
        _canSelectRange(spaceId, date, slotStart, currentEnd)) {
      return (slotStart, currentEnd);
    }
    return (slotStart, slotEnd);
  }

  bool _canSelectRange(String spaceId, DateTime date, int start, int end) =>
      durationError(start, end) == null &&
      isSlotAvailable(spaceId, date, start, end);

  /// ยกเลิกอัตโนมัติเมื่อเลยกำหนด และจบรายการที่ยืนยันแล้วเมื่อเลยเวลาสิ้นสุด
  void sweep() {
    final now = store.clock();
    for (final booking in store.bookings) {
      _sweepBooking(booking, now);
    }
  }

  void _sweepBooking(Booking booking, DateTime now) {
    final expirationReason = _expirationReason(booking, now);
    if (expirationReason != null) {
      _expire(booking, expirationReason);
      return;
    }
    if (booking.status == BookingStatus.confirmed &&
        now.isAfter(booking.autoCompleteAt)) {
      booking.status = BookingStatus.completed;
      booking.completedAt = now;
      store.changed(
        '${booking.id}: จบรายการอัตโนมัติหลังสิ้นสุดเวลา',
        actor: 'ระบบ',
      );
    }
  }

  String? _expirationReason(Booking booking, DateTime now) =>
      switch (booking.status) {
        BookingStatus.ownerReview
            when _isPastDeadline(
              booking.startsAt,
              booking.ownerResponseDeadline,
              now,
            ) =>
          'หมดเวลาตอบรับจากเจ้าของ',
        BookingStatus.paymentDue
            when _isPastDeadline(
              booking.startsAt,
              booking.paymentDeadline,
              now,
            ) =>
          'ไม่ชำระเงินภายในกำหนด',
        BookingStatus.slipRejected
            when _isPastDeadline(
              booking.startsAt,
              booking.slipResubmitDeadline,
              now,
            ) =>
          'ไม่ส่งสลิปใหม่ภายในกำหนด',
        _ => null,
      };

  bool _isPastDeadline(DateTime startsAt, DateTime? deadline, DateTime now) =>
      !startsAt.isAfter(now) || (deadline != null && now.isAfter(deadline));

  void _expire(Booking b, String reason) {
    b.status = BookingStatus.canceled;
    b.reason = reason;
    store.changed('${b.id}: ยกเลิกอัตโนมัติ ($reason)', actor: 'ระบบ');
  }

  Booking create(
    String spaceId,
    DateTime date,
    int start,
    int end, {
    int days = 1,
    int attendees = 1,
    String zone = 'โซนหลัก (พื้นที่มาตรฐาน)',
    String renterNote = '',
  }) {
    final u = store.requireUser(UserRole.renter), s = store.space(spaceId);
    if (days < 1 || days > maxBookingDays) {
      throw DomainError('จองต่อเนื่องได้ 1–$maxBookingDays วัน');
    }
    if (attendees < 1 || attendees > s.capacity) {
      throw DomainError(
        'จำนวนผู้เข้าใช้งานต้องอยู่ระหว่าง 1–${s.capacity} ท่าน',
      );
    }
    validateDuration(start, end);
    sweep();
    final amount = rent(s.price, start, end, days: days);
    _validateCreateSlot(s, date, start, end, days);
    final normalizedZone = zone.trim().isEmpty
        ? 'โซนหลัก (พื้นที่มาตรฐาน)'
        : zone.trim();
    final b = Booking(
      id: store.nextId('RS'),
      spaceId: s.id,
      ownerId: s.ownerId,
      renterId: u.id,
      spaceName: s.name,
      date: dateOnly(date),
      startMinutes: start,
      endMinutes: end,
      rentAmount: amount,
      days: days,
      attendees: attendees,
      zone: normalizedZone,
      renterNote: renterNote.trim(),
    );
    b.createdAt = store.clock();
    store.bookings.insert(0, b);
    store.changed('สร้างคำขอจอง ${b.id}');
    return b;
  }

  void _validateCreateSlot(
    Space space,
    DateTime date,
    int start,
    int end,
    int days,
  ) {
    if (space.status != SpaceStatus.approved ||
        !store.user(space.ownerId).active) {
      throw DomainError('พื้นที่นี้ยังไม่เปิดรับจอง');
    }
    if (!atMinute(date, start).isAfter(store.clock())) {
      throw DomainError('ต้องเลือกเวลาในอนาคต');
    }
    if (!space.availability.acceptsRange(date, start, end, days: days)) {
      throw DomainError('อยู่นอกเวลาเปิดหรือเป็นช่วงปิด');
    }
    if (store.conflicts(space.id, date, start, end, days: days)) {
      throw DomainError('ช่วงเวลานี้มีการจองแล้ว');
    }
  }

  void ownerReview(String id, bool approve, String reason) {
    final u = store.requireUser(UserRole.owner), b = store.booking(id);
    sweep();
    if (b.ownerId != u.id || b.status != BookingStatus.ownerReview) {
      throw DomainError('ไม่สามารถตรวจคำขอนี้ได้');
    }
    if (!approve && reason.trim().isEmpty) throw DomainError('กรุณาระบุเหตุผล');
    if (approve && !b.startsAt.isAfter(store.clock())) {
      throw DomainError('คำขอนี้เลยเวลาเริ่มแล้ว กรุณาปฏิเสธ');
    }
    if (approve &&
        store.conflicts(
          b.spaceId,
          b.date,
          b.startMinutes,
          b.endMinutes,
          days: b.days,
          excluding: b.id,
        )) {
      throw DomainError('เวลาจองซ้อน');
    }
    b.status = approve ? BookingStatus.paymentDue : BookingStatus.ownerRejected;
    if (approve) b.approvedAt = store.clock();
    b.reason = reason.trim();
    store.changed('${b.id}: ${b.status.label}');
  }

  void cancel(String id, String reason) {
    final u = store.requireUser(), b = store.booking(id);
    sweep();
    if (reason.trim().isEmpty) throw DomainError('กรุณาระบุเหตุผลยกเลิก');
    final unpaid = [
      BookingStatus.ownerReview,
      BookingStatus.paymentDue,
      BookingStatus.slipRejected,
    ];
    if (u.role == UserRole.admin) {
      if ([
        BookingStatus.completed,
        BookingStatus.canceled,
        BookingStatus.ownerRejected,
      ].contains(b.status)) {
        throw DomainError('ไม่สามารถยกเลิกสถานะนี้');
      }
    } else if (u.role != UserRole.renter ||
        b.renterId != u.id ||
        !unpaid.contains(b.status)) {
      throw DomainError('รายการที่ชำระเงินหรือรอตรวจสลิปต้องให้ Admin จัดการ');
    }
    b.status = BookingStatus.canceled;
    b.reason = reason.trim();
    store.changed('${b.id}: ยกเลิก');
  }

  void complete(String id) {
    final u = store.requireUser(UserRole.owner), b = store.booking(id);
    sweep();
    if (b.status == BookingStatus.completed) {
      throw DomainError('รายการนี้จบแล้ว');
    }
    if (b.ownerId != u.id || b.status != BookingStatus.confirmed) {
      throw DomainError('ไม่สามารถจบรายการนี้ได้');
    }
    if (store.clock().isBefore(b.endsAt)) {
      throw DomainError('ต้องรอจนสิ้นสุดเวลาใช้บริการ');
    }
    b.status = BookingStatus.completed;
    b.completedAt = store.clock();
    store.changed('${b.id}: ใช้บริการเสร็จสิ้น');
  }

  void submitReview(String bookingId, int rating, String comment) {
    final u = store.requireUser(UserRole.renter), b = store.booking(bookingId);
    if (b.renterId != u.id || b.status != BookingStatus.completed) {
      throw DomainError('รีวิวได้เฉพาะรายการที่คุณใช้งานเสร็จสิ้นแล้ว');
    }
    if (b.review != null) throw DomainError('รายการนี้ส่งรีวิวไปแล้ว');
    _validateReviewInput(rating, comment);
    b.review = SpaceReview(
      rating: rating,
      comment: comment.trim(),
      createdAt: store.clock(),
    );
    store.changed('${b.id}: รีวิวพื้นที่ $rating ดาว');
  }

  void _validateReviewInput(int rating, String comment) {
    if (rating < 1 || rating > 5 || comment.trim().isEmpty) {
      throw DomainError('กรุณาเลือกคะแนน 1–5 ดาว และระบุความคิดเห็น');
    }
  }
}
