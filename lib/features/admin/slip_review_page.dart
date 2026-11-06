import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/booking_store.dart';
import '../../models/booking.dart';

class SlipReviewPage extends StatefulWidget {
  const SlipReviewPage({super.key});

  @override
  State<SlipReviewPage> createState() => _SlipReviewPageState();
}

class _SlipReviewPageState extends State<SlipReviewPage> {
  final demoRows = <Map<String, String>>[
    {
      'id': 'RS-582941',
      'space': 'The Green Room',
      'payer': 'คุณมินตรา',
      'amount': '฿1,100',
      'date': '6 พ.ย. 2026 10:42',
      'slip': 'slip_RS-582941.jpg',
      'status': 'รอตรวจสอบ',
    },
    {
      'id': 'RS-582812',
      'space': 'สตูดิโอแสงเหนือ',
      'payer': 'คุณธนา',
      'amount': '฿2,550',
      'date': '6 พ.ย. 2026 09:18',
      'slip': 'slip_RS-582812.jpg',
      'status': 'รอตรวจสอบ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pending = BookingStore.instance.pendingSlips;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'ตรวจสอบสลิป',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'ตรวจยอดก่อนยืนยันการจอง เงินจะพักไว้ในระบบจนกว่าผู้เช่าใช้บริการเสร็จ',
        ),
        const SizedBox(height: 14),
        if (pending.isEmpty &&
            demoRows.every((r) => r['status'] != 'รอตรวจสอบ'))
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('ไม่มีสลิปรอตรวจสอบ', textAlign: TextAlign.center),
            ),
          ),
        ...pending.map(_bookingCard),
        ...demoRows.where((r) => r['status'] == 'รอตรวจสอบ').map(_demoCard),
      ],
    );
  }

  Widget _bookingCard(Booking booking) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${booking.id} · ${booking.spaceName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Chip(label: Text('รอตรวจสอบ')),
            ],
          ),
          Text(
            'ผู้โอน: ${booking.renterName} · ยอดที่ต้องได้รับ: ฿${booking.rentAmount}',
          ),
          Text('สลิป: ${booking.slipName ?? 'ยังไม่มีไฟล์'}'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _update(booking, BookingStatus.slipRejected),
                  child: const Text('ปฏิเสธสลิป'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _update(booking, BookingStatus.confirmed),
                  child: const Text('ตรวจแล้ว ยืนยันการจอง'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _demoCard(Map<String, String> row) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row['id']} · ${row['space']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('ผู้โอน: ${row['payer']} · ยอดตัวอย่าง: ${row['amount']}'),
          Text('สลิปตัวอย่าง: ${row['slip']} · ${row['date']}'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _demoAction(row, 'ปฏิเสธสลิป'),
                  child: const Text('ปฏิเสธ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _demoAction(row, 'ตรวจสอบแล้ว'),
                  child: const Text('ยืนยันยอดโอน'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _update(Booking booking, String status) {
    setState(() => booking.status = status);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${booking.id}: $status')));
  }

  void _demoAction(Map<String, String> row, String action) {
    setState(() => row['status'] = action);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${row['id']}: $action (ข้อมูลตัวอย่าง)')),
    );
  }
}
