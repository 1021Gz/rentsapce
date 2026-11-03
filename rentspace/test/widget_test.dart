import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentspace/controllers/rentspace_controller.dart';
import 'package:rentspace/main.dart';
import 'package:rentspace/models/app_models.dart';

void main() {
  setUp(() {
    resetMockDatabase();
  });

  testWidgets('Login screen renders and validates empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RentSpaceApp());

    expect(find.text('RentSpace'), findsOneWidget);
    final loginBtn = find.text('เข้าสู่ระบบ (Login)');
    expect(loginBtn, findsOneWidget);

    await tester.ensureVisible(loginBtn);
    await tester.pumpAndSettle();
    await tester.tap(loginBtn);
    await tester.pump();

    expect(find.text('กรุณากรอก Username'), findsOneWidget);
    expect(find.text('กรุณากรอก Password'), findsOneWidget);
  });

  testWidgets('Renter login navigates to search and shows XAMPP seed spaces',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RentSpaceApp());

    final demoRenterChip = find.text('Demo Renter');
    await tester.ensureVisible(demoRenterChip);
    await tester.pumpAndSettle();
    await tester.tap(demoRenterChip);
    await tester.pump();

    final loginBtn = find.text('เข้าสู่ระบบ (Login)');
    await tester.ensureVisible(loginBtn);
    await tester.pumpAndSettle();
    await tester.tap(loginBtn);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Renter — ค้นหาพื้นที่เช่า'), findsOneWidget);
    expect(find.text('ห้องประชุมสว่างใจ'), findsOneWidget);
    expect(find.text('พื้นที่อเนกประสงค์สำหรับกิจกรรมกลุ่ม เวิร์กช็อป และสัมมนาขนาดย่อม'), findsNothing);
  });

  test('Controller rules: overlap prevention, registration & admin audit log',
      () {
    final publicAdminAttempt = AuthController.register(
      username: 'hacker',
      email: 'hacker@test.com',
      password: 'password123',
      fullName: 'Hacker',
      phone: '',
      role: 'admin',
    );
    expect(publicAdminAttempt.isSuccess, isFalse);

    final space = globalSpaces.firstWhere((s) => s.id == 2);
    final overlapOutcome = BookingController.createBookingRequest(
      space: space,
      start: DateTime(2026, 11, 6, 14, 0),
      end: DateTime(2026, 11, 6, 16, 0),
    );
    expect(overlapOutcome.isSuccess, isFalse);

    final initialLogs = globalAdminLogs.length;
    final pendingSpace = globalSpaces.firstWhere(
      (s) => s.approvalStatus == 'pending',
    );
    final approvalRes = AdminController.setSpaceApproval(
      space: pendingSpace,
      status: 'approved',
    );
    expect(approvalRes.isSuccess, isTrue);
    expect(globalAdminLogs.length, equals(initialLogs + 1));
  });

  testWidgets('Registration mode validates Gmail and Confirm Password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RentSpaceApp());

    final toggleRegisterBtn = find.text('ยังไม่มีบัญชี? สมัครสมาชิก');
    expect(toggleRegisterBtn, findsOneWidget);
    await tester.ensureVisible(toggleRegisterBtn);
    await tester.pumpAndSettle();
    await tester.tap(toggleRegisterBtn);
    await tester.pumpAndSettle();

    expect(find.text('Gmail / อีเมล'), findsOneWidget);
    expect(find.text('ยืนยันรหัสผ่าน (Confirm Password)'), findsOneWidget);

    final submitBtn = find.widgetWithText(ElevatedButton, 'สร้างบัญชี');
    expect(submitBtn, findsOneWidget);
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pump();

    expect(find.text('กรุณากรอก Gmail'), findsOneWidget);
    expect(find.text('กรุณากรอกยืนยันรหัสผ่าน'), findsOneWidget);
  });

  testWidgets('Registration mode provides interactive role selection between Renter and Owner',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RentSpaceApp());

    final toggleRegisterBtn = find.text('ยังไม่มีบัญชี? สมัครสมาชิก');
    await tester.ensureVisible(toggleRegisterBtn);
    await tester.pumpAndSettle();
    await tester.tap(toggleRegisterBtn);
    await tester.pumpAndSettle();

    expect(find.text('เลือกบทบาทผู้ใช้งาน (Role)'), findsOneWidget);
    expect(find.text('ผู้เช่า (Renter)'), findsOneWidget);
    expect(find.text('เจ้าของ (Owner)'), findsOneWidget);

    final ownerPill = find.text('เจ้าของ (Owner)');
    await tester.tap(ownerPill);
    await tester.pumpAndSettle();
    expect(find.text('ลงประกาศพื้นที่ จัดการราคา และคำขอจอง'), findsOneWidget);

    final renterPill = find.text('ผู้เช่า (Renter)');
    await tester.tap(renterPill);
    await tester.pumpAndSettle();
    expect(find.text('ค้นหา ดูรายละเอียด และจองพื้นที่ใช้งาน'), findsOneWidget);
  });
}
