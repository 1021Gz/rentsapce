// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension AdminReportsPage on _HomePageState {
  Widget _reports() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'รายงานประกาศจากผู้ใช้',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text(
        'คิวนี้ใช้ตรวจเนื้อหา/ความถูกต้องของประกาศเท่านั้น; ปัญหาที่ผูกกับ booking อยู่ในเมนู ปัญหา/ข้อพิพาท',
        style: TextStyle(color: Colors.black54),
      ),
      Card(
        child: ListTile(
          title: const Text('Creative Loft Studio'),
          subtitle: const Text('เหตุผล: ข้อมูลไม่ตรงกับภาพ · เปิดอยู่'),
          trailing: TextButton(
            onPressed: () => _toast('ปิดรายงานแล้ว'),
            child: const Text('จัดการ'),
          ),
        ),
      ),
    ],
  );
}
