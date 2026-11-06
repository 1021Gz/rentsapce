// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension AdminAuditLogsPage on _HomePageState {
  Widget _adminLogs() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'บันทึกกิจกรรม',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text('ประวัติการดำเนินการของผู้ดูแลระบบ'),
      ...[
        'วันนี้ 10:42 · Admin อนุมัติพื้นที่ · ห้องประชุม The Green Room',
        'วันนี้ 09:18 · Admin ระงับบัญชี · user#204',
        'เมื่อวาน 16:30 · Admin ปิดรายงาน · Creative Loft Studio',
      ].map(
        (x) => Card(
          child: ListTile(
            leading: const Icon(Icons.history, color: green),
            title: Text(x.split(' · ').skip(1).first),
            subtitle: Text(
              x.split(' · ').first + ' · ' + x.split(' · ').skip(2).join(' · '),
            ),
          ),
        ),
      ),
    ],
  );
}
