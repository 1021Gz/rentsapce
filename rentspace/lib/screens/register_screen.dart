import 'package:flutter/material.dart';
import '../controllers/rentspace_controller.dart';
import '../main.dart';
import '../models/app_models.dart';
import 'admin/admin_dashboard_screen.dart';
import 'owner/owner_dashboard_screen.dart';
import 'renter/renter_main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registrationFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _chosenRole = 'renter';
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _dispatchRegistration() {
    if (!_registrationFormKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านและการยืนยันรหัสผ่านไม่ตรงกัน'),
          backgroundColor: Color(0xFFC53030),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final registrationOutcome = AuthController.register(
      username: _usernameController.text,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      role: _chosenRole,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(registrationOutcome.message),
        backgroundColor: registrationOutcome.isSuccess
            ? const Color(0xFF2E633D)
            : const Color(0xFFC53030),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!registrationOutcome.isSuccess) return;

    final activeUser = currentSessionUser;
    final Widget destinationScreen = activeUser?.role == 'owner'
        ? const OwnerDashboardScreen()
        : (activeUser?.role == 'admin'
            ? const AdminDashboardScreen()
            : const RenterMainScreen());

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destinationScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ResponsiveFrame(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text(
                'RentSpace',
                style: TextStyle(
                  color: Color(0xFFC3562C),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ สมัครสมาชิก',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: const [
            ThemeToggleButton(),
            SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _registrationFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'สร้างบัญชี RentSpace',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'เลือกบทบาทผู้เช่า (Renter) หรือเจ้าของพื้นที่ (Owner)',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อ-นามสกุล',
                          isDense: true,
                        ),
                        validator: (valueInput) =>
                            valueInput == null || valueInput.trim().isEmpty
                                ? 'กรุณากรอกชื่อ-นามสกุล'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          isDense: true,
                        ),
                        validator: (valueInput) =>
                            valueInput == null || valueInput.trim().isEmpty
                                ? 'กรุณากรอก Username'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Gmail / อีเมล',
                          hintText: 'example@gmail.com',
                          isDense: true,
                        ),
                        validator: (valueInput) {
                          if (valueInput == null || valueInput.trim().isEmpty) {
                            return 'กรุณากรอก Gmail';
                          }
                          if (!valueInput.contains('@')) {
                            return 'รูปแบบอีเมลไม่ถูกต้อง (เช่น example@gmail.com)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'เบอร์โทรศัพท์ (ไม่บังคับ)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                        validator: (valueInput) =>
                            valueInput == null || valueInput.length < 6
                                ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _hideConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'ยืนยันรหัสผ่าน (Confirm Password)',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hideConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() =>
                                _hideConfirmPassword = !_hideConfirmPassword),
                          ),
                        ),
                        validator: (confirmInput) {
                          if (confirmInput == null || confirmInput.isEmpty) {
                            return 'กรุณากรอกยืนยันรหัสผ่าน';
                          }
                          if (confirmInput != _passwordController.text) {
                            return 'รหัสผ่านไม่ตรงกัน';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _chosenRole,
                        decoration: const InputDecoration(
                          labelText: 'บทบาท (Role)',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'renter',
                            child: Text('ผู้เช่า (Renter)'),
                          ),
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('เจ้าของพื้นที่ (Owner)'),
                          ),
                        ],
                        onChanged: (selectedVal) {
                          if (selectedVal != null) {
                            setState(() => _chosenRole = selectedVal);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC3562C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _dispatchRegistration,
                          child: const Text(
                            'ยืนยันการสมัครสมาชิก',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
