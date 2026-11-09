import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../data/app_store.dart';
import '../models/domain.dart';
import 'common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.store});
  final AppStore store;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      phone = TextEditingController();
  bool register = false, showPassword = false;
  UserRole role = UserRole.renter;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: 22,
                            color: scheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'rentSPACE',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'พื้นที่ที่ใช่ เริ่มต้นไอเดียดี ๆ',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ThemeToggle(
                          dark: widget.store.darkMode,
                          onChanged: (v) {
                            if (v != widget.store.darkMode) {
                              widget.store.toggleTheme();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TabStrip(
                      labels: const ['เข้าสู่ระบบ', 'สมัครสมาชิก'],
                      selected: register ? 1 : 0,
                      onChanged: (v) => setState(() => register = v == 1),
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                    if (register) formInput(name, 'ชื่อ-นามสกุล'),
                    formInput(
                      email,
                      'อีเมล',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (register)
                      formInput(
                        phone,
                        'เบอร์โทรศัพท์ติดต่อ (เช่น 081-234-5678)',
                        keyboardType: TextInputType.phone,
                      ),
                    formInput(
                      password,
                      'รหัสผ่าน (อย่างน้อย 8 ตัวอักษร)',
                      obscure: !showPassword,
                      suffix: IconButton(
                        tooltip: showPassword ? 'ซ่อนรหัสผ่าน' : 'แสดงรหัสผ่าน',
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                    if (register)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<UserRole>(
                          initialValue: role,
                          decoration: const InputDecoration(
                            labelText: 'ประเภทบัญชี',
                          ),
                          items: [UserRole.renter, UserRole.owner]
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => role = v!),
                        ),
                      ),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: () => perform(context, () {
                        final auth = AuthController(widget.store);
                        if (register) {
                          auth.register(
                            name.text,
                            email.text,
                            password.text,
                            role,
                            phone.text,
                          );
                        } else {
                          auth.login(email.text, password.text);
                        }
                      }),
                      child: Text(register ? 'สร้างบัญชี' : 'เข้าสู่ระบบ'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('หรือ', style: theme.textTheme.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ทดลองใช้งานด้วยบัญชีจำลอง',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    for (final r in UserRole.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          onPressed: () => perform(
                            context,
                            () => AuthController(widget.store).demo(r),
                          ),
                          child: Text(r.label),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      'ข้อมูลจำลองในหน่วยความจำ • ไม่มีการโอนเงินจริง\n'
                      'ข้อมูลจะเริ่มใหม่เมื่อปิดหรือรีเฟรชแอป',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'บัญชีเพิ่มเติม: renter2@demo.com / owner2@demo.com\n'
                      'รหัสผ่านบัญชีตัวอย่างทั้งหมด: demo1234',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
