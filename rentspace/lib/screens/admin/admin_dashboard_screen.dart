import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../../main.dart';
import '../../models/app_models.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _activeSegmentIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshFromDatabase();
  }

  Future<void> _refreshFromDatabase() async {
    final syncSuccess = await MysqlApiBridge.syncFromDatabase();
    if (mounted && syncSuccess) setState(() {});
  }

  void _executeLogout() {
    AuthController.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _updateSpaceStatus(SpaceItem spaceRecord, String targetStatus) {
    final outcome = AdminController.setSpaceApproval(
      space: spaceRecord,
      status: targetStatus,
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor: targetStatus == 'approved'
            ? const Color(0xFF2E633D)
            : const Color(0xFFC53030),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleUserSuspension(UserAccount userAccount) {
    final outcome = AdminController.toggleUserSuspension(userAccount);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor: outcome.isSuccess
            ? const Color(0xFF2E633D)
            : const Color(0xFFC53030),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelBookingByAdmin(BookingItem bookingRecord) {
    final outcome = AdminController.cancelBookingByAdmin(bookingRecord);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor: const Color(0xFFC53030),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pendingSpacesCount = globalSpaces
        .where((space) => space.approvalStatus == 'pending')
        .length;

    final estimatedRevenue = globalBookings
        .where((b) => b.status == 'completed' || b.status == 'confirmed')
        .fold<double>(0.0, (sum, b) => sum + b.totalPrice);

    return ResponsiveFrame(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text(
                'RentSpace',
                style: TextStyle(
                  color: Color(0xFFC3562C),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ แอดมิน',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'ซิงค์ฐานข้อมูล',
              icon: const Icon(Icons.sync_rounded, size: 20),
              onPressed: _refreshFromDatabase,
            ),
            const ThemeToggleButton(),
            IconButton(
              tooltip: 'ออกจากระบบ',
              icon: const Icon(Icons.logout_rounded),
              onPressed: _executeLogout,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshFromDatabase,
            color: const Color(0xFFC3562C),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ภาพรวมระบบ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildMetricsGrid(pendingSpacesCount, isDark),
                  const SizedBox(height: 12),
                  _buildRevenueBanner(estimatedRevenue),
                  const SizedBox(height: 24),
                  _buildSegmentSwitcher(isDark),
                  const SizedBox(height: 16),
                  _buildActiveSegmentContent(theme, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(int pendingCount, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard('ผู้ใช้ทั้งหมด', globalUsers.length, isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard('พื้นที่ทั้งหมด', globalSpaces.length, isDark),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard('การจอง', globalBookings.length, isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard('รออนุมัติ', pendingCount, isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String metricLabel, int countValue, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192030) : const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metricLabel,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            countValue.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBanner(double revenueAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFC3562C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'มูลค่าการจองโดยประมาณ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '฿${revenueAmount.toInt().toString()}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentSwitcher(bool isDark) {
    final segmentTitles = ['พื้นที่', 'ผู้ใช้', 'การจอง', 'ประวัติ'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192030) : const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
        ),
      ),
      child: Row(
        children: List.generate(segmentTitles.length, (segmentIndex) {
          final isSelected = _activeSegmentIndex == segmentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSegmentIndex = segmentIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF242C3D) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  segmentTitles[segmentIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFFC3562C)
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveSegmentContent(ThemeData theme, bool isDark) {
    switch (_activeSegmentIndex) {
      case 0:
        return _buildSpacesTab(theme, isDark);
      case 1:
        return _buildUsersTab(theme, isDark);
      case 2:
        return _buildBookingsTab(theme, isDark);
      case 3:
      default:
        return _buildLogsTab(theme, isDark);
    }
  }

  Widget _buildSpacesTab(ThemeData theme, bool isDark) {
    return Column(
      children: globalSpaces.map((spaceRecord) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        spaceRecord.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusPill(status: spaceRecord.approvalStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@${spaceRecord.ownerName} · ${spaceRecord.categoryLabel}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (spaceRecord.approvalStatus != 'approved') ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC3562C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            _updateSpaceStatus(spaceRecord, 'approved'),
                        child: const Text('อนุมัติ'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (spaceRecord.approvalStatus == 'pending') ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC53030),
                          side: const BorderSide(color: Color(0xFFFDE8E8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            _updateSpaceStatus(spaceRecord, 'rejected'),
                        child: const Text('ปฏิเสธ'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (spaceRecord.approvalStatus == 'approved') ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.black54,
                          side: BorderSide(
                            color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            _updateSpaceStatus(spaceRecord, 'hidden'),
                        child: const Text('ซ่อน'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsersTab(ThemeData theme, bool isDark) {
    return Column(
      children: globalUsers.map((userAccount) {
        final isSuspended = userAccount.status == 'suspended';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userAccount.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${userAccount.username} · ${userAccount.role}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isSuspended ? const Color(0xFF2E633D) : const Color(0xFFC53030),
                    side: BorderSide(
                      color: isSuspended
                          ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFE4F0E8))
                          : (isDark ? const Color(0xFF3B1818) : const Color(0xFFFDE8E8)),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _toggleUserSuspension(userAccount),
                  child: Text(
                    isSuspended ? 'เปิดใช้งาน' : 'ระงับ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingsTab(ThemeData theme, bool isDark) {
    return Column(
      children: globalBookings.map((bookingRecord) {
        final canCancel = bookingRecord.status == 'pending' ||
            bookingRecord.status == 'confirmed';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingRecord.spaceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${bookingRecord.renterName} · ${bookingRecord.startTime}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusPill(status: bookingRecord.status),
                    if (canCancel) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _cancelBookingByAdmin(bookingRecord),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC53030),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogsTab(ThemeData theme, bool isDark) {
    if (globalAdminLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'ยังไม่มีประวัติการทำงานของแอดมิน',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ),
      );
    }

    return Column(
      children: globalAdminLogs.map((logRecord) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC3562C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        logRecord.action,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC3562C),
                        ),
                      ),
                    ),
                    Text(
                      logRecord.formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  logRecord.details,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'โดย ${logRecord.adminName} · เป้าหมาย: ${logRecord.targetType} #${logRecord.targetId}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
