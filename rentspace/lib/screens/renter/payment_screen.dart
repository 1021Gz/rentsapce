import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../../models/app_models.dart';

class PaymentScreen extends StatefulWidget {
  final BookingItem bookingRecord;
  final SpaceItem? spaceRecord;

  const PaymentScreen({
    super.key,
    required this.bookingRecord,
    this.spaceRecord,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final TextEditingController _refController;
  String _mockSlipName = 'slip_sample.jpg';

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController(text: 'PAY-${widget.bookingRecord.id}-TEST');
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  void _confirmPayment() {
    BookingController.payBooking(
      widget.bookingRecord.id,
      _refController.text.trim().isEmpty ? 'PAY-${widget.bookingRecord.id}' : _refController.text.trim(),
      _mockSlipName,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ชำระเงินสำเร็จ! การจองได้รับการยืนยันแล้ว')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bookingRecord;

    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงินการจอง')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('รายละเอียดคำขอจอง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),
                    Text('พื้นที่: ${b.spaceName}', style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('เวลา: ${b.startTime} - ${b.endTime}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ยอดชำระสุทธิ:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '฿${b.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PromptPay Card
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 100, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text('สแกน QR Code เพื่อชำระเงิน (พร้อมเพย์)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ยอดโอน: ฿${b.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reference & Slip Mock
            TextField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'เลขอ้างอิงการโอนเงิน (Reference No.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _mockSlipName = 'slip_uploaded_${DateTime.now().millisecondsSinceEpoch}.jpg');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('แนบสลิปโอนเงินสำเร็จ')),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: Text('แนบสลิปโอนเงิน ($_mockSlipName)'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _confirmPayment,
              child: const Text('ยืนยันการชำระเงิน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
