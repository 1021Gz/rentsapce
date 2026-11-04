import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../login_screen.dart';

class RenterProfileTab extends StatefulWidget {
  const RenterProfileTab({super.key});

  @override
  State<RenterProfileTab> createState() => _RenterProfileTabState();
}

class _RenterProfileTabState extends State<RenterProfileTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: currentUser?.fullName ?? '');
    _emailController = TextEditingController(text: currentUser?.email ?? '');
    _phoneController = TextEditingController(text: currentUser?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (currentUser != null) {
      currentUser!.fullName = _nameController.text.trim();
      currentUser!.email = _emailController.text.trim();
      currentUser!.phone = _phoneController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลโปรไฟล์เรียบร้อย')),
      );
    }
  }

  void _logout() {
    AuthController.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ของฉัน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 8),
            Text(
              currentUser?.fullName ?? 'ผู้ใช้งาน',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('บทบาท: ${currentUser?.role ?? "renter"}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล', prefixIcon: Icon(Icons.badge)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'อีเมล', prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'เบอร์โทร', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('บันทึกข้อมูล'),
            ),
            const Divider(height: 36),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ'),
            ),
          ],
        ),
      ),
    );
  }
}
