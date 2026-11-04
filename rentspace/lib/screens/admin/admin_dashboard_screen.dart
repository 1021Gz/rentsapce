import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout() {
    currentUser = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ผู้ดูแลระบบ (Admin)'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'ภาพรวมระบบ'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'อนุมัติพื้นที่'),
            Tab(icon: Icon(Icons.people_outline), text: 'จัดการผู้ใช้'),
            Tab(icon: Icon(Icons.history), text: 'บันทึกระบบ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsOverview(),
          _buildSpaceApprovalList(),
          _buildUserManagementList(),
          _buildAuditLogsList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    final pendingCount =
        globalSpaces.where((space) => space.approvalStatus == 'pending').length;
    final approvedCount =
        globalSpaces.where((space) => space.approvalStatus == 'approved').length;
    final totalRevenue = globalBookings
        .where((booking) => booking.status == 'confirmed')
        .fold(0.0, (sum, booking) => sum + booking.totalPrice);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถิติภาพรวมแพลตฟอร์ม',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'ผู้ใช้งานทั้งหมด',
                  value: '${globalUsers.length} คน',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'พื้นที่เช่าทั้งหมด',
                  value: '${globalSpaces.length} แห่ง',
                  icon: Icons.apartment,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'การจองทั้งหมด',
                  value: '${globalBookings.length} ครั้ง',
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'ยอดเงินสำเร็จ',
                  value: '฿${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.payments,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สถานะงานค้างตรวจสอบ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: pendingCount > 0
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      child: Icon(
                        pendingCount > 0 ? Icons.warning_amber : Icons.done_all,
                        color: pendingCount > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                    title: Text('พื้นที่รอแอดมินอนุมัติ: $pendingCount แห่ง'),
                    subtitle: Text('อนุมัติแล้ว: $approvedCount แห่ง'),
                    trailing: pendingCount > 0
                        ? ElevatedButton(
                            onPressed: () => _tabController.animateTo(1),
                            child: const Text('ตรวจทันที'),
                          )
                        : const Chip(label: Text('เรียบร้อย')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withAlpha(30),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceApprovalList() {
    if (globalSpaces.isEmpty) {
      return const Center(child: Text('ไม่มีรายการพื้นที่'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: globalSpaces.length,
      itemBuilder: (context, index) {
        final space = globalSpaces[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Image.asset(
              space.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  const Icon(Icons.meeting_room, size: 40),
            ),
            title: Text(space.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'เจ้าของ: ${space.ownerName}\n฿${space.pricePerHour.toStringAsFixed(0)}/ชม. • สถานะ: ${space.approvalStatus}'),
            trailing: _buildSpaceActionButtons(space),
          ),
        );
      },
    );
  }

  Widget _buildSpaceActionButtons(SpaceItem space) {
    if (space.approvalStatus == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              MockStore.approveSpace(space, 'approved');
              setState(() {});
            },
            child: const Text('อนุมัติ'),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              MockStore.approveSpace(space, 'rejected');
              setState(() {});
            },
            child: const Text('ปฏิเสธ'),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Chip(
          visualDensity: VisualDensity.compact,
          label: Text(space.approvalStatus),
          backgroundColor: space.approvalStatus == 'approved'
              ? Colors.green.shade100
              : Colors.red.shade100,
        ),
        if (space.approvalStatus == 'approved') ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'ซ่อนพื้นที่นี้',
            icon: const Icon(Icons.visibility_off, color: Colors.grey, size: 20),
            onPressed: () {
              MockStore.approveSpace(space, 'rejected');
              setState(() {});
            },
          ),
        ],
      ],
    );
  }

  Widget _buildUserManagementList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: globalUsers.length,
      itemBuilder: (context, index) {
        final targetUser = globalUsers[index];
        final isActive = targetUser.status == 'active';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: targetUser.role == 'admin'
                  ? Colors.purple.shade100
                  : targetUser.role == 'owner'
                      ? Colors.orange.shade100
                      : Colors.blue.shade100,
              child: Text(
                targetUser.role.isNotEmpty
                    ? targetUser.role[0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(targetUser.fullName),
            subtitle: Text(
                'ชื่อผู้ใช้: ${targetUser.username} • บทบาท: ${targetUser.role}\nสถานะ: ${targetUser.status}'),
            trailing: targetUser.role == 'admin'
                ? const Chip(label: Text('ผู้ดูแล'), visualDensity: VisualDensity.compact)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isActive ? Colors.red.shade50 : Colors.green.shade50,
                      foregroundColor: isActive ? Colors.red : Colors.green,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      MockStore.toggleUserStatus(
                        targetUser.userId,
                        isActive ? 'suspended' : 'active',
                      );
                      setState(() {});
                    },
                    child: Text(isActive ? 'ระงับบัญชี' : 'ปลดระงับ'),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsList() {
    if (globalAdminLogs.isEmpty) {
      return const Center(child: Text('ไม่มีบันทึกกิจกรรม'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: globalAdminLogs.length,
      itemBuilder: (context, index) {
        final singleLog = globalAdminLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.security, color: Colors.blue),
            title: Text(singleLog.action,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${singleLog.details}\nเวลา: ${singleLog.formattedTime} โดย ${singleLog.adminName}'),
          ),
        );
      },
    );
  }
}
