// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension OwnerSpacesPage on _HomePageState {
  Widget _mySpaces() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'พื้นที่ของฉัน',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton.icon(
            onPressed: _addSpace,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มพื้นที่'),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AvailabilitySettingsPage()),
          ),
          icon: const Icon(Icons.schedule),
          label: const Text('ตั้งเวลาว่างและวันปิด'),
        ),
      ),
      ...demoSpaces.map(
        (s) => Card(
          child: ListTile(
            leading: const Icon(Icons.home_work, color: green),
            title: Text(s.name),
            subtitle: Text('${s.location} · ฿${s.price}/ชม. · อนุมัติแล้ว'),
            trailing: IconButton(
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => EditSpacePage(space: s)),
                );
                if (updated == true) setState(() {});
              },
              icon: const Icon(Icons.edit),
            ),
          ),
        ),
      ),
    ],
  );

  void _addSpace() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มพื้นที่ใหม่'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'ชื่อพื้นที่')),
              TextField(decoration: InputDecoration(labelText: 'ประเภท')),
              TextField(decoration: InputDecoration(labelText: 'ที่อยู่')),
              TextField(decoration: InputDecoration(labelText: 'ราคา/ชั่วโมง')),
              TextField(decoration: InputDecoration(labelText: 'ความจุ')),
              TextField(
                decoration: InputDecoration(labelText: 'สิ่งอำนวยความสะดวก'),
              ),
              TextField(decoration: InputDecoration(labelText: 'คำอธิบาย')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toast('ส่งประกาศให้ Admin ตรวจสอบ');
            },
            child: const Text('ส่งตรวจสอบ'),
          ),
        ],
      ),
    );
  }
}
