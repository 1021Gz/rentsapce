import 'package:flutter/material.dart';
import '../controllers/rentspace_controller.dart';
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

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RenterMainScreen()),
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
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(outcome.message)),
      );

      if (outcome.isSuccess) {
        _navigateToMain();
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

      _navigateToMain();
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
                  const Icon(Icons.meeting_room_rounded, size: 64, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    _isRegisterMode ? 'สร้างบัญชีผู้เช่าใหม่' : 'เข้าสู่ระบบ RentSpace',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_isRegisterMode) ...[
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
                    const SizedBox(height: 12),
                  ],

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
