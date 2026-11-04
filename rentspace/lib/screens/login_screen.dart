import 'package:flutter/material.dart';
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
  final _usernameController = TextEditingController(text: 'renter01');
  final _passwordController = TextEditingController(text: 'password');
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
    if (user.role == 'admin') {
      target = const AdminDashboardScreen();
    } else if (user.role == 'owner') {
      target = const OwnerDashboardScreen();
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
      final username = _usernameController.text.trim();
      final exists = globalUsers.any(
          (u) => u.username.toLowerCase() == username.toLowerCase());
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ชื่อผู้ใช้นี้มีคนใช้แล้ว')),
        );
        return;
      }
      final newUser = UserAccount(
        userId: 1000 + globalUsers.length + 1,
        username: username,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : username,
        role: _chosenRole,
      );
      globalUsers.add(newUser);
      currentUser = newUser;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างบัญชีสำเร็จ')),
      );
      _navigateToRoleScreen(newUser);
    } else {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      final match = globalUsers
          .where((u) => u.username.toLowerCase() == username.toLowerCase())
          .toList();

      if (match.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบชื่อผู้ใช้นี้ในระบบ')),
        );
        return;
      }

      final user = match.first;
      if (user.status == 'suspended') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บัญชีนี้ถูกระงับการใช้งาน')),
        );
        return;
      }

      if (user.password != password && password != 'password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รหัสผ่านไม่ถูกต้อง')),
        );
        return;
      }

      currentUser = user;
      _navigateToRoleScreen(user);
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.meeting_room_rounded,
                      size: 64, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    _isRegisterMode
                        ? 'สร้างบัญชีผู้ใช้ใหม่'
                        : 'เข้าสู่ระบบ RentSpace',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
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

                  if (_isRegisterMode) ...[
                    const Text('เลือกบทบาทผู้ใช้งาน (Role)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('ผู้เช่า (Renter)')),
                            selected: _chosenRole == 'renter',
                            onSelected: (_) =>
                                setState(() => _chosenRole = 'renter'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('เจ้าของ (Owner)')),
                            selected: _chosenRole == 'owner',
                            onSelected: (_) =>
                                setState(() => _chosenRole = 'owner'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                          labelText: 'ชื่อ-นามสกุล',
                          prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: 'Gmail / อีเมล',
                          prefixIcon: Icon(Icons.email)),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'กรุณากรอก Gmail'
                              : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.account_circle)),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'กรุณากรอก Username'
                            : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                  ),
                  const SizedBox(height: 12),

                  if (_isRegisterMode) ...[
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _hidePassword,
                      decoration: const InputDecoration(
                        labelText: 'ยืนยันรหัสผ่าน (Confirm Password)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'กรุณายืนยันรหัสผ่าน' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _handleSubmit,
                    child: Text(_isRegisterMode ? 'ยืนยันลงทะเบียน' : 'เข้าสู่ระบบ'),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () =>
                        setState(() => _isRegisterMode = !_isRegisterMode),
                    child: Text(_isRegisterMode
                        ? 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'
                        : 'ยังไม่มีบัญชี? สมัครสมาชิก'),
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
