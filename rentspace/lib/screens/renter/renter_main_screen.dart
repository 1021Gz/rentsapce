import 'package:flutter/material.dart';
import '../../main.dart';
import 'renter_bookings_tab.dart';
import 'renter_home_tab.dart';
import 'renter_profile_tab.dart';

class RenterMainScreen extends StatefulWidget {
  const RenterMainScreen({super.key});

  @override
  State<RenterMainScreen> createState() => _RenterMainScreenState();
}

class _RenterMainScreenState extends State<RenterMainScreen> {
  int _tabIndex = 0;
  final List<Widget> _tabScreens = const [
    RenterHomeTab(),
    RenterMyBookingsTab(),
    RenterProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ResponsiveFrame(
      child: Scaffold(
        body: _tabScreens[_tabIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _tabIndex,
            onTap: (selectedDestination) =>
                setState(() => _tabIndex = selectedDestination),
            selectedItemColor: const Color(0xFFC3562C),
            unselectedItemColor: isDark ? Colors.white38 : Colors.black45,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.cardColor,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'ค้นหา',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today_rounded),
                label: 'การจอง',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
