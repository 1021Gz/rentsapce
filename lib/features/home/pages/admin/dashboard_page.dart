// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension AdminDashboardPage on _HomePageState {
  Widget _adminDash() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Dashboard',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text('ภาพรวมการใช้งาน RentSpace'),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _stat('ผู้ใช้ทั้งหมด', '248'),
          _stat('พื้นที่ทั้งหมด', '86'),
          _stat('การจองทั้งหมด', '314'),
          _stat('รอตรวจสอบ', '7'),
        ],
      ),
      const SizedBox(height: 18),
      const Text(
        'งานที่ต้องจัดการ',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.approval, color: green),
          title: const Text('ศูนย์ตรวจสอบ'),
          subtitle: const Text('ประกาศที่รอตรวจ รายงานจากผู้ใช้ และข้อพิพาท'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => index = 1),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long, color: green),
          title: const Text('การเงินและการจอง'),
          subtitle: const Text('รายการจองและคิวตรวจสลิป'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => index = 2),
        ),
      ),
    ],
  );
}
