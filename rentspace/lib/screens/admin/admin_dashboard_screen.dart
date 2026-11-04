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
    _tabController = TabController(length: 3, vsync: this);
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
          tabs: const [
            Tab(icon: Icon(Icons.check_circle_outline), text: 'อนุมัติพื้นที่'),
            Tab(icon: Icon(Icons.people), text: 'จัดการผู้ใช้'),
            Tab(icon: Icon(Icons.history), text: 'บันทึกระบบ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Space Approval
          globalSpaces.isEmpty
              ? const Center(child: Text('ไม่มีรายการพื้นที่'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: globalSpaces.length,
                  itemBuilder: (context, index) {
                    final sp = globalSpaces[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Image.asset(
                          sp.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.meeting_room, size: 40),
                        ),
                        title: Text(sp.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'เจ้าของ: ${sp.ownerName} • สถานะ: ${sp.approvalStatus}'),
                        trailing: sp.approvalStatus == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white),
                                    onPressed: () {
                                      MockStore.approveSpace(sp, 'approved');
                                      setState(() {});
                                    },
                                    child: const Text('อนุมัติ'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      MockStore.approveSpace(sp, 'rejected');
                                      setState(() {});
                                    },
                                    child: const Text('ปฏิเสธ'),
                                  ),
                                ],
                              )
                            : Chip(
                                label: Text(sp.approvalStatus),
                                backgroundColor: sp.approvalStatus == 'approved'
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                              ),
                      ),
                    );
                  },
                ),

          // 2. Users Management
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: globalUsers.length,
            itemBuilder: (context, index) {
              final u = globalUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                        u.role.isNotEmpty ? u.role[0].toUpperCase() : 'U'),
                  ),
                  title: Text(u.fullName),
                  subtitle: Text(
                      'Username: ${u.username} • บทบาท: ${u.role}\nสถานะ: ${u.status}'),
                  trailing: u.role == 'admin'
                      ? null
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: u.status == 'active'
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            foregroundColor: u.status == 'active'
                                ? Colors.red
                                : Colors.green,
                          ),
                          onPressed: () {
                            MockStore.toggleUserStatus(
                              u.userId,
                              u.status == 'active' ? 'suspended' : 'active',
                            );
                            setState(() {});
                          },
                          child: Text(
                              u.status == 'active' ? 'ระงับบัญชี' : 'ปลดระงับ'),
                        ),
                ),
              );
            },
          ),

          // 3. Admin Audit Logs
          globalAdminLogs.isEmpty
              ? const Center(child: Text('ไม่มีบันทึกกิจกรรม'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: globalAdminLogs.length,
                  itemBuilder: (context, index) {
                    final log = globalAdminLogs[index];
                    return Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.security, color: Colors.blue),
                        title: Text(log.action,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${log.details}\nเวลา: ${log.formattedTime} โดย ${log.adminName}'),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
