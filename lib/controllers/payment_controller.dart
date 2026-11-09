import 'dart:typed_data';

import '../data/app_store.dart';
import '../models/domain.dart';
import 'booking_controller.dart';

class PaymentController {
  PaymentController(this.store);
  final AppStore store;
  static const maxBytes = 5 * 1024 * 1024;
  static void validateSlip(String name, Uint8List bytes) {
    final extension = name.split('.').last.toLowerCase();
    final png =
        bytes.length >= 8 &&
        [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ].asMap().entries.every((e) => bytes[e.key] == e.value);
    final jpg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw DomainError('ภาพต้องมีขนาดมากกว่า 0 และไม่เกิน 5 MB');
    }
    if (!((extension == 'png' && png) ||
        (['jpg', 'jpeg'].contains(extension) && jpg))) {
      throw DomainError('รองรับภาพ JPG และ PNG เท่านั้น');
    }
  }

  void submit(String id, String name, Uint8List bytes, String note) {
    final u = store.requireUser(UserRole.renter), b = store.booking(id);
    BookingController(store).sweep();
    if (b.renterId != u.id ||
        ![
          BookingStatus.paymentDue,
          BookingStatus.slipRejected,
        ].contains(b.status)) {
      throw DomainError('รายการนี้ยังไม่พร้อมส่งสลิป');
    }
    validateSlip(name, bytes);
    if (!b.startsAt.isAfter(store.clock())) {
      throw DomainError('เลยเวลาเริ่มจองแล้ว กรุณาติดต่อ Admin');
    }
    if (store.conflicts(
      b.spaceId,
      b.date,
      b.startMinutes,
      b.endMinutes,
      days: b.days,
      excluding: b.id,
    )) {
      throw DomainError('เวลาจองซ้อน กรุณาติดต่อ Admin');
    }
    b.slips.add(
      PaymentSlip(
        name: name,
        bytes: bytes,
        note: note.trim(),
        submittedAt: store.clock(),
      ),
    );
    b.status = BookingStatus.slipReview;
    b.slipRejectedAt = null;
    b.reason = '';
    store.changed('${b.id}: ส่งสลิปครั้งที่ ${b.slips.length}');
  }

  void review(String id, bool approve, String reason) {
    store.requireUser(UserRole.admin);
    final booking = store.booking(id);
    BookingController(store).sweep();
    final slip = _requirePendingSlip(booking);
    final now = store.clock();
    if (approve) {
      _applyApproval(booking, now);
    } else {
      _applyRejection(booking, reason, now);
    }
    slip.rejectionReason = booking.reason;
    store.changed('${booking.id}: ${booking.status.label}');
  }

  PaymentSlip _requirePendingSlip(Booking booking) {
    final slip = booking.latestSlip;
    if (booking.status != BookingStatus.slipReview || slip == null) {
      throw DomainError('ไม่มีสลิปที่รอตรวจ');
    }
    return slip;
  }

  void _applyApproval(Booking booking, DateTime now) {
    if (!booking.startsAt.isAfter(now)) {
      throw DomainError('เลยเวลาเริ่มจองแล้ว กรุณาจัดการยกเลิกและตรวจยอดโอน');
    }
    if (store.conflicts(
      booking.spaceId,
      booking.date,
      booking.startMinutes,
      booking.endMinutes,
      days: booking.days,
      excluding: booking.id,
    )) {
      throw DomainError('มีรายการจองซ้อน ไม่สามารถยืนยัน');
    }
    booking.status = BookingStatus.confirmed;
    booking.confirmedAt = now;
    booking.slipRejectedAt = null;
    booking.reason = '';
  }

  void _applyRejection(Booking booking, String reason, DateTime now) {
    if (reason.trim().isEmpty) {
      throw DomainError('กรุณาระบุเหตุผลที่สลิปไม่ผ่าน');
    }
    booking.status = BookingStatus.slipRejected;
    booking.slipRejectedAt = now;
    booking.reason = reason.trim();
  }

  void payout(String id) {
    store.requireUser(UserRole.admin);
    final b = store.booking(id);
    BookingController(store).sweep();
    if (b.status != BookingStatus.completed || b.paidOutAt != null) {
      throw DomainError('รายการนี้ยังจ่ายไม่ได้หรือจ่ายแล้ว');
    }
    b.paidOutAt = store.clock();
    store.changed('${b.id}: บันทึกจ่ายเจ้าของจำลอง ฿${b.ownerNet}');
  }
}
