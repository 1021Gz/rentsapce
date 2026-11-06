import 'package:flutter/material.dart';

class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({
    super.key,
    required this.bookingId,
    required this.spaceName,
    required this.dateTime,
    required this.status,
    required this.amount,
  });
  final String bookingId, spaceName, dateTime, status;
  final int amount;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('รายละเอียดการจอง')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลการจอง',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row('รหัสการจอง', bookingId),
                    _row('พื้นที่', spaceName),
                    _row('วันและเวลา', dateTime),
                    _row('สถานะ', status),
                    _row('ยอดรวม', '฿$amount'),
                    const Divider(),
                    const Text(
                      'นโยบายยกเลิก',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('การยกเลิกเป็นไปตามเงื่อนไขที่แสดง ณ เวลาจอง'),
                    const SizedBox(height: 18),
                    if (status == 'รออนุมัติ' || status == 'ยืนยันแล้ว')
                      OutlinedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('ยกเลิกการจอง?'),
                            content: const Text(
                              'ระบบจะคำนวณยอดคืนตามนโยบายที่ใช้กับรายการนี้',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('กลับ'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ส่งคำขอยกเลิกแล้ว'),
                                    ),
                                  );
                                },
                                child: const Text('ยืนยันยกเลิก'),
                              ),
                            ],
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('ยกเลิก/ถอนคำขอ'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
