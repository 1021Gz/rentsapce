import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/booking_store.dart';
import '../../models/booking.dart';
import 'payment_status_page.dart';

class SlipUploadPage extends StatefulWidget {
  const SlipUploadPage({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.spaceName,
  });
  final String bookingId, spaceName;
  final int amount;
  @override
  State<SlipUploadPage> createState() => _SlipUploadPageState();
}

class _SlipUploadPageState extends State<SlipUploadPage> {
  PlatformFile? file;
  bool busy = false;
  Future<void> chooseFile() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isNotEmpty) setState(() => file = result.first);
  }

  Future<void> submit() async {
    if (file == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกภาพสลิปก่อน')));
      return;
    }
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final store = BookingStore.instance;
    Booking? booking;
    for (final item in store.bookings) {
      if (item.id == widget.bookingId) {
        booking = item;
        break;
      }
    }
    if (booking != null) {
      booking.status = BookingStatus.slipReview;
      booking.slipName = file!.name;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusPage(
          bookingId: widget.bookingId,
          amount: widget.amount,
          spaceName: widget.spaceName,
          slipName: file!.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('แนบสลิปโอนเงิน')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'ยืนยันการโอนเงิน',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('แนบภาพสลิปที่เห็นยอดเงิน วันเวลา และเลขอ้างอิงชัดเจน'),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: green),
                title: Text(widget.spaceName),
                subtitle: Text(
                  'รายการ ${widget.bookingId} · ยอด ฿${widget.amount.toStringAsFixed(2)}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: chooseFile,
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: green.withValues(alpha: .3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      file == null
                          ? Icons.cloud_upload_outlined
                          : Icons.check_circle_outline,
                      size: 48,
                      color: green,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      file?.name ?? 'แตะเพื่อเลือกรูปสลิป',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'รองรับไฟล์ภาพ JPG, PNG',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'หมายเหตุ (ไม่บังคับ)',
                hintText: 'ระบุข้อมูลเพิ่มเติมให้ Admin ตรวจสอบ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: busy ? null : submit,
              child: Text(busy ? 'กำลังส่ง...' : 'ส่งสลิปเพื่อตรวจสอบ'),
            ),
            const SizedBox(height: 8),
            const Text(
              'หลังส่งแล้ว รายการจะอยู่สถานะ “รอตรวจสอบ” จนกว่า Admin จะตรวจหลักฐาน',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
