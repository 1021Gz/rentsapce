// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension AdminBookingsPage on _HomePageState {
  Widget _adminBookings() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'การจองทั้งหมด',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text('ตรวจสอบสถานะการจองในระบบ'),
      const SizedBox(height: 12),
      ...BookingStore.instance.bookings.map(_managedBookingCard),
      ...[
        'RS-1024 · ห้องประชุม · ผู้เช่า: มินตรา · รออนุมัติ',
        'RS-1023 · สตูดิโอ · ผู้เช่า: ธนา · ยืนยันแล้ว',
        'RS-1018 · ห้องประชุม · ผู้เช่า: อาร์ม · เสร็จสิ้น',
      ].map(
        (x) => Card(
          child: ListTile(
            leading: const Icon(Icons.event_note, color: green),
            title: Text(x.split(' · ').first),
            subtitle: Text(x.split(' · ').skip(1).join(' · ')),
            trailing: IconButton(
              onPressed: () => _toast('ยกเลิกการจอง พร้อมระบุเหตุผล'),
              icon: const Icon(Icons.more_horiz),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _managedBookingCard(Booking booking) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.id} · ${booking.spaceName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Chip(label: Text(booking.status)),
            ],
          ),
          Text(
            '${booking.renterName} · ${booking.dateLabel} · ${booking.timeLabel}',
          ),
          Text(
            'ผู้เช่าชำระ ฿${booking.rentAmount} · ค่าบริการ 5% ฿${booking.platformFee} · เจ้าของรับ ฿${booking.ownerNet}',
          ),
        ],
      ),
    ),
  );
}
