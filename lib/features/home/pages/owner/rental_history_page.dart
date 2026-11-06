// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension OwnerRentalHistoryPage on _HomePageState {
  Widget _rentalHistory() {
    final records = [
      (
        'RS-1018',
        'ห้องประชุม The Green Room',
        'คุณมินตรา',
        '03 พ.ย. 2026',
        'เสร็จสิ้น',
        1100,
      ),
      (
        'RS-1012',
        'สตูดิโอแสงเหนือ',
        'คุณธนา',
        '29 ต.ค. 2026',
        'ยกเลิกแล้ว',
        2550,
      ),
      (
        'RS-1009',
        'Creative Loft Studio',
        'คุณพิม',
        '25 ต.ค. 2026',
        'ปฏิเสธ',
        2400,
      ),
      (
        'RS-1003',
        'ห้องประชุม The Green Room',
        'คุณอาร์ม',
        '18 ต.ค. 2026',
        'เสร็จสิ้น',
        1650,
      ),
    ];
    final shown = records
        .where((r) => historyFilter == 'ทั้งหมด' || r.$5 == historyFilter)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'ประวัติการให้เช่า',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text('ตรวจสอบรายการจองที่ผ่านมาและรายได้โดยประมาณ'),
        const SizedBox(height: 12),
        ...BookingStore.instance.bookings
            .where(
              (booking) => [
                BookingStatus.completed,
                BookingStatus.canceled,
                BookingStatus.ownerRejected,
              ].contains(booking.status),
            )
            .where(
              (booking) =>
                  historyFilter == 'ทั้งหมด' ||
                  _matchesHistoryFilter(booking.status, historyFilter),
            )
            .map(
              (booking) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: mint,
                    child: Icon(Icons.history, color: green),
                  ),
                  title: Text(booking.spaceName),
                  subtitle: Text(
                    '${booking.id} · ${booking.renterName} · ${booking.dateLabel}\nสถานะ: ${booking.status} · เจ้าของรับสุทธิ ฿${booking.ownerNet}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
        Wrap(
          spacing: 8,
          children: ['ทั้งหมด', 'เสร็จสิ้น', 'ยกเลิกแล้ว', 'ปฏิเสธ']
              .map(
                (x) => ChoiceChip(
                  label: Text(x),
                  selected: historyFilter == x,
                  onSelected: (_) => setState(() => historyFilter = x),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        ...shown.map(
          (r) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: mint,
                child: Icon(Icons.history, color: green),
              ),
              title: Text(r.$2),
              subtitle: Text('${r.$1} · ${r.$3} · ${r.$4}\nสถานะ: ${r.$5}'),
              isThreeLine: true,
              trailing: Text(
                '฿${r.$6}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _rentalDetail(r.$1, r.$2, r.$3, r.$4, r.$5, r.$6),
            ),
          ),
        ),
        if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text('ไม่พบประวัติในสถานะนี้', textAlign: TextAlign.center),
          ),
      ],
    );
  }

  bool _matchesHistoryFilter(String status, String filter) =>
      (filter == 'เสร็จสิ้น' && status == BookingStatus.completed) ||
      (filter == 'ยกเลิกแล้ว' && status == BookingStatus.canceled) ||
      (filter == 'ปฏิเสธ' && status == BookingStatus.ownerRejected);

  void _rentalDetail(
    String id,
    String space,
    String renter,
    String date,
    String status,
    int total,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('รายละเอียดการให้เช่า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รหัส: $id'),
            Text('พื้นที่: $space'),
            Text('ผู้เช่า: $renter'),
            Text('วันที่: $date'),
            Text('สถานะ: $status'),
            Text('ยอดจอง: ฿$total'),
            const SizedBox(height: 8),
            const Text(
              'ข้อมูลตัวอย่างสำหรับสาธิต',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}
