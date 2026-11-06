// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension ProfilePage on _HomePageState {
  Widget _profile() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'โปรไฟล์ของฉัน',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const CircleAvatar(
        radius: 36,
        backgroundColor: mint,
        child: Icon(Icons.person, color: green, size: 36),
      ),
      const TextField(
        decoration: InputDecoration(
          labelText: 'ชื่อ-นามสกุล',
          hintText: 'ผู้ใช้ RentSpace',
        ),
      ),
      const TextField(
        decoration: InputDecoration(
          labelText: 'อีเมล',
          hintText: 'user@demo.com',
        ),
      ),
      const TextField(decoration: InputDecoration(labelText: 'เบอร์โทรศัพท์')),
      const SizedBox(height: 15),
      FilledButton(
        onPressed: () => _toast('บันทึกข้อมูลแล้ว'),
        child: const Text('บันทึกโปรไฟล์'),
      ),
    ],
  );
}
