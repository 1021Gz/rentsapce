import 'dart:typed_data';

enum UserRole { renter, owner, admin }

extension RoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.renter => 'ผู้เช่า',
    UserRole.owner => 'เจ้าของพื้นที่',
    UserRole.admin => 'ผู้ดูแลระบบ',
  };
}

enum SpaceStatus { pending, approved, rejected }

enum SpaceSort { recommended, priceAsc, priceDesc, capacityDesc }

extension SpaceSortLabel on SpaceSort {
  String get label => switch (this) {
    SpaceSort.recommended => 'แนะนำ',
    SpaceSort.priceAsc => 'ราคาต่ำ→สูง',
    SpaceSort.priceDesc => 'ราคาสูง→ต่ำ',
    SpaceSort.capacityDesc => 'ความจุมาก→น้อย',
  };
}

extension SpaceLabel on SpaceStatus {
  String get label => switch (this) {
    SpaceStatus.pending => 'รอตรวจประกาศ',
    SpaceStatus.approved => 'อนุมัติแล้ว',
    SpaceStatus.rejected => 'ไม่ผ่านการตรวจ',
  };
}

enum BookingStatus {
  ownerReview,
  paymentDue,
  slipReview,
  confirmed,
  slipRejected,
  ownerRejected,
  completed,
  canceled,
}

extension BookingLabel on BookingStatus {
  String get label => switch (this) {
    BookingStatus.ownerReview => 'รอเจ้าของอนุมัติ',
    BookingStatus.paymentDue => 'รอชำระเงิน',
    BookingStatus.slipReview => 'รอตรวจสลิป',
    BookingStatus.confirmed => 'ยืนยันแล้ว',
    BookingStatus.slipRejected => 'สลิปไม่ผ่าน',
    BookingStatus.ownerRejected => 'เจ้าของปฏิเสธ',
    BookingStatus.completed => 'เสร็จสิ้น',
    BookingStatus.canceled => 'ยกเลิกแล้ว',
  };
  bool get holdsTime =>
      this != BookingStatus.ownerRejected && this != BookingStatus.canceled;
  int get progressStep => switch (this) {
    BookingStatus.ownerReview ||
    BookingStatus.ownerRejected ||
    BookingStatus.canceled => 0,
    BookingStatus.paymentDue || BookingStatus.slipRejected => 1,
    BookingStatus.slipReview => 2,
    BookingStatus.confirmed || BookingStatus.completed => 3,
  };
}

/// เจ้าของต้องตอบรับคำขอ และผู้เช่าต้องชำระเงินภายใน 24 ชั่วโมง
const ownerResponseWindow = Duration(hours: 24);
const paymentWindow = Duration(hours: 24);
const slipResubmitWindow = Duration(hours: 24);

/// รายการที่ยืนยันแล้วจะจบอัตโนมัติเมื่อเลยเวลาสิ้นสุด 24 ชั่วโมง
const autoCompleteWindow = Duration(hours: 24);

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone = '',
    this.bankInfo = '',
    this.active = true,
  });
  final String id;
  final UserRole role;
  String name, email, phone, bankInfo, password;
  bool active;
  final Set<String> favorites = {};
  String get phoneLabel => phone.trim().isEmpty ? 'ไม่ระบุ' : phone.trim();
}

class DayHours {
  DayHours({this.open = true, this.start = 540, this.end = 1080});
  bool open;
  int start, end;
  DayHours copy() => DayHours(open: open, start: start, end: end);
}

class BlockedPeriod {
  BlockedPeriod({
    required this.id,
    required this.start,
    required this.end,
    required this.reason,
  });
  final String id, reason;
  final DateTime start, end;
}

class Availability {
  Availability({List<DayHours>? days, List<BlockedPeriod>? blocks})
    : days = days ?? List.generate(7, (_) => DayHours()),
      blocks = blocks ?? [];
  final List<DayHours> days;
  final List<BlockedPeriod> blocks;
  Availability copy() => Availability(
    days: days.map((d) => d.copy()).toList(),
    blocks: [...blocks],
  );
  bool accepts(DateTime date, int start, int end) {
    if (start < 0 || end > 1440 || end <= start) return false;
    final day = days[date.weekday - 1];
    final from = atMinute(date, start), to = atMinute(date, end);
    return day.open &&
        start >= day.start &&
        end <= day.end &&
        !blocks.any((b) => from.isBefore(b.end) && to.isAfter(b.start));
  }

  bool acceptsRange(DateTime date, int start, int end, {int days = 1}) {
    if (days < 1 || days > 30) return false;
    for (var i = 0; i < days; i++) {
      if (!accepts(dateOnly(date).add(Duration(days: i)), start, end)) {
        return false;
      }
    }
    return true;
  }
}

class Space {
  Space({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.location,
    required this.price,
    required this.capacity,
    required this.description,
    this.image = '',
    List<String>? amenities,
    this.status = SpaceStatus.pending,
    Availability? availability,
  }) : amenities = amenities ?? [],
       availability = availability ?? Availability();
  final String id, ownerId;
  String name, category, location, description, image;
  int price, capacity;
  List<String> amenities;
  SpaceStatus status;
  String reviewReason = '';
  Availability availability;
}

class PaymentSlip {
  PaymentSlip({
    required this.name,
    required Uint8List bytes,
    required this.submittedAt,
    this.note = '',
  }) : bytes = Uint8List.fromList(bytes);
  final String name, note;
  final Uint8List bytes;
  final DateTime submittedAt;
  String rejectionReason = '';
}

class SpaceReview {
  SpaceReview({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
  final int rating;
  final String comment;
  final DateTime createdAt;
}

class Booking {
  Booking({
    required this.id,
    required this.spaceId,
    required this.ownerId,
    required this.renterId,
    required this.spaceName,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.rentAmount,
    this.days = 1,
    this.attendees = 1,
    this.zone = 'โซนหลัก (พื้นที่มาตรฐาน)',
    this.renterNote = '',
    this.status = BookingStatus.ownerReview,
    this.review,
  });
  final String id, spaceId, ownerId, renterId, spaceName, zone, renterNote;
  final DateTime date;
  final int startMinutes, endMinutes, rentAmount, days, attendees;
  BookingStatus status;
  SpaceReview? review;
  final List<PaymentSlip> slips = [];
  PaymentSlip? get latestSlip => slips.isEmpty ? null : slips.last;
  String reason = '';
  DateTime? paidOutAt;
  DateTime? createdAt, approvedAt, slipRejectedAt, confirmedAt, completedAt;
  DateTime? get ownerResponseDeadline => createdAt?.add(ownerResponseWindow);
  DateTime? get paymentDeadline => approvedAt?.add(paymentWindow);
  DateTime? get slipResubmitDeadline =>
      slipRejectedAt?.add(slipResubmitWindow);
  DateTime? get effectiveSlipResubmitDeadline {
    final deadline = slipResubmitDeadline;
    if (deadline == null) return null;
    return startsAt.isBefore(deadline) ? startsAt : deadline;
  }
  DateTime get endDate => dateOnly(date).add(Duration(days: days - 1));
  DateTime get autoCompleteAt => endsAt.add(autoCompleteWindow);
  int get platformFee => (rentAmount * 5 / 100).round();
  int get ownerNet => rentAmount - platformFee;
  DateTime get startsAt => atMinute(date, startMinutes);
  DateTime get endsAt => atMinute(endDate, endMinutes);
  bool coversDate(DateTime target) {
    final d = dateOnly(target), from = dateOnly(date), to = endDate;
    return !d.isBefore(from) && !d.isAfter(to);
  }
}

class Issue {
  Issue({
    required this.id,
    required this.reporterId,
    required this.subject,
    required this.detail,
  });
  final String id, reporterId, subject, detail;
  bool closed = false;
  String resolution = '';
}

class AuditEntry {
  AuditEntry(this.at, this.actor, this.action);
  final DateTime at;
  final String actor, action;
}

class DomainError implements Exception {
  DomainError(this.message);
  final String message;
  @override
  String toString() => message;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime atMinute(DateTime d, int m) => dateOnly(d).add(Duration(minutes: m));
String dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';
String timeLabel(int m) =>
    '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
String dateTimeLabel(DateTime d) =>
    '${dateLabel(d)} ${timeLabel(d.hour * 60 + d.minute)}';
String bookingWhen(Booking b) => b.days > 1
    ? '${dateLabel(b.date)}–${dateLabel(b.endDate)} (${b.days} วัน) · ${timeLabel(b.startMinutes)}–${timeLabel(b.endMinutes)}'
    : '${dateLabel(b.date)} · ${timeLabel(b.startMinutes)}–${timeLabel(b.endMinutes)}';
