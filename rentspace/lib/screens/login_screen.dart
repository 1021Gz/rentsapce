import 'package:flutter/material.dart';
import '../controllers/rentspace_controller.dart';
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

  String _chosenRole = 'renter';
  bool _isRegisterMode = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _fillDemo(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
  }

  void _navigateToRoleScreen(UserAccount user) {
    Widget target;
    if (user.role == 'owner') {
      target = const OwnerDashboardScreen();
    } else if (user.role == 'admin') {
      target = const AdminDashboardScreen();
    } else {
      target = const RenterMainScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegisterMode) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน')),
        );
        return;
      }

      final outcome = AuthController.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        role: _chosenRole,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(outcome.message)),
      );

      if (outcome.isSuccess && currentUser != null) {
        _navigateToRoleScreen(currentUser!);
      }
    } else {
      final outcome = AuthController.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (!outcome.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(outcome.message)),
        );
        return;
      }

      if (currentUser != null) {
        _navigateToRoleScreen(currentUser!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RentSpace'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.meeting_room_rounded, size: 64, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    _isRegisterMode ? 'สร้างบัญชีผู้ใช้ใหม่' : 'เข้าสู่ระบบ RentSpace',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Demo quick login buttons
                  if (!_isRegisterMode) ...[
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          label: const Text('Demo Renter'),
                          onPressed: () => _fillDemo('renter01', 'password'),
                        ),
                        ActionChip(
                          label: const Text('Demo Owner'),
                          onPressed: () => _fillDemo('owner01', 'password'),
                        ),
                        ActionChip(
                          label: const Text('Demo Admin'),
                          onPressed: () => _fillDemo('admin01', 'password'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Role selector in register mode
                  if (_isRegisterMode) ...[
                    const Text('เลือกบทบาทผู้ใช้งาน (Role)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('ผู้เช่า (Renter)')),
                            selected: _chosenRole == 'renter',
                            onSelected: (_) => setState(() => _chosenRole = 'renter'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('เจ้าของ (Owner)')),
                            selected: _chosenRole == 'owner',
                            onSelected: (_) => setState(() => _chosenRole = 'owner'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _chosenRole == 'owner'
                          ? 'ลงประกาศพื้นที่ จัดการราคา และคำขอจอง'
                          : 'ค้นหา ดูรายละเอียด และจองพื้นที่ใช้งาน',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Gmail / อีเมล', prefixIcon: Icon(Icons.email)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอก Gmail' : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.account_circle)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอก Username' : null,
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอก Password' : null,
                  ),
                  const SizedBox(height: 12),

                  // Confirm password in register mode
                  if (_isRegisterMode) ...[
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'ยืนยันรหัสผ่าน (Confirm Password)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกยืนยันรหัสผ่าน' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleSubmit,
                    child: Text(
                      _isRegisterMode ? 'สร้างบัญชี' : 'เข้าสู่ระบบ (Login)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Toggle mode button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isRegisterMode ? 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ' : 'ยังไม่มีบัญชี? สมัครสมาชิก',
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
}
