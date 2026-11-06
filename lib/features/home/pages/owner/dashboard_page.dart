// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension OwnerDashboardPage on _HomePageState {
  Widget _ownerDash() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'สวัสดี เจ้าของพื้นที่ 👋',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const Text('ภาพรวมพื้นที่และการจองของคุณ'),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _stat('ประกาศทั้งหมด', '4'),
          _stat('รออนุมัติ', '1'),
          _stat('คำขอจองใหม่', '3'),
          _stat('จองเดือนนี้', '12'),
        ],
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _addSpace,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มพื้นที่'),
      ),
      const SizedBox(height: 10),
      const Text(
        'ทางลัด',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.event_available, color: green),
          title: const Text('การจอง'),
          subtitle: const Text('รวมคำขอ ปฏิทิน และประวัติการให้เช่า'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => index = 2),
        ),
      ),
    ],
  );
}
