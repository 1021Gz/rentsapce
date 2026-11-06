// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension AdminUsersPage on _HomePageState {
  Widget _users() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'จัดการผู้ใช้',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      ...[
        'พิมพ์ชนก · ผู้เช่า',
        'กิตติ · เจ้าของพื้นที่',
        'Admin · ผู้ดูแลระบบ',
      ].map(
        (x) => Card(
          child: ListTile(
            title: Text(x),
            subtitle: const Text('สถานะ: ใช้งาน'),
            trailing: TextButton(
              onPressed: () => _toast('เปลี่ยนสถานะบัญชีแล้ว'),
              child: const Text('ระงับ'),
            ),
          ),
        ),
      ),
    ],
  );
}
