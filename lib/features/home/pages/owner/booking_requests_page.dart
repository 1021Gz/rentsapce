// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension OwnerBookingRequestsPage on _HomePageState {
  Widget _ownerBookingRequests() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'คำขอจอง',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text('คำขอที่รอการตอบรับสำหรับพื้นที่ของคุณ'),
      const SizedBox(height: 12),
      ...BookingStore.instance.bookings
          .where(
            (booking) => ![
              BookingStatus.ownerRejected,
              BookingStatus.canceled,
              BookingStatus.completed,
            ].contains(booking.status),
          )
          .map(_bookingRequestCard),
      ...[
        (
          'RS-1024',
          'ห้องประชุม The Green Room',
          'คุณมินตรา',
          '12 พ.ย. 2026',
          '10:00–12:00',
          1100,
        ),
        (
          'RS-1023',
          'สตูดิโอแสงเหนือ',
          'คุณธนา',
          '14 พ.ย. 2026',
          '13:00–16:00',
          2550,
        ),
        (
          'RS-1021',
          'Creative Loft Studio',
          'คุณพิม',
          '16 พ.ย. 2026',
          '09:00–11:00',
          2400,
        ),
      ].map((r) {
        final status = ownerRequestStatuses[r.$1] ?? 'รออนุมัติ';
        return Card(
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
                        r.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Chip(label: Text(status)),
                  ],
                ),
                Text('${r.$1} · ${r.$3}'),
                Text('${r.$4} · ${r.$5} · ฿${r.$6}'),
                if (status == 'รออนุมัติ') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(
                            () => ownerRequestStatuses[r.$1] = 'ปฏิเสธ',
                          ),
                          child: const Text('ปฏิเสธ'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => setState(
                            () => ownerRequestStatuses[r.$1] = 'ยืนยันแล้ว',
                          ),
                          child: const Text('ยืนยันการจอง'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status != 'รออนุมัติ')
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          _rentalDetail(r.$1, r.$2, r.$3, r.$4, status, r.$6),
                      child: const Text('ดูรายละเอียด'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    ],
  );

  Widget _bookingRequestCard(Booking booking) => Card(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Chip(label: Text(booking.status)),
            ],
          ),
          Text('${booking.id} · ${booking.renterName}'),
          Text('${booking.dateLabel} · ${booking.timeLabel}'),
          Text(
            'ผู้เช่าจ่าย ฿${booking.rentAmount} · หักค่าบริการ 5% เมื่อใช้บริการเสร็จ · เจ้าของรับสุทธิ ฿${booking.ownerNet}',
          ),
          if (booking.status == BookingStatus.ownerReview) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(
                      () => booking.status = BookingStatus.ownerRejected,
                    ),
                    child: const Text('ปฏิเสธ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(
                      () => booking.status = BookingStatus.paymentDue,
                    ),
                    child: const Text('อนุมัติคำขอ'),
                  ),
                ),
              ],
            ),
          ],
          if (booking.status == BookingStatus.confirmed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setState(() => booking.status = BookingStatus.completed),
                child: const Text('ทำเครื่องหมายว่าใช้บริการแล้ว'),
              ),
            ),
        ],
      ),
    ),
  );
}
