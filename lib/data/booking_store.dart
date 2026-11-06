import '../models/booking.dart';

/// In-memory shared state for the clickable frontend prototype.
class BookingStore {
  BookingStore._();

  static final instance = BookingStore._();
  final List<Booking> bookings = [];
  final List<Booking> slipReviewQueue = [];

  bool hasTimeConflict({
    required String spaceName,
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
  }) => bookings.any((booking) {
    if (booking.spaceName != spaceName ||
        booking.date.year != date.year ||
        booking.date.month != date.month ||
        booking.date.day != date.day ||
        booking.status == BookingStatus.ownerRejected ||
        booking.status == BookingStatus.slipRejected ||
        booking.status == BookingStatus.canceled) {
      return false;
    }
    return startMinutes < booking.endMinutes &&
        endMinutes > booking.startMinutes;
  });

  void add(Booking booking) {
    bookings.insert(0, booking);
  }

  List<Booking> get ownerInbox => bookings
      .where((b) => b.status == BookingStatus.ownerReview)
      .toList(growable: false);

  List<Booking> get pendingSlips => bookings
      .where((b) => b.status == BookingStatus.slipReview)
      .toList(growable: false);

  List<Booking> get ownerPayable => bookings
      .where((b) => b.status == BookingStatus.completed)
      .toList(growable: false);
}
