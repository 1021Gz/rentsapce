import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import 'slip_upload_page.dart';

class BankTransferPage extends StatelessWidget {
  const BankTransferPage({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.spaceName,
  });
  final String bookingId, spaceName;
  final int amount;
  static const bankName = 'ธนาคารตัวอย่าง';
  static const accountName = 'RentSpace Co., Ltd. (บัญชีตัวอย่าง)';
  static const accountNo = 'XXX-X-XXXXX-X';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ชำระเงินด้วยการโอนธนาคาร')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'โอนเงินตามข้อมูลบัญชี',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('กรุณาโอนยอดให้ตรงกับรายการ แล้วแนบสลิปเพื่อส่งตรวจสอบ'),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('ธนาคาร', bankName),
                    _row('ชื่อบัญชี', accountName),
                    Row(
                      children: [
                        Expanded(child: _row('เลขที่บัญชี', accountNo)),
                        IconButton(
                          onPressed: () =>
                              Clipboard.setData(
                                const ClipboardData(text: accountNo),
                              ).then(
                                (_) =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('คัดลอกเลขบัญชีแล้ว'),
                                      ),
                                    ),
                              ),
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                    const Divider(),
                    _row('ผู้รับชำระ', 'RentSpace (บัญชีรับชำระตัวอย่าง)'),
                    _row('เลขรายการ', bookingId),
                    _row('พื้นที่', spaceName),
                    _row(
                      'ยอดที่ต้องโอน',
                      '฿${amount.toStringAsFixed(2)}',
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'บัญชีและเลขที่บัญชีในหน้านี้เป็น placeholder สำหรับจัดวาง Frontend กรุณาแทนด้วยข้อมูลบัญชีที่ได้รับอนุญาตก่อนใช้งานจริง',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
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
              label: const Text('โอนแล้ว แนบสลิป'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('กลับไปตรวจสอบรายการ'),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _row(String a, String b, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(a, style: const TextStyle(color: Colors.black54)),
        ),
        Text(
          b,
          style: TextStyle(
            fontWeight: strong ? FontWeight.bold : FontWeight.w600,
            color: strong ? green : null,
            fontSize: strong ? 18 : null,
          ),
        ),
      ],
    ),
  );
}
