# RentSpace Flutter Prototype

โปรเจกต์ Flutter Frontend ตัวอย่างสำหรับ RentSpace เปิดแอปที่หน้าเข้าสู่ระบบ มีปุ่มทดลองเข้าใช้ในบทบาทผู้เช่า เจ้าของพื้นที่ และผู้ดูแลระบบ

## เปิดทดสอบใน Chrome (แนะนำ)

เปิด PowerShell ที่โฟลเดอร์โปรเจกต์แล้วรัน:

```powershell
flutter pub get
flutter run -d chrome
```

ถ้าต้องการสร้างไฟล์เว็บสำหรับนำไปโฮสต์:

```powershell
flutter build web
```

ไฟล์ผลลัพธ์จะอยู่ใน `build/web` เมื่อ build สำเร็จ

## เปิดบน Android

เปิด Android Emulator จาก Android Studio แล้วรัน:

```powershell
flutter devices
flutter run -d <device-id>
```

## Windows Desktop

คำสั่ง `flutter run` โดยไม่ระบุอุปกรณ์จะเลือก Windows Desktop และต้องมี Visual Studio workload `Desktop development with C++` รวม MSVC, CMake tools และ Windows SDK ก่อน

หากยังไม่ได้ติดตั้งส่วนดังกล่าว ให้ใช้ `flutter run -d chrome` หรือ Android Emulator แทน ข้อความในภาพเป็นปัญหา toolchain ของ Windows Desktop ไม่ใช่ข้อผิดพลาดในหน้าแอป

## ขอบเขต

ข้อมูลบัญชี พื้นที่ การจอง และการแจ้งเตือนเป็นข้อมูลจำลองในหน่วยความจำ ยังไม่เชื่อม API หรือฐานข้อมูล และจะเริ่มใหม่เมื่อปิดแอป

## โครงสร้างโค้ด

```text
lib/
  main.dart                    # จุดเริ่มต้นแอป
  app.dart                     # MaterialApp และ theme bootstrap
  core/theme.dart               # สีและค่ารูปแบบร่วม
  models/space.dart              # โมเดลข้อมูลพื้นที่
  data/demo_spaces.dart          # ข้อมูลพื้นที่ตัวอย่าง
  features/
    auth/login_page.dart         # หน้าเข้าสู่ระบบ/สมัครสมาชิก
    home/home_page.dart          # โครงเมนูตามบทบาทและหน้าหลักของผู้ใช้
```

หน้าใน HomePage ปัจจุบันรวมอยู่ในไฟล์ feature เดียว เพราะใช้ state และ callback ร่วมกัน; สามารถแยกต่อเป็น `features/renter/`, `features/owner/`, `features/admin/` เมื่อเริ่มต่อ API และแยก state management ได้

### Checkout flow (sandbox)

หน้าสรุปการจองและชำระเงินอยู่ที่ `lib/features/payments/checkout_page.dart` มีราคาแยกรายการ นโยบายยกเลิก วิธีชำระแบบ sandbox และหน้าผลลัพธ์ Payment sandbox ไม่ตัดเงินจริงและยังไม่เรียก API

## หน้าชำระเงินแบบโอนธนาคาร (Frontend)

```text
lib/features/payments/
  checkout_page.dart          # สรุป booking/ราคา/เงื่อนไข
  bank_transfer_page.dart     # รายละเอียดบัญชี/ยอดที่ต้องโอน
  slip_upload_page.dart       # เลือกไฟล์ภาพและส่งสลิป
  payment_status_page.dart    # สถานะรอตรวจสอบ
lib/features/admin/
  slip_review_page.dart       # หน้าตรวจหลักฐานโอนสำหรับ Admin
lib/features/owner/
  payout_page.dart            # หน้ารายรับ/สถานะจ่ายให้เจ้าของ
```

เส้นทางหน้า: `รายละเอียดพื้นที่ → checkout_page → bank_transfer_page → slip_upload_page → payment_status_page`; Admin เปิด `slip_review_page`; เจ้าของเปิด `payout_page` ดูยอดสุทธิหลังหักค่าบริการ

บัญชีธนาคารเป็น placeholder และข้อมูลรายการยังเป็นตัวอย่างฝั่ง Frontend เท่านั้น การตรวจสลิปจริง การกระทบยอด และการโอนให้เจ้าของต้องเชื่อม Backend/ผู้ให้บริการก่อนใช้งาน

## หน้าจอ Flutter แยกตามหน้า

ตัวนำทางและ state ของผู้ใช้รวมอยู่ที่ `lib/features/home/home_page.dart`; หน้าต่าง ๆ ถูกแยกเป็น part files เพื่อให้แต่ละหน้าดูและแก้ได้โดยยังใช้ state เดียวกัน:

```text
lib/features/home/pages/
  renter/explore_page.dart
  renter/bookings_page.dart
  renter/favorites_page.dart
  shared/profile_page.dart
  owner/dashboard_page.dart
  owner/spaces_page.dart
  owner/rental_history_page.dart
  owner/calendar_page.dart
  admin/dashboard_page.dart
  admin/approvals_page.dart
  admin/reports_page.dart
  admin/users_page.dart
  admin/bookings_page.dart
  admin/audit_logs_page.dart
```

หน้าชำระเงิน/แนบสลิป/ผลตรวจ และหน้า Admin ตรวจสลิป/เจ้าของดูรายรับ แยกเป็น widget files ใน `features/payments`, `features/admin`, `features/owner` ตามส่วนก่อนหน้า

## เมนูหลักหลังปรับลดหน้าซ้ำ

- ผู้เช่า: ค้นหา, การจอง, รายการโปรด, โปรไฟล์
- เจ้าของ: ภาพรวม, พื้นที่ (รวมทางเข้าตั้งเวลาว่าง), การจอง (แท็บคำขอ/ปฏิทิน/ประวัติ), รายรับ, โปรไฟล์
- Admin: Dashboard, ตรวจสอบ (แท็บประกาศ/รายงาน/ข้อพิพาท), การเงิน (แท็บการจอง/ตรวจสลิป), ผู้ใช้, Log

หน้าที่ใช้ทำงานชุดเดียวกันถูกรวมเป็นแท็บภายในหมวด แทนการแสดงเป็นเมนูหลักแยกหลายรายการ
