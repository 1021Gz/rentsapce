// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension RenterBookingsPage on _HomePageState {
  Widget _bookingPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        pageTitle,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text('ติดตามคำขอและประวัติการจอง'),
      const SizedBox(height: 16),
      ...BookingStore.instance.bookings.map(_renterBookingCard),
      ...[
        'ห้องประชุม The Green Room · 12 พ.ย. 2026 · 10:00–12:00 · รออนุมัติ',
        'สตูดิโอแสงเหนือ · 14 พ.ย. 2026 · 13:00–16:00 · ยืนยันแล้ว',
        'ห้องอ่านหนังสือ · 08 พ.ย. 2026 · เสร็จสิ้น',
      ].map(
        (x) => Card(
          child: ListTile(
            leading: const Icon(Icons.event_note, color: green),
            title: Text(x.split(' · ').first),
            subtitle: Text(x.split(' · ').skip(1).join(' · ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailPage(
                  bookingId: 'RS-1024',
                  spaceName: x.split(' · ').first,
                  dateTime: x.split(' · ').skip(1).take(2).join(' · '),
                  status: x.split(' · ').last,
                  amount: 1100,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _renterBookingCard(Booking booking) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.spaceName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Chip(label: Text(booking.status)),
            ],
          ),
          Text('${booking.id} · ${booking.dateLabel} · ${booking.timeLabel}'),
          Text('ยอดที่ผู้เช่าชำระ ฿${booking.rentAmount}'),
          if (booking.status == BookingStatus.ownerReview)
            const Text(
              'รอเจ้าของตอบรับ ยังไม่มีการเรียกเก็บเงิน',
              style: TextStyle(color: Colors.black54),
            ),
          if (booking.status == BookingStatus.paymentDue ||
              booking.status == BookingStatus.slipRejected) ...[
            Text(
              booking.status == BookingStatus.slipRejected
                  ? 'ตรวจสอบยอดและแนบสลิปใหม่'
                  : 'เจ้าของอนุมัติแล้ว กรุณาโอนเงินและแนบสลิป',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BankTransferPage(
                      bookingId: booking.id,
                      amount: booking.rentAmount,
                      spaceName: booking.spaceName,
                    ),
                  ),
                ),
                icon: const Icon(Icons.account_balance),
                label: Text(
                  booking.status == BookingStatus.slipRejected
                      ? 'ส่งสลิปใหม่'
                      : 'ชำระเงิน',
                ),
              ),
            ),
          ],
          if (booking.status == BookingStatus.slipReview)
            Text(
              'สลิปที่ส่ง: ${booking.slipName ?? 'รอตรวจสอบ'} · เงินยังอยู่ระหว่างตรวจสอบ',
              style: const TextStyle(color: Colors.black54),
            ),
          if (booking.status == BookingStatus.confirmed)
            const Text(
              'ชำระแล้ว · เงินจะจ่ายให้ผู้ให้เช่าหลังใช้บริการ',
              style: TextStyle(color: green),
            ),
          if (booking.status == BookingStatus.ownerReview ||
              booking.status == BookingStatus.paymentDue)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setState(() => booking.status = BookingStatus.canceled),
                child: const Text('ยกเลิกคำขอ'),
              ),
            ),
        ],
      ),
    ),
  );
}
