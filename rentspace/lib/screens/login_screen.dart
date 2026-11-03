import 'package:flutter/material.dart';
import '../controllers/rentspace_controller.dart';
import '../main.dart';
import '../models/app_models.dart';
import 'admin/admin_dashboard_screen.dart';
import 'owner/owner_dashboard_screen.dart';
import 'renter/renter_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();

  String _chosenRole = 'renter'; // 'renter', 'owner', 'admin'
  bool _isRegisterMode = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    MysqlApiBridge.syncFromDatabase().then((success) {
      if (!mounted || !success) return;
      final restoredSession = currentSessionUser;
      if (restoredSession != null) {
        final Widget targetScreen;
        if (restoredSession.role == 'renter') {
          targetScreen = const RenterMainScreen();
        } else if (restoredSession.role == 'owner') {
          targetScreen = const OwnerDashboardScreen();
        } else {
          targetScreen = const AdminDashboardScreen();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _fillPresetCredentials(String username, String role) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = 'password';
      _chosenRole = role;
      _isRegisterMode = false;
    });
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegisterMode &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('รหัสผ่านและการยืนยันรหัสผ่านไม่ตรงกัน'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      ActionOutcome outcome;
      if (_isRegisterMode) {
        outcome = AuthController.register(
          username: _usernameController.text,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.isNotEmpty
              ? _fullNameController.text
              : _usernameController.text,
          phone: '',
          role: _chosenRole,
        );
      } else {
        outcome = AuthController.login(
          username: _usernameController.text,
          password: _passwordController.text,
          roleOverride: _chosenRole,
        );
      }

      setState(() => _isSubmitting = false);

      if (!outcome.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(outcome.message),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final activeRole = currentSessionUser?.role ?? _chosenRole;
      Widget nextScreen;
      if (activeRole == 'renter') {
        nextScreen = const RenterMainScreen();
      } else if (activeRole == 'owner') {
        nextScreen = const OwnerDashboardScreen();
      } else {
        nextScreen = const AdminDashboardScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFC3562C);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121624) : const Color(0xFFF2ECE3),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D2336) : const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A3E37).withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header with Meeting Image
                  Stack(
                    children: [
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/meeting.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFF32241D),
                            child: const Icon(Icons.meeting_room, color: Colors.white, size: 64),
                          ),
                        ),
                      ),
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const ThemeToggleButton(iconColor: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RentSpace',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'พื้นที่ว่าง จองได้รายชั่วโมง',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Form Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isRegisterMode ? 'สร้างบัญชี' : 'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF32241D),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_isRegisterMode) ...[
                          Row(
                            children: [
                              Text(
                                'เลือกบทบาทผู้ใช้งาน (Role)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : const Color(0xFF63564D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141926) : const Color(0xFFF0EAE0),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                _buildRolePill('renter', 'ผู้เช่า (Renter)', Icons.person_outline, isDark),
                                _buildRolePill('owner', 'เจ้าของ (Owner)', Icons.storefront_outlined, isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C2233) : const Color(0xFFF7F3EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 15,
                                  color: isDark ? Colors.amber[300] : const Color(0xFFC3562C),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _chosenRole == 'renter'
                                        ? 'ค้นหา ดูรายละเอียด และจองพื้นที่ใช้งาน'
                                        : 'ลงประกาศพื้นที่ จัดการราคา และคำขอจอง',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : const Color(0xFF63564D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (_isRegisterMode) ...[
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อ-นามสกุล',
                              prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Gmail / อีเมล',
                              hintText: 'example@gmail.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                            ),
                            validator: (emailInput) {
                              if (!_isRegisterMode) return null;
                              if (emailInput == null || emailInput.trim().isEmpty) {
                                return 'กรุณากรอก Gmail';
                              }
                              if (!emailInput.contains('@')) {
                                return 'รูปแบบอีเมลไม่ถูกต้อง (เช่น example@gmail.com)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อผู้ใช้ (Username)',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          validator: (usernameInput) {
                            if (usernameInput == null || usernameInput.trim().isEmpty) {
                              return 'กรุณากรอก Username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          decoration: InputDecoration(
                            labelText: 'รหัสผ่าน (Password)',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            ),
                          ),
                          validator: (passwordInput) {
                            if (passwordInput == null || passwordInput.isEmpty) {
                              return 'กรุณากรอก Password';
                            }
                            if (_isRegisterMode && passwordInput.length < 6) {
                              return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        if (_isRegisterMode) ...[
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _hideConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'ยืนยันรหัสผ่าน (Confirm Password)',
                              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
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
                              if (!_isRegisterMode) return null;
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
                        ],
                        const SizedBox(height: 18),

                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isRegisterMode ? 'สร้างบัญชี' : 'เข้าสู่ระบบ (Login)',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isRegisterMode = !_isRegisterMode;
                              if (_chosenRole == 'admin') {
                                _chosenRole = 'renter';
                              }
                            });
                          },
                          child: Text(
                            _isRegisterMode ? 'มีบัญชีแล้ว? เข้าสู่ระบบ' : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF9E948C) : const Color(0xFF786D65),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Quick Demo Section for Instant Testing
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.person, size: 16),
                              label: const Text('Demo Renter'),
                              onPressed: () => _fillPresetCredentials('renter01', 'renter'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.storefront, size: 16),
                              label: const Text('Demo Owner'),
                              onPressed: () => _fillPresetCredentials('owner01', 'owner'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.admin_panel_settings, size: 16),
                              label: const Text('Demo Admin'),
                              onPressed: () => _fillPresetCredentials('admin01', 'admin'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolePill(
    String roleKey,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _chosenRole == roleKey;
    const primaryColor = Color(0xFFC3562C);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _chosenRole = roleKey;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1D2336) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white60 : const Color(0xFF786D65)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? primaryColor
                        : (isDark ? Colors.white70 : const Color(0xFF786D65)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
