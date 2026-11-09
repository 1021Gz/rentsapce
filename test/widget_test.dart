import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentspace/app.dart';
import 'package:rentspace/controllers/auth_controller.dart';
import 'package:rentspace/data/app_store.dart';
import 'package:rentspace/models/domain.dart';

void main() {
  AppStore testStore() {
    final store = AppStore();
    for (final s in store.spaces) {
      s.image = '';
    }
    return store;
  }

  testWidgets('owner form creates shared pending space and admin approves it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testStore();
    final auth = AuthController(store);
    auth.demo(UserRole.owner);
    await tester.pumpWidget(RentSpaceApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.home_work_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('เพิ่มพื้นที่'));
    await tester.pumpAndSettle();
    final values = [
      'พื้นที่ทดสอบ UI',
      'สตูดิโอ',
      'กรุงเทพ',
      '400',
      '5',
      'พื้นที่สำหรับทดสอบ',
    ];
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), values[i]);
    }
    final save = find.text('บันทึกและส่งตรวจสอบ');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final space = store.spaces.last;
    expect(space.name, 'พื้นที่ทดสอบ UI');
    expect(space.status, SpaceStatus.pending);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('ออกจากระบบ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'ผู้ดูแลระบบ'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.rule_folder_outlined),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.ancestor(
      of: find.text('พื้นที่ทดสอบ UI'),
      matching: find.byType(Card),
    );
    final approve = find.descendant(
      of: card,
      matching: find.text('อนุมัติประกาศ'),
    );
    await tester.ensureVisible(approve);
    await tester.tap(approve);
    await tester.pumpAndSettle();
    expect(space.status, SpaceStatus.approved);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  testWidgets('renter can submit a request through checkout and see detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testStore();
    AuthController(store).demo(UserRole.renter);
    await tester.pumpWidget(RentSpaceApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ดูรายละเอียดและจอง').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('เปิด 09:00–18:00'), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-600-660')), findsOneWidget);
    final submit = find.text('ส่งคำขอจอง');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('ยืนยันการจอง'), findsOneWidget);
    expect(find.text('สรุปราคา'), findsOneWidget);
    expect(find.text('ข้อมูลผู้จอง'), findsOneWidget);
    expect(find.text('เงื่อนไขสำคัญก่อนการจอง'), findsOneWidget);
    expect(
      find.text('ฉันยอมรับเงื่อนไขการจองและกฎการใช้สถานที่'),
      findsOneWidget,
    );

    final checkbox = find.byType(CheckboxListTile);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    final confirmBtn = find.byKey(const ValueKey('confirm-booking-btn'));
    await tester.ensureVisible(confirmBtn);
    await tester.pumpAndSettle();
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    final newBooking = store.bookings.first;
    expect(newBooking.status, BookingStatus.ownerReview);
    expect(find.text(newBooking.id), findsWidgets);
    expect(
      find.byKey(const ValueKey('copy-booking-id-btn')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('copy-booking-evidence-btn')),
      findsOneWidget,
    );
    expect(find.text('รอเจ้าของอนุมัติ'), findsOneWidget);
    expect(find.text('1. ส่งคำขอ'), findsOneWidget);
    expect(find.text('4. ยืนยัน'), findsOneWidget);
    expect(find.text('รายละเอียดการจอง'), findsOneWidget);
    expect(find.textContaining('ส่งคำขอจอง'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  testWidgets('login rejects empty credentials', (tester) async {
    final store = testStore();
    await tester.pumpWidget(RentSpaceApp(store: store));
    expect(find.byTooltip('แสดงรหัสผ่าน'), findsOneWidget);
    await tester.tap(find.byTooltip('แสดงรหัสผ่าน'));
    await tester.pump();
    expect(find.byTooltip('ซ่อนรหัสผ่าน'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(find.text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'), findsOneWidget);
    expect(store.currentUser, isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  testWidgets('registration form validates and creates new account with phone', (
    tester,
  ) async {
    final store = testStore();
    await tester.pumpWidget(RentSpaceApp(store: store));
    await tester.tap(find.text('สมัครสมาชิก'));
    await tester.pumpAndSettle();
    expect(find.text('เบอร์โทรศัพท์ติดต่อ (เช่น 081-234-5678)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'สมชาย ทดสอบ');
    await tester.enterText(find.byType(TextField).at(1), 'somchai@test.com');
    await tester.enterText(find.byType(TextField).at(2), '081-999-8888');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    final createBtn = find.widgetWithText(FilledButton, 'สร้างบัญชี');
    await tester.ensureVisible(createBtn);
    await tester.pumpAndSettle();
    await tester.tap(createBtn);
    await tester.pumpAndSettle();
    expect(store.currentUser?.name, 'สมชาย ทดสอบ');
    expect(store.currentUser?.phone, '081-999-8888');
    expect(find.byTooltip('สมชาย ทดสอบ (ผู้เช่า)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  testWidgets('filter bottom sheet filters spaces by budget', (tester) async {
    final store = testStore();
    AuthController(store).demo(UserRole.renter);
    await tester.pumpWidget(RentSpaceApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-filter-btn')));
    await tester.pumpAndSettle();
    expect(find.text('ตัวกรองและเรียงลำดับ'), findsOneWidget);
    await tester.tap(find.text('ไม่เกิน ฿300'));
    await tester.pumpAndSettle();
    final applyBtn = find.text('ดูผลลัพธ์');
    await tester.ensureVisible(applyBtn);
    await tester.pumpAndSettle();
    await tester.tap(applyBtn);
    await tester.pumpAndSettle();
    expect(find.textContaining('≤ ฿300/ชม.'), findsOneWidget);
    expect(find.text('ห้องอ่านหนังสือเงียบสงบ'), findsOneWidget);
    expect(find.text('สตูดิโอแสงเหนือ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  testWidgets(
    'pre-booking review screen validates consent, terms modal, and back navigation',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = testStore();
      AuthController(store).demo(UserRole.renter);
      await tester.pumpWidget(RentSpaceApp(store: store));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ดูรายละเอียดและจอง').first);
      await tester.pumpAndSettle();

      final submit = find.text('ส่งคำขอจอง');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันการจอง'), findsOneWidget);
      expect(find.text('สรุปราคา'), findsOneWidget);
      expect(find.text('ข้อมูลผู้จอง'), findsOneWidget);
      expect(find.text('เงื่อนไขสำคัญก่อนการจอง'), findsOneWidget);

      final confirmBtnFinder = find.byKey(
        const ValueKey('confirm-booking-btn'),
      );
      final FilledButton initialButton = tester.widget(confirmBtnFinder);
      expect(initialButton.onPressed, isNull);

      final termsLink = find.text('อ่านกฎระเบียบและเงื่อนไขการคืนเงินฉบับเต็ม');
      await tester.ensureVisible(termsLink);
      await tester.pumpAndSettle();
      await tester.tap(termsLink);
      await tester.pumpAndSettle();
      expect(find.text('เงื่อนไขและนโยบายการจอง'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      final backBtn = find.text('กลับไปแก้ไขข้อมูลการจอง');
      await tester.ensureVisible(backBtn);
      await tester.pumpAndSettle();
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('รายละเอียดและสรุปการจอง'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
  for (final role in UserRole.values) {
    for (final width in [360.0, 1280.0]) {
      testWidgets(
        '${role.name} navigation at width $width has no layout exception',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = testStore();
          AuthController(store).demo(role);
          await tester.pumpWidget(RentSpaceApp(store: store));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final icons = switch (role) {
            UserRole.renter => [
              Icons.event_note,
              Icons.favorite_border,
              Icons.person_outline,
              Icons.search,
            ],
            UserRole.owner => [
              Icons.home_work_outlined,
              Icons.event_available,
              Icons.account_balance_wallet_outlined,
              Icons.person_outline,
              Icons.dashboard_outlined,
            ],
            UserRole.admin => [
              Icons.rule_folder_outlined,
              Icons.payments_outlined,
              Icons.people_outline,
              Icons.dashboard_outlined,
            ],
          };
          for (final icon in icons) {
            final nav = find.byType(NavigationBar);
            await tester.tap(
              find.descendant(of: nav, matching: find.byIcon(icon)).first,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
          store.dispose();
        },
      );
    }
  }

  testWidgets('Multi-day booking flow and clean Home navigation work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = testStore();
    AuthController(store).demo(UserRole.renter);
    await tester.pumpWidget(RentSpaceApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ดูรายละเอียดและจอง').first);
    await tester.pumpAndSettle();
    expect(find.text('ขั้นตอน 1/2'), findsOneWidget);

    await tester.tap(find.text('เหมาหลายวัน (ต่อเนื่อง)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('days-preset-3')));
    await tester.pumpAndSettle();

    final noteChip = find.text('ขอโปรเจกเตอร์/จอภาพ');
    await tester.ensureVisible(noteChip);
    await tester.pumpAndSettle();
    await tester.tap(noteChip);
    await tester.pumpAndSettle();

    final submitBtn = find.text('ส่งคำขอจอง');
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('ขั้นตอน 2/2'), findsOneWidget);
    expect(find.textContaining('3 วันต่อเนื่อง'), findsOneWidget);
    expect(find.text('ขอโปรเจกเตอร์/จอภาพ'), findsOneWidget);

    final checkbox = find.byType(CheckboxListTile);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    final confirmBtn = find.byKey(const ValueKey('confirm-booking-btn'));
    await tester.ensureVisible(confirmBtn);
    await tester.pumpAndSettle();
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(store.bookings.first.days, 3);
    expect(store.bookings.first.renterNote, 'ขอโปรเจกเตอร์/จอภาพ');
    expect(find.text('รายละเอียดการจอง'), findsOneWidget);
    expect(find.text('ขอโปรเจกเตอร์/จอภาพ'), findsOneWidget);

    await tester.tap(find.byTooltip('กลับหน้าหลัก'));
    await tester.pumpAndSettle();
    expect(find.text('ดูรายละเอียดและจอง'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  testWidgets('admin portal enhancements work seamlessly', (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testStore();
    AuthController(store).demo(UserRole.admin);
    await tester.pumpWidget(RentSpaceApp(store: store));
    await tester.pumpAndSettle();

    // 1. Dashboard shows quick action banner when actions are required
    expect(find.text('ภาพรวม'), findsWidgets);
    expect(find.textContaining('งานด่วนที่ต้องดำเนินการ'), findsOneWidget);

    // 2. Navigate to Moderation
    await tester.tap(find.text('ตรวจสอบ'));
    await tester.pumpAndSettle();
    final totalSpaces = store.spaces.length;
    expect(find.text('พื้นที่ทั้งหมด ($totalSpaces)'), findsOneWidget);

    // Switch to all spaces tab and verify filter chips
    await tester.tap(find.text('พื้นที่ทั้งหมด ($totalSpaces)'));
    await tester.pumpAndSettle();
    final approvedSpaces = store.spaces.where((s) => s.status == SpaceStatus.approved).length;
    expect(find.text('เปิดใช้งาน ($approvedSpaces)'), findsOneWidget);

    // Suspend space
    expect(find.text('ระงับประกาศ'), findsWidgets);

    // 3. Navigate to Finance
    await tester.tap(find.text('การเงิน'));
    await tester.pumpAndSettle();
    expect(find.text('คัดลอกสรุปการเงิน'), findsOneWidget);
    await tester.tap(find.text('คัดลอกสรุปการเงิน'));
    await tester.pumpAndSettle();
    expect(find.text('คัดลอกสรุปบัญชีการเงินแล้ว'), findsOneWidget);

    // 4. Navigate to Users
    await tester.tap(find.text('ผู้ใช้'));
    await tester.pumpAndSettle();
    expect(find.text('จัดการผู้ใช้'), findsOneWidget);
    expect(find.textContaining('บัญชีรับเงิน:'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  testWidgets('owner portal enhancements work seamlessly', (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testStore();
    AuthController(store).demo(UserRole.owner);
    await tester.pumpWidget(RentSpaceApp(store: store));
    await tester.pumpAndSettle();

    // 1. Dashboard shows verified bookings stat rather than slip reviews
    expect(find.text('คิวจองที่ยืนยันแล้ว'), findsOneWidget);
    expect(find.text('สลิปรอตรวจ'), findsNothing);

    // 2. Spaces tab shows active queue and space details
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.home_work_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('คิวจอง'), findsWidgets);

    // 3. Reservations tab shows owner card with quick action buttons
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.event_available),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('การจองพื้นที่'), findsOneWidget);

    // 4. Payouts tab shows export summary and edit bank action
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.account_balance_wallet_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('คัดลอกสรุปรายรับ'), findsOneWidget);
    expect(find.text('แก้ไขบัญชี'), findsOneWidget);

    await tester.tap(find.text('คัดลอกสรุปรายรับ'));
    await tester.pumpAndSettle();
    expect(find.text('คัดลอกสรุปรายรับลง Clipboard แล้ว'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
