import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../../main.dart';
import '../../models/app_models.dart';
import '../login_screen.dart';

class RenterProfileTab extends StatefulWidget {
  const RenterProfileTab({super.key});

  @override
  State<RenterProfileTab> createState() => _RenterProfileTabState();
}

class _RenterProfileTabState extends State<RenterProfileTab> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final activeUser = currentSessionUser;
    _fullNameController = TextEditingController(
      text: activeUser?.fullName ?? 'ณัฐ วงศ์ดี',
    );
    _emailController = TextEditingController(
      text: activeUser?.email ?? 'renter01@rentspace.test',
    );
    _phoneController = TextEditingController(
      text: activeUser?.phone ?? '081-234-5678',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _saveProfileChanges() {
    final outcome = AuthController.updateProfile(
      fullName: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      newPassword: _newPasswordController.text,
    );
    if (outcome.isSuccess) {
      _newPasswordController.clear();
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor: outcome.isSuccess
            ? const Color(0xFF2E633D)
            : const Color(0xFFC53030),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _executeLogout() {
    AuthController.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeUser = currentSessionUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              '/ โปรไฟล์',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'ออกจากระบบ',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _executeLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'บัญชีของฉัน',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF283248)
                        : const Color(0xFFE8E2D8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              const Color(0xFFC3562C).withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Color(0xFFC3562C),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeUser?.fullName ?? 'ผู้ใช้งาน',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '@${activeUser?.username ?? 'renter01'} · ${(activeUser?.role ?? 'renter').toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อ-นามสกุล',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทรศัพท์',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'เปลี่ยนรหัสผ่านใหม่ (เว้นว่างหากไม่เปลี่ยน)',
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC3562C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _saveProfileChanges,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text(
                          'บันทึกการแก้ไขลง MySQL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
