import 'package:flutter/material.dart';
import 'slip_upload_page.dart';

class PaymentStatusPage extends StatelessWidget {
  const PaymentStatusPage({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.spaceName,
    required this.slipName,
    this.rejected = false,
  });
  final String bookingId, spaceName, slipName;
  final int amount;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final color = rejected ? Colors.red : const Color(0xFFB78327);
    final title = rejected
        ? 'สลิปไม่ผ่านการตรวจสอบ'
        : 'ส่งสลิปแล้ว · รอตรวจสอบ';
    final message = rejected
        ? 'กรุณาตรวจสอบยอดและภาพสลิป แล้วส่งหลักฐานใหม่'
        : 'เราจะแจ้งผลเมื่อผู้ดูแลตรวจสอบยอดและหลักฐานแล้ว';
    return Scaffold(
      appBar: AppBar(title: const Text('สถานะการชำระ')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(22),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        rejected
                            ? Icons.error_outline
                            : Icons.hourglass_top_rounded,
                        size: 66,
                        color: color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (rejected)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'เหตุผล: ภาพ/ยอดโอนไม่ชัดเจน (ตัวอย่าง)',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      const Divider(height: 30),
                      _row('รหัสรายการ', bookingId),
                      _row('พื้นที่', spaceName),
                      _row('ยอดโอน', '฿${amount.toStringAsFixed(2)}'),
                      _row('ไฟล์หลักฐาน', slipName),
                      _row(
                        'สถานะการชำระ',
                        rejected ? 'ต้องส่งสลิปใหม่' : 'รอตรวจสอบ',
                      ),
                      _row(
                        'สถานะการจอง',
                        rejected ? 'ยังไม่ยืนยัน' : 'รอตรวจสอบ',
                      ),
                      const SizedBox(height: 16),
                      if (rejected)
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SlipUploadPage(
                                bookingId: bookingId,
                                amount: amount,
                                spaceName: spaceName,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('ส่งสลิปใหม่'),
                        ),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                        child: const Text('กลับหน้าหลัก'),
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
  }

  Widget _row(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(a, style: const TextStyle(color: Colors.black54)),
        ),
        Flexible(
          child: Text(
            b,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
