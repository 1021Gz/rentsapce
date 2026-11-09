import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentspace/controllers/auth_controller.dart';
import 'package:rentspace/controllers/booking_controller.dart';
import 'package:rentspace/controllers/payment_controller.dart';
import 'package:rentspace/controllers/space_controller.dart';
import 'package:rentspace/data/app_store.dart';
import 'package:rentspace/models/domain.dart';

void main() {
  late AppStore store;
  late AuthController auth;
  late BookingController bookings;
  late PaymentController payments;
  late SpaceController spaces;
  late DateTime now;
  final date = DateTime(2026, 11, 7);
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jE1sAAAAASUVORK5CYII=',
  );
  Booking request([int start = 600, int end = 720, String space = 'space-1']) {
    auth.demo(UserRole.renter);
    return bookings.create(space, date, start, end);
  }

  void approve(Booking b) {
    auth.demo(UserRole.owner);
    bookings.ownerReview(b.id, true, '');
  }

  void submit(Booking b) {
    auth.demo(UserRole.renter);
    payments.submit(b.id, 'slip.png', png, 'ทดสอบ');
  }

  void confirm(Booking b) {
    auth.demo(UserRole.admin);
    payments.review(b.id, true, '');
  }

  setUp(() {
    now = DateTime(2026, 11, 6, 8);
    store = AppStore(clock: () => now);
    auth = AuthController(store);
    bookings = BookingController(store);
    payments = PaymentController(store);
    spaces = SpaceController(store);
  });
  tearDown(() => store.dispose());

  group('Booking rules', () {
    test('overlap rejected; adjacent intervals accepted', () {
      request();
      expect(
        () => bookings.create('space-1', date, 660, 780),
        throwsA(isA<DomainError>()),
      );
      expect(bookings.create('space-1', date, 720, 780).rentAmount, 850);
    });
    test('same name different IDs do not conflict', () {
      store.space('space-2').name = store.space('space-1').name;
      request();
      expect(bookings.create('space-2', date, 600, 720).spaceId, 'space-2');
    });
    test('renaming a space does not free existing reservation', () {
      request();
      store.space('space-1').name = 'ชื่อใหม่';
      expect(
        () => bookings.create('space-1', date, 600, 720),
        throwsA(isA<DomainError>()),
      );
    });
    test('invalid, zero and reversed intervals rejected', () {
      auth.demo(UserRole.renter);
      for (final pair in [(600, 600), (720, 600), (-1, 600), (600, 1441)]) {
        expect(
          () => bookings.create('space-1', date, pair.$1, pair.$2),
          throwsA(isA<DomainError>()),
        );
      }
    });
    test('past time and outside opening hours rejected', () {
      auth.demo(UserRole.renter);
      expect(
        () => bookings.create('space-1', DateTime(2026, 11, 5), 600, 720),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => bookings.create('space-1', date, 480, 600),
        throwsA(isA<DomainError>()),
      );
    });
    test('cancellation frees time and retains reason', () {
      final b = request();
      bookings.cancel(b.id, 'เปลี่ยนแผน');
      expect(b.reason, 'เปลี่ยนแผน');
      expect(request().status, BookingStatus.ownerReview);
    });
    test('owner cannot operate another owner booking', () {
      final b = request();
      auth.login('owner2@demo.com', 'demo1234');
      expect(
        () => bookings.ownerReview(b.id, true, ''),
        throwsA(isA<DomainError>()),
      );
    });
    test('other renter cannot cancel and cannot see another booking', () {
      final b = request();
      auth.login('renter2@demo.com', 'demo1234');
      expect(store.visibleBookings(), isEmpty);
      expect(() => bookings.cancel(b.id, 'test'), throwsA(isA<DomainError>()));
    });
    test('owner rejects with mandatory reason', () {
      final b = request();
      auth.demo(UserRole.owner);
      expect(
        () => bookings.ownerReview(b.id, false, ''),
        throwsA(isA<DomainError>()),
      );
      bookings.ownerReview(b.id, false, 'ไม่สะดวก');
      expect(b.status, BookingStatus.ownerRejected);
      expect(request().status, BookingStatus.ownerReview);
    });
    test('quote rounds partial hours up and snapshots original price', () {
      final b = request(600, 690);
      expect(b.rentAmount, 1700);
      store.space('space-1').price = 9999;
      expect(b.rentAmount, 1700);
      expect(b.platformFee, 85);
      expect(b.ownerNet, 1615);
      expect(BookingController.rent(550, 600, 660), 550);
    });
    test('IDs remain unique with fixed clock', () {
      final a = request(600, 660), b = request(660, 720);
      expect(a.id, isNot(b.id));
    });
  });
  group('Availability and space approval', () {
    test('blocked period applies to one space only', () {
      auth.demo(UserRole.owner);
      final a = store.space('space-1').availability.copy();
      a.blocks.add(
        BlockedPeriod(
          id: 'block',
          start: atMinute(date, 600),
          end: atMinute(date, 720),
          reason: 'ซ่อมบำรุง',
        ),
      );
      spaces.saveAvailability('space-1', a);
      expect(() => request(), throwsA(isA<DomainError>()));
      expect(request(600, 720, 'space-2').spaceId, 'space-2');
      expect(request(720, 780).status, BookingStatus.ownerReview);
    });
    test('draft is isolated until save and cannot exclude active booking', () {
      request();
      auth.demo(UserRole.owner);
      final a = store.space('space-1').availability.copy();
      a.days[date.weekday - 1].open = false;
      expect(
        store.space('space-1').availability.accepts(date, 600, 720),
        isTrue,
      );
      expect(
        () => spaces.saveAvailability('space-1', a),
        throwsA(isA<DomainError>()),
      );
    });
    test('new space is pending then searchable/bookable after review', () {
      auth.demo(UserRole.owner);
      final s = spaces.save(
        name: 'ใหม่',
        category: 'สตูดิโอ',
        location: 'กรุงเทพ',
        price: 100,
        capacity: 2,
        description: 'รายละเอียด',
        amenities: [],
      );
      auth.demo(UserRole.renter);
      expect(
        () => bookings.create(s.id, date, 600, 660),
        throwsA(isA<DomainError>()),
      );
      auth.demo(UserRole.admin);
      spaces.review(s.id, true, '');
      auth.demo(UserRole.renter);
      expect(bookings.create(s.id, date, 600, 660).rentAmount, 100);
    });
    test('admin can suspend approved space and reactivate it', () {
      auth.demo(UserRole.admin);
      expect(
        () => spaces.suspendSpace('space-1', ''),
        throwsA(isA<DomainError>()),
      );
      spaces.suspendSpace('space-1', 'มีข้อร้องเรียนเรื่องเสียง');
      expect(store.space('space-1').status, SpaceStatus.rejected);
      expect(store.space('space-1').reviewReason, 'มีข้อร้องเรียนเรื่องเสียง');

      auth.demo(UserRole.renter);
      expect(
        () => bookings.create('space-1', date, 600, 660),
        throwsA(isA<DomainError>()),
      );

      auth.demo(UserRole.admin);
      spaces.activateSpace('space-1');
      expect(store.space('space-1').status, SpaceStatus.approved);
    });
    test('reject invalid space price and missing fields', () {
      auth.demo(UserRole.owner);
      expect(
        () => spaces.save(
          name: '',
          category: '',
          location: '',
          price: -1,
          capacity: 0,
          description: '',
          amenities: [],
        ),
        throwsA(isA<DomainError>()),
      );
    });
  });
  group('Payment state machine', () {
    test('rejecting and resubmitting slip never releases slot', () {
      final b = request();
      approve(b);
      submit(b);
      auth.demo(UserRole.admin);
      payments.review(b.id, false, 'ยอดไม่ครบ');
      expect(b.latestSlip!.rejectionReason, 'ยอดไม่ครบ');
      auth.login('renter2@demo.com', 'demo1234');
      expect(
        () => bookings.create('space-1', date, 600, 720),
        throwsA(isA<DomainError>()),
      );
      submit(b);
      confirm(b);
      expect(b.status, BookingStatus.confirmed);
      expect(b.slips.length, 2);
    });
    test('cannot skip approval, submit for missing ID, or submit twice', () {
      final b = request();
      expect(
        () => payments.submit(b.id, 'a.png', png, ''),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => payments.submit('missing', 'a.png', png, ''),
        throwsA(isA<DomainError>()),
      );
      approve(b);
      submit(b);
      expect(
        () => payments.submit(b.id, 'a.png', png, ''),
        throwsA(isA<DomainError>()),
      );
      expect(b.slips.length, 1);
    });
    test('invalid file extension/signature/size rejected', () {
      expect(
        () => PaymentController.validateSlip('a.gif', png),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => PaymentController.validateSlip(
          'a.png',
          Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => PaymentController.validateSlip('a.png', Uint8List(0)),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => PaymentController.validateSlip(
          'a.png',
          Uint8List(PaymentController.maxBytes + 1),
        ),
        throwsA(isA<DomainError>()),
      );
    });
    test('only Admin can review and rejection requires reason', () {
      final b = request();
      approve(b);
      submit(b);
      expect(
        () => payments.review(b.id, true, ''),
        throwsA(isA<DomainError>()),
      );
      auth.demo(UserRole.admin);
      expect(
        () => payments.review(b.id, false, ''),
        throwsA(isA<DomainError>()),
      );
    });
    test('complete only after service ends; pay once', () {
      final b = request();
      approve(b);
      submit(b);
      confirm(b);
      auth.demo(UserRole.owner);
      expect(() => bookings.complete(b.id), throwsA(isA<DomainError>()));
      now = atMinute(date, 720);
      bookings.complete(b.id);
      auth.demo(UserRole.admin);
      payments.payout(b.id);
      expect(b.paidOutAt, now);
      expect(() => payments.payout(b.id), throwsA(isA<DomainError>()));
    });
    test('confirmed cancellation releases the slot and blocks payout', () {
      final b = request();
      approve(b);
      submit(b);
      confirm(b);
      bookings.cancel(b.id, 'ยกเลิกตามข้อตกลง');
      expect(b.status, BookingStatus.canceled);
      expect(() => payments.payout(b.id), throwsA(isA<DomainError>()));
    });
    test('approve conflict guard catches inconsistent imported state', () {
      final b = request();
      approve(b);
      submit(b);
      store.bookings.add(
        Booking(
          id: 'bad-import',
          spaceId: b.spaceId,
          ownerId: b.ownerId,
          renterId: 'renter-2',
          spaceName: b.spaceName,
          date: b.date,
          startMinutes: 600,
          endMinutes: 660,
          rentAmount: 850,
          status: BookingStatus.confirmed,
        ),
      );
      auth.demo(UserRole.admin);
      expect(
        () => payments.review(b.id, true, ''),
        throwsA(isA<DomainError>()),
      );
    });
  });
  group('Accounts and reports', () {
    test('invalid login and duplicate registration rejected', () {
      expect(
        () => auth.login('renter@demo.com', 'bad'),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => auth.register(
          'ใหม่',
          'RENTER@demo.com',
          'password1',
          UserRole.renter,
          '081-234-5678',
        ),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => auth.register(
          'ใหม่',
          'new@example.com',
          'password1',
          UserRole.renter,
          '',
        ),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => auth.register(
          'ใหม่',
          'new@example.com',
          'password1',
          UserRole.admin,
          '081-234-5678',
        ),
        throwsA(isA<DomainError>()),
      );
      auth.register(
        'ผู้เช่าใหม่',
        'newrenter@example.com',
        'password1',
        UserRole.renter,
        '089-555-4433',
      );
      expect(store.currentUser?.phone, '089-555-4433');
    });
    test('profile and favorites survive logout in memory', () {
      auth.demo(UserRole.renter);
      spaces.favorite('space-1');
      expect(
        () => auth.updateProfile('ใหม่', 'new@example.com', ''),
        throwsA(isA<DomainError>()),
      );
      auth.updateProfile('ใหม่', 'new@example.com', '0812345678');
      auth.logout();
      auth.login('new@example.com', 'demo1234');
      expect(store.currentUser!.name, 'ใหม่');
      expect(store.currentUser!.favorites, contains('space-1'));
    });
    test('suspended account cannot log in', () {
      auth.demo(UserRole.admin);
      auth.toggleUser('renter-1');
      auth.logout();
      expect(() => auth.demo(UserRole.renter), throwsA(isA<DomainError>()));
    });
    test('report is shared with admin and result retained', () {
      auth.demo(UserRole.renter);
      spaces.report('พื้นที่', 'รูปไม่ตรง');
      final issue = store.issues.single;
      auth.demo(UserRole.admin);
      spaces.closeIssue(issue.id, 'แก้ไขรูปแล้ว');
      expect(issue.closed, isTrue);
      expect(issue.resolution, 'แก้ไขรูปแล้ว');
      expect(store.logs.first.action, contains(issue.id));
    });
  });
  group('Limits and lifecycle', () {
    test('booking shorter than the minimum is rejected', () {
      auth.demo(UserRole.renter);
      expect(
        () => bookings.create('space-1', date, 600, 630),
        throwsA(isA<DomainError>()),
      );
    });
    test('booking longer than the daily maximum is rejected', () {
      auth.demo(UserRole.owner);
      final a = store.space('space-1').availability.copy();
      for (final d in a.days) {
        d
          ..open = true
          ..start = 0
          ..end = 1440;
      }
      spaces.saveAvailability('space-1', a);
      auth.demo(UserRole.renter);
      expect(
        () => bookings.create('space-1', date, 0, 13 * 60),
        throwsA(isA<DomainError>()),
      );
    });
    test('admin can cancel a slip-review booking without payout', () {
      final b = request();
      approve(b);
      submit(b);
      auth.demo(UserRole.admin);
      bookings.cancel(b.id, 'ตรวจยอดแล้ว');
      expect(b.status, BookingStatus.canceled);
      expect(() => payments.payout(b.id), throwsA(isA<DomainError>()));
    });
    test('logout writes a single audit entry with the user name', () {
      auth.demo(UserRole.renter);
      final before = store.logs.length;
      auth.logout();
      expect(store.logs.length, before + 1);
      expect(store.logs.first.action, 'ออกจากระบบ');
      expect(store.logs.first.actor, 'มินตรา');
    });
    test('unanswered owner request expires and frees the slot', () {
      final b = request();
      now = now.add(const Duration(hours: 25));
      bookings.sweep();
      expect(b.status, BookingStatus.canceled);
      expect(b.reason, contains('หมดเวลาตอบรับ'));
      auth.demo(UserRole.renter);
      expect(
        bookings.create('space-1', date, 600, 720).status,
        BookingStatus.ownerReview,
      );
    });
    test('unpaid approved request expires after the payment window', () {
      final b = request();
      approve(b);
      now = now.add(const Duration(hours: 25, minutes: 1));
      bookings.sweep();
      expect(b.status, BookingStatus.canceled);
      expect(b.reason, contains('ชำระเงิน'));
    });
    test('confirmed booking auto-completes after the grace window', () {
      final b = request();
      approve(b);
      submit(b);
      confirm(b);
      now = b.endsAt.add(const Duration(hours: 25));
      bookings.sweep();
      expect(b.status, BookingStatus.completed);
      expect(b.completedAt, now);
      auth.demo(UserRole.admin);
      payments.payout(b.id);
      expect(b.paidOutAt, now);
    });
    test('rejected slip expires after 24h resubmit window and frees slot', () {
      final futureDate = DateTime(2026, 11, 10);
      auth.demo(UserRole.renter);
      final b = bookings.create('space-1', futureDate, 600, 720);
      approve(b);
      submit(b);
      auth.demo(UserRole.admin);
      payments.review(b.id, false, 'สลิปไม่ชัด');
      expect(b.status, BookingStatus.slipRejected);
      expect(b.slipRejectedAt, now);
      expect(b.slipResubmitDeadline, now.add(const Duration(hours: 24)));
      now = now.add(const Duration(hours: 23));
      bookings.sweep();
      expect(b.status, BookingStatus.slipRejected);
      auth.login('renter2@demo.com', 'demo1234');
      expect(
        () => bookings.create('space-1', futureDate, 600, 720),
        throwsA(isA<DomainError>()),
      );
      now = now.add(const Duration(hours: 2));
      bookings.sweep();
      expect(b.status, BookingStatus.canceled);
      expect(b.reason, contains('ส่งสลิปใหม่'));
      expect(
        bookings.create('space-1', futureDate, 600, 720).status,
        BookingStatus.ownerReview,
      );
    });
    test('rejected slip expires at booking start time if earlier than 24h', () {
      final b = request();
      approve(b);
      submit(b);
      now = atMinute(date, 480);
      auth.demo(UserRole.admin);
      payments.review(b.id, false, 'ยอดโอนไม่ตรง');
      expect(b.effectiveSlipResubmitDeadline, b.startsAt);
      now = b.startsAt;
      bookings.sweep();
      expect(b.status, BookingStatus.canceled);
      expect(b.reason, contains('ส่งสลิปใหม่'));
    });
    test('resubmitting slip clears rejection timestamp and prevents expiry', () {
      final futureDate = DateTime(2026, 11, 10);
      auth.demo(UserRole.renter);
      final b = bookings.create('space-1', futureDate, 600, 720);
      approve(b);
      submit(b);
      auth.demo(UserRole.admin);
      payments.review(b.id, false, 'ภาพเบลอ');
      now = now.add(const Duration(hours: 12));
      submit(b);
      expect(b.status, BookingStatus.slipReview);
      expect(b.slipRejectedAt, isNull);
      now = now.add(const Duration(hours: 20));
      bookings.sweep();
      expect(b.status, BookingStatus.slipReview);
    });
    test('hourly slots, busy labels, and adjacent slot extension work', () {
      request(600, 720);
      final slots = bookings.hourlySlots(store.space('space-1'), date);
      expect(slots.first, (540, 600));
      expect(slots.last, (1020, 1080));
      expect(bookings.busySlotLabels('space-1', date), ['คิวจอง 10:00–12:00']);
      expect(bookings.isSlotAvailable('space-1', date, 600, 660), isFalse);
      expect(bookings.isSlotAvailable('space-1', date, 720, 780), isTrue);
      final extended = bookings.selectOrExtendSlot(
        spaceId: 'space-1',
        date: date,
        currentStart: 720,
        currentEnd: 780,
        slotStart: 780,
        slotEnd: 840,
      );
      expect(extended, (720, 840));
    });
    test('navBadges reflects pending action counts per role', () {
      final b = request();
      auth.demo(UserRole.owner);
      expect(store.navBadges()[2], 1);
      expect(store.navBadges()[3], 1);
      bookings.ownerReview(b.id, true, '');
      auth.demo(UserRole.renter);
      expect(store.navBadges()[1], 1);
      submit(b);
      auth.demo(UserRole.admin);
      expect(store.navBadges()[1], 1);
      expect(store.navBadges()[2], 2);
    });
    test('filterSpaces supports amenity search and sorting options', () {
      auth.demo(UserRole.renter);
      final byPriceAsc = spaces.filterSpaces(sort: SpaceSort.priceAsc);
      expect(byPriceAsc.first.price, lessThanOrEqualTo(byPriceAsc.last.price));
      final byPriceDesc = spaces.filterSpaces(sort: SpaceSort.priceDesc);
      expect(
        byPriceDesc.first.price,
        greaterThanOrEqualTo(byPriceDesc.last.price),
      );
      final byCapacity = spaces.filterSpaces(sort: SpaceSort.capacityDesc);
      expect(
        byCapacity.first.capacity,
        greaterThanOrEqualTo(byCapacity.last.capacity),
      );
      final byAmenity = spaces.filterSpaces(query: 'ไฟสตูดิโอ');
      expect(byAmenity.single.id, 'space-1');
      final under600 = spaces.filterSpaces(maxPrice: 600);
      expect(under600.every((s) => s.price <= 600), isTrue);
      final minCap8 = spaces.filterSpaces(minCapacity: 8);
      expect(minCap8.every((s) => s.capacity >= 8), isTrue);
    });
    test('completed booking supports single renter review and space rating', () {
      final b = request();
      approve(b);
      submit(b);
      confirm(b);
      auth.demo(UserRole.renter);
      expect(
        () => bookings.submitReview(b.id, 5, 'ดีมาก'),
        throwsA(isA<DomainError>()),
      );
      now = b.endsAt.add(const Duration(minutes: 1));
      auth.demo(UserRole.owner);
      bookings.complete(b.id);
      auth.demo(UserRole.renter);
      bookings.submitReview(b.id, 4, 'ห้องสะอาด อุปกรณ์ครบ');
      expect(b.review?.rating, 4);
      expect(b.review?.comment, 'ห้องสะอาด อุปกรณ์ครบ');
      expect(spaces.averageRating('space-1'), 4.0);
      expect(spaces.reviewedBookings('space-1').single.id, b.id);
      expect(
        () => bookings.submitReview(b.id, 5, 'รีวิวซ้ำ'),
        throwsA(isA<DomainError>()),
      );
    });
    test('owner bankInfo update and admin user search/role filter work', () {
      auth.demo(UserRole.owner);
      auth.updateProfile(
        'เจ้าของใหม่',
        'owner@demo.com',
        '0891112222',
        'กรุงเทพ 111-2-33333-4',
      );
      expect(store.currentUser!.bankInfo, 'กรุงเทพ 111-2-33333-4');
      auth.demo(UserRole.admin);
      final owners = auth.filterUsers(role: UserRole.owner);
      expect(owners.length, 2);
      final mintra = auth.filterUsers(query: 'renter@demo.com');
      expect(mintra.single.id, 'renter-1');
    });
    test('changePassword validates current password and updates login', () {
      auth.demo(UserRole.renter);
      expect(
        () => auth.changePassword('wrong', 'newpass123', 'newpass123'),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => auth.changePassword('demo1234', 'short', 'short'),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => auth.changePassword('demo1234', 'newpass123', 'mismatch123'),
        throwsA(isA<DomainError>()),
      );
      auth.changePassword('demo1234', 'newpass123', 'newpass123');
      auth.logout();
      expect(
        () => auth.login('renter@demo.com', 'demo1234'),
        throwsA(isA<DomainError>()),
      );
      auth.login('renter@demo.com', 'newpass123');
      expect(store.currentUser?.id, 'renter-1');
    });
    test('multi-day booking calculates total rent and blocks all covered days', () {
      auth.demo(UserRole.renter);
      final b = bookings.create('space-1', date, 600, 720, days: 3);
      expect(b.days, 3);
      expect(b.rentAmount, 850 * 2 * 3);
      expect(b.coversDate(date), isTrue);
      expect(b.coversDate(date.add(const Duration(days: 1))), isTrue);
      expect(b.coversDate(date.add(const Duration(days: 2))), isTrue);
      expect(b.coversDate(date.add(const Duration(days: 3))), isFalse);

      approve(b);

      final day2 = date.add(const Duration(days: 1));
      expect(bookings.isSlotAvailable('space-1', day2, 600, 660), isFalse);
      expect(
        bookings.busySlotLabels('space-1', day2).single,
        contains('3 วัน'),
      );

      auth.demo(UserRole.renter);
      expect(
        () => bookings.create('space-1', date, 600, 660, days: 15),
        throwsA(isA<DomainError>()),
      );
      expect(
        () => bookings.create('space-1', date, 600, 660, attendees: 99),
        throwsA(isA<DomainError>()),
      );
      final withNote = bookings.create(
        'space-1',
        date.add(const Duration(days: 5)),
        600,
        720,
        attendees: 8,
        zone: 'ห้องส่วนตัว / ประชุมย่อย',
        renterNote: 'ขอโปรเจกเตอร์/จอภาพ',
      );
      expect(withNote.attendees, 8);
      expect(withNote.zone, 'ห้องส่วนตัว / ประชุมย่อย');
      expect(withNote.renterNote, 'ขอโปรเจกเตอร์/จอภาพ');
    });
  });
}
