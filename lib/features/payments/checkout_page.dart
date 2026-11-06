import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/booking_store.dart';
import '../../data/availability_store.dart';
import '../../models/booking.dart';
import '../../models/space.dart';
import 'booking_submitted_page.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({
    super.key,
    required this.space,
    required this.date,
    required this.start,
    required this.end,
  });

  final Space space;
  final DateTime date;
  final TimeOfDay start, end;

  int get duration {
    final minutes =
        (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
    return (minutes / 60).ceil().clamp(1, 24);
  }

  int get total => space.price * duration;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ตรวจสอบการจอง')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'สรุปรายการก่อนส่งคำขอ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('ตรวจสอบวันเวลาและราคาให้ครบก่อนส่งให้เจ้าของพื้นที่'),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_work, color: green),
                    title: Text(space.name),
                    subtitle: Text(
                      '${space.location} · รองรับ ${space.capacity} คน',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_month, color: green),
                    title: Text('${date.day}/${date.month}/${date.year}'),
                    subtitle: Text(
                      '${start.format(context)} – ${end.format(context)} · $duration ชั่วโมง',
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _line('ค่าเช่า $duration ชม.', '฿$total'),
                    const Divider(),
                    _line('ยอดที่ผู้เช่าชำระ', '฿$total', bold: true),
                  ],
                ),
              ),
            ),
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
                        'ผู้เช่าจ่ายตามราคาเช่า ไม่มีการบวกค่าธรรมเนียมเพิ่ม เมื่อใช้บริการเสร็จ แพลตฟอร์มหักค่าบริการ 5% จากยอดผู้ให้เช่า',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ลำดับการจอง',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. ส่งคำขอและรอเจ้าของอนุมัติ  2. เมื่ออนุมัติแล้วจึงโอนเงินและแนบสลิป  3. ผู้ดูแลตรวจสลิปและยืนยันการจอง  4. หลังใช้บริการ เจ้าของได้รับยอดหลังหักค่าบริการ',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'หากเจ้าของปฏิเสธ จะไม่มีการเรียกเก็บเงิน',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _submitRequest(context),
              icon: const Icon(Icons.send),
              label: const Text('ส่งคำขอจอง'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ตัวอย่าง Frontend: สถานะจำลองในหน่วยความจำ ยังไม่เชื่อมต่อ backend',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    ),
  );

  void _submitRequest(BuildContext context) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final store = BookingStore.instance;
    if (!AvailabilityStore.instance.accepts(date, startMinutes, endMinutes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'เวลาที่เลือกอยู่นอกเวลาเปิดให้บริการ กรุณาเลือกเวลาอื่น',
          ),
        ),
      );
      return;
    }
    if (store.hasTimeConflict(
      spaceName: space.name,
      date: date,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ช่วงเวลานี้มีคำขอหรือรายการจองแล้ว กรุณาเลือกเวลาอื่น',
          ),
        ),
      );
      return;
    }
    final id =
        'RS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    store.add(
      Booking(
        id: id,
        spaceName: space.name,
        renterName: 'ผู้เช่าตัวอย่าง',
        date: date,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        rentAmount: total,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSubmittedPage(
          bookingId: id,
          spaceName: space.name,
          amount: total,
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : null,
            color: bold ? green : null,
            fontSize: bold ? 17 : null,
          ),
        ),
      ],
    ),
  );
}
