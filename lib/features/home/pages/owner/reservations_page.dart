// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension OwnerReservationsPage on _HomePageState {
  Widget _ownerReservations() => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'การจอง',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const TabBar(
          tabs: [
            Tab(text: 'คำขอ'),
            Tab(text: 'ปฏิทิน'),
            Tab(text: 'ประวัติ'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _ownerBookingRequests(),
              _ownerCalendar(),
              _rentalHistory(),
            ],
          ),
        ),
      ],
    ),
  );
}
