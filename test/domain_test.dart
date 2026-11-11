import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentspace/models/domain.dart';

// ─── Helper: build a minimal Booking ─────────────────────────────────────────
Booking makeBooking({
  String id = 'b-1',
  DateTime? date,
  int startMinutes = 600,
  int endMinutes = 720,
  int rentAmount = 1000,
  int days = 1,
  BookingStatus status = BookingStatus.ownerReview,
}) =>
    Booking(
      id: id,
      spaceId: 's-1',
      ownerId: 'o-1',
      renterId: 'r-1',
      spaceName: 'Test Space',
      date: date ?? DateTime(2026, 11, 10), // Monday
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      rentAmount: rentAmount,
      days: days,
      status: status,
    );

void main() {
  // ─── Enum labels ────────────────────────────────────────────────────────────
  group('UserRole labels', () {
    test('every role has a non-empty label', () {
      for (final r in UserRole.values) {
        expect(r.label, isNotEmpty);
      }
    });
    test('correct Thai labels', () {
      expect(UserRole.renter.label, 'ผู้เช่า');
      expect(UserRole.owner.label, 'เจ้าของพื้นที่');
      expect(UserRole.admin.label, 'ผู้ดูแลระบบ');
    });
  });

  group('SpaceStatus labels', () {
    test('every status has a non-empty label', () {
      for (final s in SpaceStatus.values) {
        expect(s.label, isNotEmpty);
      }
    });
    test('correct Thai labels', () {
      expect(SpaceStatus.pending.label, 'รอตรวจประกาศ');
      expect(SpaceStatus.approved.label, 'อนุมัติแล้ว');
      expect(SpaceStatus.rejected.label, 'ไม่ผ่านการตรวจ');
    });
  });

  group('SpaceSort labels', () {
    test('every sort option has a non-empty label', () {
      for (final s in SpaceSort.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  // ─── BookingStatus ──────────────────────────────────────────────────────────
  group('BookingStatus.holdsTime', () {
    test('true for active statuses', () {
      const active = [
        BookingStatus.ownerReview,
        BookingStatus.paymentDue,
        BookingStatus.slipReview,
        BookingStatus.confirmed,
        BookingStatus.slipRejected,
        BookingStatus.completed,
      ];
      for (final s in active) {
        expect(s.holdsTime, isTrue, reason: '${s.name} should hold time');
      }
    });

    test('false only for ownerRejected and canceled', () {
      expect(BookingStatus.ownerRejected.holdsTime, isFalse);
      expect(BookingStatus.canceled.holdsTime, isFalse);
    });
  });

  group('BookingStatus.progressStep', () {
    test('step 0: ownerReview, ownerRejected, canceled', () {
      expect(BookingStatus.ownerReview.progressStep, 0);
      expect(BookingStatus.ownerRejected.progressStep, 0);
      expect(BookingStatus.canceled.progressStep, 0);
    });
    test('step 1: paymentDue, slipRejected', () {
      expect(BookingStatus.paymentDue.progressStep, 1);
      expect(BookingStatus.slipRejected.progressStep, 1);
    });
    test('step 2: slipReview', () {
      expect(BookingStatus.slipReview.progressStep, 2);
    });
    test('step 3: confirmed, completed', () {
      expect(BookingStatus.confirmed.progressStep, 3);
      expect(BookingStatus.completed.progressStep, 3);
    });
  });

  group('BookingStatus labels', () {
    test('every status has a non-empty label', () {
      for (final s in BookingStatus.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  // ─── Time window constants ───────────────────────────────────────────────────
  group('Window constants', () {
    test('all business windows are 24 hours', () {
      expect(ownerResponseWindow, const Duration(hours: 24));
      expect(paymentWindow, const Duration(hours: 24));
      expect(slipResubmitWindow, const Duration(hours: 24));
      expect(autoCompleteWindow, const Duration(hours: 24));
    });
  });

  // ─── AppUser ─────────────────────────────────────────────────────────────────
  group('AppUser', () {
    test('phoneLabel returns number when set', () {
      final u = AppUser(
        id: 'u1', name: 'Ann', email: 'a@b.com',
        password: 'x', role: UserRole.renter, phone: '0812345678',
      );
      expect(u.phoneLabel, '0812345678');
    });

    test('phoneLabel returns placeholder when empty', () {
      final u = AppUser(
        id: 'u1', name: 'Ann', email: 'a@b.com',
        password: 'x', role: UserRole.renter, phone: '',
      );
      expect(u.phoneLabel, 'ไม่ระบุ');
    });

    test('phoneLabel trims whitespace', () {
      final u = AppUser(
        id: 'u1', name: 'Ann', email: 'a@b.com',
        password: 'x', role: UserRole.renter, phone: '  ',
      );
      expect(u.phoneLabel, 'ไม่ระบุ');
    });

    test('favorites set starts empty', () {
      final u = AppUser(
        id: 'u1', name: 'Ann', email: 'a@b.com',
        password: 'x', role: UserRole.renter,
      );
      expect(u.favorites, isEmpty);
    });

    test('active defaults to true', () {
      final u = AppUser(
        id: 'u1', name: 'Ann', email: 'a@b.com',
        password: 'x', role: UserRole.renter,
      );
      expect(u.active, isTrue);
    });
  });

  // ─── DayHours ────────────────────────────────────────────────────────────────
  group('DayHours', () {
    test('defaults: open, 09:00–18:00 (540–1080)', () {
      final d = DayHours();
      expect(d.open, isTrue);
      expect(d.start, 540);
      expect(d.end, 1080);
    });

    test('copy produces independent object', () {
      final d = DayHours(open: false, start: 480, end: 960);
      final c = d.copy();
      c.open = true;
      c.start = 600;
      expect(d.open, isFalse);
      expect(d.start, 480);
    });
  });

  // ─── Availability.accepts ────────────────────────────────────────────────────
  group('Availability.accepts', () {
    // Monday 2026-11-09, default hours 09:00–18:00 (540–1080)
    final monday = DateTime(2026, 11, 9);

    test('accepts slot within opening hours', () {
      final av = Availability();
      expect(av.accepts(monday, 600, 720), isTrue);
    });

    test('rejects slot outside opening hours (too early)', () {
      final av = Availability();
      expect(av.accepts(monday, 480, 600), isFalse);
    });

    test('rejects slot outside opening hours (too late)', () {
      final av = Availability();
      expect(av.accepts(monday, 1020, 1140), isFalse);
    });

    test('rejects when day is closed', () {
      final av = Availability();
      av.days[0].open = false; // Monday closed
      expect(av.accepts(monday, 600, 720), isFalse);
    });

    test('rejects reversed interval', () {
      final av = Availability();
      expect(av.accepts(monday, 720, 600), isFalse);
    });

    test('rejects zero-length interval', () {
      final av = Availability();
      expect(av.accepts(monday, 600, 600), isFalse);
    });

    test('rejects negative start', () {
      final av = Availability();
      expect(av.accepts(monday, -1, 600), isFalse);
    });

    test('rejects end > 1440', () {
      final av = Availability();
      expect(av.accepts(monday, 600, 1441), isFalse);
    });

    test('rejects slot overlapping a blocked period', () {
      final av = Availability(blocks: [
        BlockedPeriod(
          id: 'bp1',
          start: atMinute(monday, 600),
          end: atMinute(monday, 720),
          reason: 'Maintenance',
        ),
      ]);
      expect(av.accepts(monday, 600, 720), isFalse);
      expect(av.accepts(monday, 650, 720), isFalse); // partial overlap
    });

    test('accepts slot adjacent to but not overlapping a blocked period', () {
      final av = Availability(blocks: [
        BlockedPeriod(
          id: 'bp1',
          start: atMinute(monday, 720),
          end: atMinute(monday, 840),
          reason: 'Maintenance',
        ),
      ]);
      expect(av.accepts(monday, 600, 720), isTrue); // ends exactly when block starts
    });
  });

  // ─── Availability.acceptsRange ───────────────────────────────────────────────
  group('Availability.acceptsRange', () {
    final monday = DateTime(2026, 11, 9);

    test('single day same as accepts', () {
      final av = Availability();
      expect(av.acceptsRange(monday, 600, 720), isTrue);
    });

    test('multi-day: all days must be open', () {
      final av = Availability();
      av.days[2].open = false; // Wednesday closed
      // Mon-Wed (3 days) → should fail
      expect(av.acceptsRange(monday, 600, 720, days: 3), isFalse);
      // Mon-Tue (2 days) → should pass
      expect(av.acceptsRange(monday, 600, 720, days: 2), isTrue);
    });

    test('rejects days < 1', () {
      expect(Availability().acceptsRange(monday, 600, 720, days: 0), isFalse);
    });

    test('rejects days > 30', () {
      expect(Availability().acceptsRange(monday, 600, 720, days: 31), isFalse);
    });
  });

  // ─── Availability.copy ───────────────────────────────────────────────────────
  group('Availability.copy', () {
    test('mutating copy does not affect original', () {
      final av = Availability();
      final cp = av.copy();
      cp.days[0].open = false;
      expect(av.days[0].open, isTrue);
    });
  });

  // ─── Booking computed properties ─────────────────────────────────────────────
  group('Booking.platformFee & ownerNet', () {
    test('5% fee rounds correctly', () {
      // 1000 * 5% = 50
      final b = makeBooking(rentAmount: 1000);
      expect(b.platformFee, 50);
      expect(b.ownerNet, 950);
    });

    test('fee rounds half-up on fractional result', () {
      // 1001 * 5% = 50.05 → rounds to 50
      final b = makeBooking(rentAmount: 1001);
      expect(b.platformFee, 50);
      expect(b.ownerNet, 951);
    });

    test('fee + ownerNet always equals rentAmount', () {
      for (final amount in [100, 333, 850, 1200, 9999]) {
        final b = makeBooking(rentAmount: amount);
        expect(b.platformFee + b.ownerNet, amount);
      }
    });
  });

  group('Booking.startsAt & endsAt', () {
    test('single-day: startsAt and endsAt on same date', () {
      final b = makeBooking(
        date: DateTime(2026, 11, 10),
        startMinutes: 600,
        endMinutes: 720,
      );
      expect(b.startsAt, DateTime(2026, 11, 10, 10, 0));
      expect(b.endsAt, DateTime(2026, 11, 10, 12, 0));
    });

    test('multi-day: endsAt is on the last day', () {
      final b = makeBooking(
        date: DateTime(2026, 11, 10),
        startMinutes: 600,
        endMinutes: 720,
        days: 3,
      );
      expect(b.startsAt, DateTime(2026, 11, 10, 10, 0));
      expect(b.endsAt, DateTime(2026, 11, 12, 12, 0)); // 10 + 2 days
    });
  });

  group('Booking.endDate', () {
    test('single day: endDate == date', () {
      final b = makeBooking(date: DateTime(2026, 11, 10), days: 1);
      expect(b.endDate, DateTime(2026, 11, 10));
    });

    test('multi-day: endDate = date + (days-1)', () {
      final b = makeBooking(date: DateTime(2026, 11, 10), days: 5);
      expect(b.endDate, DateTime(2026, 11, 14));
    });
  });

  group('Booking.autoCompleteAt', () {
    test('is 24 hours after endsAt', () {
      final b = makeBooking(
        date: DateTime(2026, 11, 10),
        endMinutes: 720,
        days: 1,
      );
      expect(b.autoCompleteAt, b.endsAt.add(const Duration(hours: 24)));
    });
  });

  group('Booking.coversDate', () {
    test('single-day covers only that date', () {
      final b = makeBooking(date: DateTime(2026, 11, 10), days: 1);
      expect(b.coversDate(DateTime(2026, 11, 10)), isTrue);
      expect(b.coversDate(DateTime(2026, 11, 9)), isFalse);
      expect(b.coversDate(DateTime(2026, 11, 11)), isFalse);
    });

    test('multi-day covers all dates in range', () {
      final b = makeBooking(date: DateTime(2026, 11, 10), days: 3);
      expect(b.coversDate(DateTime(2026, 11, 10)), isTrue);
      expect(b.coversDate(DateTime(2026, 11, 11)), isTrue);
      expect(b.coversDate(DateTime(2026, 11, 12)), isTrue);
      expect(b.coversDate(DateTime(2026, 11, 9)), isFalse);
      expect(b.coversDate(DateTime(2026, 11, 13)), isFalse);
    });

    test('coversDate ignores time component', () {
      final b = makeBooking(date: DateTime(2026, 11, 10), days: 1);
      expect(b.coversDate(DateTime(2026, 11, 10, 23, 59)), isTrue);
      expect(b.coversDate(DateTime(2026, 11, 10, 0, 0)), isTrue);
    });
  });

  group('Booking deadline computed properties', () {
    test('ownerResponseDeadline is null when createdAt is null', () {
      final b = makeBooking();
      expect(b.ownerResponseDeadline, isNull);
    });

    test('ownerResponseDeadline is 24h after createdAt', () {
      final b = makeBooking()..createdAt = DateTime(2026, 11, 10, 8);
      expect(b.ownerResponseDeadline, DateTime(2026, 11, 11, 8));
    });

    test('paymentDeadline is null when approvedAt is null', () {
      final b = makeBooking();
      expect(b.paymentDeadline, isNull);
    });

    test('paymentDeadline is 24h after approvedAt', () {
      final b = makeBooking()..approvedAt = DateTime(2026, 11, 10, 9);
      expect(b.paymentDeadline, DateTime(2026, 11, 11, 9));
    });

    test('slipResubmitDeadline is null when slipRejectedAt is null', () {
      final b = makeBooking();
      expect(b.slipResubmitDeadline, isNull);
    });

    test('slipResubmitDeadline is 24h after slipRejectedAt', () {
      final b = makeBooking()..slipRejectedAt = DateTime(2026, 11, 10, 10);
      expect(b.slipResubmitDeadline, DateTime(2026, 11, 11, 10));
    });
  });

  group('Booking.effectiveSlipResubmitDeadline', () {
    test('null when slipRejectedAt not set', () {
      final b = makeBooking();
      expect(b.effectiveSlipResubmitDeadline, isNull);
    });

    test('uses startsAt when it is earlier than slipResubmitDeadline', () {
      // booking starts at 10:00 on Nov 10
      // slip rejected at Nov 10 08:00 → deadline Nov 11 08:00
      // but booking starts Nov 10 10:00 which is BEFORE Nov 11 08:00
      final b = makeBooking(
        date: DateTime(2026, 11, 10),
        startMinutes: 600, // 10:00
      )..slipRejectedAt = DateTime(2026, 11, 10, 8);
      // startsAt = Nov 10 10:00, deadline = Nov 11 08:00
      // startsAt is before deadline → effective = startsAt
      expect(b.effectiveSlipResubmitDeadline, b.startsAt);
    });

    test('uses slipResubmitDeadline when earlier than startsAt', () {
      // booking starts far in the future (Nov 20)
      // slip rejected Nov 10 → deadline Nov 11 — which is before Nov 20
      final b = makeBooking(
        date: DateTime(2026, 11, 20),
        startMinutes: 600,
      )..slipRejectedAt = DateTime(2026, 11, 10, 8);
      expect(b.effectiveSlipResubmitDeadline, b.slipResubmitDeadline);
    });
  });

  group('Booking.latestSlip', () {
    test('null when no slips', () {
      final b = makeBooking();
      expect(b.latestSlip, isNull);
    });

    test('returns last added slip', () {
      final b = makeBooking();
      final slip1 = PaymentSlip(
        name: 'slip1.png',
        bytes: Uint8List(1),
        submittedAt: DateTime(2026, 11, 10),
      );
      final slip2 = PaymentSlip(
        name: 'slip2.png',
        bytes: Uint8List(1),
        submittedAt: DateTime(2026, 11, 11),
      );
      b.slips.add(slip1);
      b.slips.add(slip2);
      expect(b.latestSlip?.name, 'slip2.png');
    });
  });

  // ─── PaymentSlip ─────────────────────────────────────────────────────────────
  group('PaymentSlip', () {
    test('bytes are copied defensively', () {
      final original = Uint8List.fromList([1, 2, 3]);
      final slip = PaymentSlip(
        name: 'slip.png',
        bytes: original,
        submittedAt: DateTime(2026, 11, 10),
      );
      original[0] = 99;
      expect(slip.bytes[0], 1); // not affected by mutation
    });

    test('rejectionReason defaults to empty', () {
      final slip = PaymentSlip(
        name: 's.png',
        bytes: Uint8List(1),
        submittedAt: DateTime(2026, 11, 10),
      );
      expect(slip.rejectionReason, isEmpty);
    });
  });

  // ─── Issue ───────────────────────────────────────────────────────────────────
  group('Issue', () {
    test('defaults: not closed, empty resolution', () {
      final i = Issue(
        id: 'i1', reporterId: 'u1',
        subject: 'Bug', detail: 'details',
      );
      expect(i.closed, isFalse);
      expect(i.resolution, isEmpty);
    });
  });

  // ─── Helper functions ─────────────────────────────────────────────────────────
  group('dateOnly', () {
    test('strips time component', () {
      final d = DateTime(2026, 11, 10, 15, 30, 45);
      expect(dateOnly(d), DateTime(2026, 11, 10));
    });

    test('already midnight stays the same', () {
      final d = DateTime(2026, 11, 10);
      expect(dateOnly(d), d);
    });
  });

  group('atMinute', () {
    test('adds correct minutes to midnight of date', () {
      final d = DateTime(2026, 11, 10, 15, 30); // time is ignored
      expect(atMinute(d, 600), DateTime(2026, 11, 10, 10, 0));
      expect(atMinute(d, 0), DateTime(2026, 11, 10, 0, 0));
      expect(atMinute(d, 1439), DateTime(2026, 11, 10, 23, 59));
    });
  });

  group('timeLabel', () {
    test('formats minutes to HH:MM', () {
      expect(timeLabel(0), '00:00');
      expect(timeLabel(60), '01:00');
      expect(timeLabel(600), '10:00');
      expect(timeLabel(720), '12:00');
      expect(timeLabel(1439), '23:59');
      expect(timeLabel(90), '01:30');
    });
  });

  group('dateLabel', () {
    test('formats as d/m/yyyy', () {
      expect(dateLabel(DateTime(2026, 1, 5)), '5/1/2026');
      expect(dateLabel(DateTime(2026, 11, 10)), '10/11/2026');
    });
  });

  group('dateTimeLabel', () {
    test('combines dateLabel and timeLabel', () {
      final d = DateTime(2026, 11, 10, 10, 30);
      expect(dateTimeLabel(d), '10/11/2026 10:30');
    });
  });

  group('bookingWhen', () {
    test('single-day format: date · start–end', () {
      final b = makeBooking(
        date: DateTime(2026, 11, 10),
        startMinutes: 600,
        endMinutes: 720,
        days: 1,
      );
      expect(bookingWhen(b), '10/11/2026 · 10:00–12:00');
    });

    test('multi-day format: startDate–endDate (N วัน) · start–end', () {
      final b = makeBooking(
        date: DateTime(2026, 11, 10),
        startMinutes: 600,
        endMinutes: 720,
        days: 3,
      );
      expect(bookingWhen(b), '10/11/2026–12/11/2026 (3 วัน) · 10:00–12:00');
    });
  });
}
