import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BookingSubmittedPage extends StatelessWidget {
  const BookingSubmittedPage({
    super.key,
    required this.bookingId,
    required this.spaceName,
    required this.amount,
  });

  final String bookingId;
  final String spaceName;
  final int amount;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ส่งคำขอจองแล้ว')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: green, size: 64),
                    SizedBox(height: 12),
                    Text(
                      'รอเจ้าของอนุมัติคำขอ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ยังไม่มีการเรียกเก็บเงิน เมื่อเจ้าของอนุมัติ รายการจองจะเปลี่ยนเป็นรอชำระเงิน',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _row('รหัสการจอง', bookingId),
            _row('พื้นที่', spaceName),
            _row('ยอดที่ผู้เช่าชำระ', '฿$amount'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('กลับหน้าหลัก'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _row(String label, String value) => ListTile(
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
