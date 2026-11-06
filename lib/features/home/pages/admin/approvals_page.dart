// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension AdminApprovalsPage on _HomePageState {
  Widget _approvals() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'อนุมัติพื้นที่',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text('ตรวจสอบประกาศก่อนแสดงต่อผู้เช่า'),
      ...demoSpaces.map(
        (s) => Card(
          child: ListTile(
            leading: const Icon(Icons.home_work, color: green),
            title: Text(s.name),
            subtitle: Text('${s.location} · ฿${s.price}/ชม.'),
            trailing: Wrap(
              children: [
                IconButton(
                  onPressed: () => _toast('อนุมัติแล้ว'),
                  icon: const Icon(Icons.check, color: green),
                ),
                IconButton(
                  onPressed: () => _toast('ปฏิเสธแล้ว'),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
