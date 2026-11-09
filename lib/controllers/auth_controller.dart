import '../data/app_store.dart';
import '../models/domain.dart';
import 'booking_controller.dart';

class AuthController {
  AuthController(this.store);
  final AppStore store;
  static bool validEmail(String s) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s.trim());
  void login(String email, String password) {
    final matches = store.users.where(
      (u) =>
          u.email.toLowerCase() == email.trim().toLowerCase() &&
          u.password == password,
    );
    if (matches.isEmpty) throw DomainError('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    if (!matches.first.active) throw DomainError('บัญชีนี้ถูกระงับการใช้งาน');
    store.currentUser = matches.first;
    store.changed('เข้าสู่ระบบ');
    BookingController(store).sweep();
  }

  void demo(UserRole role) {
    final account = store.user(switch (role) {
      UserRole.renter => 'renter-1',
      UserRole.owner => 'owner-1',
      UserRole.admin => 'admin-1',
    });
    login(account.email, account.password);
  }

  void logout() {
    store.changed('ออกจากระบบ');
    store.currentUser = null;
  }

  void register(
    String name,
    String email,
    String password,
    UserRole role,
    String phone,
  ) {
    if (role == UserRole.admin) throw DomainError('ไม่สามารถสมัครบัญชี Admin');
    validateProfile(name, email, phone);
    if (password.length < 8) {
      throw DomainError('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    }
    final user = AppUser(
      id: store.nextId('USER'),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      role: role,
      phone: phone.trim(),
    );
    store.users.add(user);
    store.currentUser = user;
    store.changed('สมัครสมาชิก');
  }

  void validateProfile(
    String name,
    String email,
    String phone, {
    String? excluding,
  }) {
    if (name.trim().isEmpty || !validEmail(email)) {
      throw DomainError('กรุณาระบุชื่อและอีเมลที่ถูกต้อง');
    }
    if (store.users.any(
      (u) =>
          u.id != excluding &&
          u.email.toLowerCase() == email.trim().toLowerCase(),
    )) {
      throw DomainError('อีเมลนี้ถูกใช้งานแล้ว');
    }
    if (phone.trim().isEmpty || !RegExp(r'^[0-9+\- ]{8,15}$').hasMatch(phone.trim())) {
      throw DomainError('หมายเลขโทรศัพท์ไม่ถูกต้อง');
    }
  }

  void updateProfile(
    String name,
    String email,
    String phone, [
    String? bankInfo,
  ]) {
    final u = store.requireUser();
    validateProfile(name, email, phone, excluding: u.id);
    u.name = name.trim();
    u.email = email.trim().toLowerCase();
    u.phone = phone.trim();
    if (bankInfo != null) {
      u.bankInfo = bankInfo.trim();
    }
    store.changed('บันทึกโปรไฟล์');
  }

  void changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) {
    final u = store.requireUser();
    if (u.password != currentPassword) {
      throw DomainError('รหัสผ่านปัจจุบันไม่ถูกต้อง');
    }
    if (newPassword.length < 8) {
      throw DomainError('รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัวอักษร');
    }
    if (newPassword != confirmPassword) {
      throw DomainError('ยืนยันรหัสผ่านใหม่ไม่ตรงกัน');
    }
    u.password = newPassword;
    store.changed('เปลี่ยนรหัสผ่าน');
  }

  List<AppUser> filterUsers({String query = '', UserRole? role}) {
    final q = query.trim().toLowerCase();
    return store.users.where((u) {
      if (role != null && u.role != role) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  void toggleUser(String id) {
    final admin = store.requireUser(UserRole.admin);
    final u = store.user(id);
    if (u.id == admin.id || u.role == UserRole.admin) {
      throw DomainError('ไม่สามารถระงับบัญชี Admin');
    }
    u.active = !u.active;
    store.changed('${u.active ? 'เปิดใช้งาน' : 'ระงับ'}บัญชี ${u.email}');
  }
}
