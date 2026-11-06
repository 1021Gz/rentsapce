import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/booking_store.dart';
import '../../models/booking.dart';

class OwnerPayoutPage extends StatelessWidget {
  const OwnerPayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final completed = BookingStore.instance.ownerPayable;
    final held = BookingStore.instance.bookings
        .where((booking) => booking.status == BookingStatus.confirmed)
        .fold<int>(0, (sum, booking) => sum + booking.rentAmount);
    final payable = completed.isEmpty
        ? 8420
        : completed.fold<int>(0, (sum, booking) => sum + booking.ownerNet);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'รายรับและประวัติการจ่าย',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text('ค่าบริการแพลตฟอร์มหักจากรายรับของผู้ให้เช่า'),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ยอดรอจ่าย',
                  style: TextStyle(color: Colors.black54),
                ),
                Text(
                  '฿${payable.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                Text(
                  completed.isEmpty
                      ? 'ยอดตัวอย่างสุทธิหลังหักค่าบริการ'
                      : 'ยอดสุทธิจากรายการที่ใช้บริการเสร็จแล้ว',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
        if (held > 0)
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock, color: green),
              title: const Text('เงินที่พักไว้จนจบการเช่า'),
              subtitle: const Text('ยังไม่พร้อมจ่ายให้เจ้าของ'),
              trailing: Text(
                '฿$held',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ตัวอย่างการหักค่าบริการต่อรายการ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _line('ค่าเช่าที่ผู้เช่าชำระ', '฿1,700'),
                _line('ค่าบริการแพลตฟอร์ม (5%)', '− ฿85'),
                const Divider(),
                _line('ผู้ให้เช่าได้รับ', '฿1,615', bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'รายการรายรับ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...completed.map(
          (booking) => Card(
            child: ListTile(
              leading: const Icon(
                Icons.account_balance_wallet_outlined,
                color: green,
              ),
              title: Text(booking.spaceName),
              subtitle: Text(
                '${booking.id} · ผู้เช่าจ่าย ฿${booking.rentAmount} · หัก 5% ฿${booking.platformFee}',
              ),
              trailing: Text(
                '฿${booking.ownerNet}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
            ),
          ),
        ),
        ...[
          'RS-582941 · The Green Room · 6 พ.ย. · รอตรวจสอบ',
          'RS-582812 · สตูดิโอแสงเหนือ · 5 พ.ย. · เตรียมจ่าย',
          'RS-582401 · ห้องอ่านหนังสือ · 2 พ.ย. · จ่ายแล้ว',
        ].map(
          (x) => Card(
            child: ListTile(
              leading: const Icon(
                Icons.account_balance_wallet_outlined,
                color: green,
              ),
              title: Text(x.split(' · ').skip(1).first),
              subtitle: Text(
                '${x.split(' · ').first} · ${x.split(' · ').skip(2).join(' · ')}',
              ),
              trailing: Text(
                x.contains('RS-582941') ? '฿1,615' : 'ดู',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'บัญชีรับเงินจะตั้งค่าในระบบหลังบ้าน บัญชีนี้เป็นหน้าตัวอย่าง ไม่ได้ส่งเงินจริง',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
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
          ),
        ),
      ],
    ),
  );
}
