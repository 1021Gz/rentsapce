// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension OwnerCalendarPage on _HomePageState {
  Widget _ownerCalendar() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'ปฏิทินการจอง',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text(
        'แสดงเฉพาะคำขอที่รออยู่และการจองที่กำลังจะมาถึง; ประวัติเก่าดูได้ที่เมนูประวัติให้เช่า',
      ),
      const SizedBox(height: 16),
      Card(
        child: Column(
          children: [
            const ListTile(
              title: Text('พฤศจิกายน 2026'),
              leading: Icon(Icons.calendar_month, color: green),
            ),
            ...[
              '12 พ.ย. · ห้องประชุม · รออนุมัติ · 10:00–12:00',
              '14 พ.ย. · สตูดิโอ · ยืนยันแล้ว · 13:00–16:00',
              '20 พ.ย. · Creative Loft · ยืนยันแล้ว · 09:00–11:00',
            ].map(
              (x) => ListTile(
                leading: const Icon(Icons.event_available, color: green),
                title: Text(x.split(' · ').skip(1).first),
                subtitle: Text(
                  '${x.split(' · ').first} · ${x.split(' · ').last}',
                ),
                onTap: () => _toast(x),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
