import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/space.dart';
import '../../data/demo_spaces.dart';
import '../payments/checkout_page.dart';
import '../payments/bank_transfer_page.dart';
import '../admin/slip_review_page.dart';
import '../owner/payout_page.dart';
import '../auth/login_page.dart';
import '../renter/booking_detail_page.dart';
import '../owner/availability_settings_page.dart';
import '../owner/edit_space_page.dart';
import '../../data/booking_store.dart';
import '../../data/availability_store.dart';
import '../../models/booking.dart';
import '../admin/issues_page.dart';
part 'pages/renter/explore_page.dart';
part 'pages/renter/bookings_page.dart';
part 'pages/renter/favorites_page.dart';
part 'pages/shared/profile_page.dart';
part 'pages/owner/rental_history_page.dart';
part 'pages/owner/calendar_page.dart';
part 'pages/owner/dashboard_page.dart';
part 'pages/owner/spaces_page.dart';
part 'pages/owner/booking_requests_page.dart';
part 'pages/owner/reservations_page.dart';
part 'pages/admin/dashboard_page.dart';
part 'pages/admin/approvals_page.dart';
part 'pages/admin/reports_page.dart';
part 'pages/admin/bookings_page.dart';
part 'pages/admin/audit_logs_page.dart';
part 'pages/admin/users_page.dart';
part 'pages/admin/operations_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.role});
  final String role;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  String query = '', category = 'ทั้งหมด', historyFilter = 'ทั้งหมด';
  final Set<String> favorites = {};
  final Map<String, String> ownerRequestStatuses = {
    'RS-1024': 'รออนุมัติ',
    'RS-1023': 'ยืนยันแล้ว',
    'RS-1021': 'รออนุมัติ',
  };
  String get pageTitle => widget.role == 'ผู้เช่า'
      ? ['ค้นหาพื้นที่', 'การจองของฉัน', 'รายการโปรด', 'โปรไฟล์'][index]
      : widget.role == 'เจ้าของพื้นที่'
      ? ['ภาพรวม', 'พื้นที่ของฉัน', 'การจอง', 'รายรับ', 'โปรไฟล์'][index]
      : [
          'Dashboard',
          'ตรวจสอบ',
          'การเงิน',
          'จัดการผู้ใช้',
          'บันทึกกิจกรรม',
        ][index];
  @override
  Widget build(BuildContext context) {
    final pages = widget.role == 'ผู้เช่า'
        ? [_browse(), _bookingPage(), _favoritePage(), _profile()]
        : widget.role == 'เจ้าของพื้นที่'
        ? [
            _ownerDash(),
            _mySpaces(),
            _ownerReservations(),
            const OwnerPayoutPage(),
            _profile(),
          ]
        : [
            _adminDash(),
            _adminModerationCenter(),
            _adminFinanceCenter(),
            _users(),
            _adminLogs(),
          ];
    final labels = widget.role == 'ผู้เช่า'
        ? ['ค้นหา', 'การจอง', 'รายการโปรด', 'โปรไฟล์']
        : widget.role == 'เจ้าของพื้นที่'
        ? ['ภาพรวม', 'พื้นที่', 'การจอง', 'รายรับ', 'โปรไฟล์']
        : ['Dashboard', 'ตรวจสอบ', 'การเงิน', 'ผู้ใช้', 'Log'];
    final icons = widget.role == 'ผู้เช่า'
        ? [
            Icons.search,
            Icons.event_note,
            Icons.favorite_border,
            Icons.person_outline,
          ]
        : widget.role == 'เจ้าของพื้นที่'
        ? [
            Icons.dashboard_outlined,
            Icons.home_work_outlined,
            Icons.event_available,
            Icons.account_balance_wallet_outlined,
            Icons.person_outline,
          ]
        : [
            Icons.dashboard_outlined,
            Icons.rule_folder_outlined,
            Icons.account_balance_outlined,
            Icons.people_outline,
            Icons.history,
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'rentSPACE',
          style: TextStyle(color: green, fontWeight: FontWeight.w900),
        ),
        actions: [
          Center(
            child: Text(
              widget.role,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width > 750)
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (v) => setState(() => index = v),
              labelType: NavigationRailLabelType.all,
              destinations: List.generate(
                labels.length,
                (i) => NavigationRailDestination(
                  icon: Icon(icons[i]),
                  label: Text(labels[i]),
                ),
              ),
            ),
          Expanded(child: pages[index]),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width <= 750
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (v) => setState(() => index = v),
              destinations: List.generate(
                labels.length,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  label: labels[i],
                ),
              ),
            )
          : null,
    );
  }

  Widget _stat(String title, String value) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 600 ? 150 : 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: green,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
