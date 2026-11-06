import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  String role = 'ผู้เช่า';
  bool register = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void enter([String? asRole]) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage(role: asRole ?? role)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        if (MediaQuery.sizeOf(context).width > 700)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF103C2E), green]),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
                  ),
                  fit: BoxFit.cover,
                  opacity: .22,
                ),
              ),
              padding: const EdgeInsets.all(48),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'rentSPACE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พื้นที่ที่ใช่\nเริ่มต้นไอเดียดี ๆ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'ค้นหาและจองห้องประชุม สตูดิโอ และพื้นที่สร้างสรรค์ได้ในที่เดียว',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  Text(
                    '© 2026 RentSpace · Prototype',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'rentSPACE',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      register ? 'สร้างบัญชีใหม่' : 'ยินดีต้อนรับกลับ',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      register
                          ? 'สมัครเพื่อเริ่มใช้งาน RentSpace'
                          : 'เข้าสู่ระบบเพื่อค้นหาและจัดการพื้นที่ของคุณ',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 22),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('เข้าสู่ระบบ')),
                        ButtonSegment(value: true, label: Text('สมัครสมาชิก')),
                      ],
                      selected: {register},
                      onSelectionChanged: (v) =>
                          setState(() => register = v.first),
                    ),
                    if (register)
                      const _Input(label: 'ชื่อ-นามสกุล', hint: 'ชื่อของคุณ'),
                    _Input(
                      label: 'อีเมล',
                      hint: 'you@example.com',
                      controller: email,
                    ),
                    _Input(
                      label: 'รหัสผ่าน',
                      hint: 'กรอกรหัสผ่าน',
                      controller: password,
                      obscure: true,
                    ),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(
                        labelText: 'เข้าใช้งานในบทบาท',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['ผู้เช่า', 'เจ้าของพื้นที่', 'ผู้ดูแลระบบ']
                          .map(
                            (x) => DropdownMenuItem(value: x, child: Text(x)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => role = v ?? role),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => enter(),
                      child: Text(register ? 'สร้างบัญชี' : 'เข้าสู่ระบบ'),
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const Text(
                      'ทดลองใช้งานทันที',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: ['ผู้เช่า', 'เจ้าของพื้นที่', 'ผู้ดูแลระบบ']
                          .map(
                            (r) => OutlinedButton(
                              onPressed: () => enter(r),
                              child: Text(r),
                            ),
                          )
                          .toList(),
                    ),
                    const Text(
                      'ข้อมูลจำลองสำหรับสาธิต · ยังไม่เชื่อมระบบบัญชีจริง',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.hint,
    this.controller,
    this.obscure = false,
  });
  final String label, hint;
  final TextEditingController? controller;
  final bool obscure;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
