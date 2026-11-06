class Booking {
  Booking({
    required this.id,
    required this.spaceName,
    required this.renterName,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.rentAmount,
    this.status = BookingStatus.ownerReview,
    this.slipName,
  });

  final String id;
  final String spaceName;
  final String renterName;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final int rentAmount;
  String status;
  String? slipName;

  int get platformFee => (rentAmount * 0.05).round();
  int get ownerNet => rentAmount - platformFee;

  String get dateLabel => '${date.day} ${_month(date.month)} ${date.year}';
  String get timeLabel => '${_time(startMinutes)}–${_time(endMinutes)}';

  static String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  static String _month(int month) => const [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ][month - 1];
}

abstract final class BookingStatus {
  static const ownerReview = 'รอเจ้าของอนุมัติ';
  static const paymentDue = 'รอชำระเงิน';
  static const slipReview = 'รอตรวจสลิป';
  static const confirmed = 'ยืนยันแล้ว';
  static const slipRejected = 'สลิปไม่ผ่าน';
  static const ownerRejected = 'เจ้าของปฏิเสธ';
  static const completed = 'เสร็จสิ้น';
  static const canceled = 'ยกเลิกแล้ว';
}
