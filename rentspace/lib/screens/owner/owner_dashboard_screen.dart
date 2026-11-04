import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../login_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddSpaceDialog() {
    final titleController = TextEditingController();
    final locController = TextEditingController();
    final addressController = TextEditingController();
    final priceController = TextEditingController();
    final capacityController = TextEditingController();
    final descController = TextEditingController();
    String category = 'meeting_room';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('ลงประกาศพื้นที่ใหม่'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'ชื่อพื้นที่'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'หมวดหมู่'),
                  items: const [
                    DropdownMenuItem(
                        value: 'meeting_room', child: Text('ห้องประชุม')),
                    DropdownMenuItem(
                        value: 'study_room', child: Text('ห้องอ่านหนังสือ')),
                    DropdownMenuItem(
                        value: 'music_room', child: Text('ห้องซ้อมดนตรี')),
                    DropdownMenuItem(value: 'studio', child: Text('สตูดิโอ')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? 'meeting_room'),
                ),
                TextField(
                  controller: locController,
                  decoration: const InputDecoration(
                      labelText: 'ย่าน/ทำเล (เช่น อารีย์)'),
                ),
                TextField(
                  controller: addressController,
                  decoration:
                      const InputDecoration(labelText: 'ที่อยู่โดยละเอียด'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                      labelText: 'ราคาต่อชั่วโมง (บาท)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: 'ความจุ (คน)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'รายละเอียด'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(priceController.text) ?? 500;
                final cap = int.tryParse(capacityController.text) ?? 10;
                MockStore.addSpace(
                  name: titleController.text,
                  category: category,
                  location: locController.text,
                  address: addressController.text,
                  pricePerHour: price,
                  capacity: cap,
                  description: descController.text,
                );
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('เพิ่มพื้นที่สำเร็จ รอแอดมินตรวจสอบ')),
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
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
    final mySpaces = globalSpaces
        .where((s) => s.ownerId == (currentUser?.userId ?? 1001))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('เจ้าของพื้นที่ (Owner Dashboard)'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.apartment), text: 'พื้นที่ของฉัน'),
            Tab(icon: Icon(Icons.assignment), text: 'คำขอจอง'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSpaceDialog,
        icon: const Icon(Icons.add),
        label: const Text('ลงประกาศพื้นที่'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Spaces
          mySpaces.isEmpty
              ? const Center(child: Text('ยังไม่มีพื้นที่ที่ลงประกาศ'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: mySpaces.length,
                  itemBuilder: (context, index) {
                    final sp = mySpaces[index];
                    return Card(
                      child: ListTile(
                        leading: Image.asset(
                          sp.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.meeting_room, size: 40),
                        ),
                        title: Text(sp.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${sp.categoryLabel} • ฿${sp.pricePerHour.toStringAsFixed(0)}/ชม.\nสถานะ: ${sp.approvalStatus}'),
                        trailing: Switch(
                          value: sp.isActive,
                          onChanged: (val) {
                            setState(() => sp.isActive = val);
                          },
                        ),
                      ),
                    );
                  },
                ),

          // Tab 2: Bookings
          globalBookings.isEmpty
              ? const Center(child: Text('ยังไม่มีคำขอจอง'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: globalBookings.length,
                  itemBuilder: (context, index) {
                    final b = globalBookings[index];
                    return Card(
                      child: ListTile(
                        title: Text('${b.spaceName} (โดย ${b.renterName})'),
                        subtitle: Text(
                            'เวลา: ${b.startTime} - ${b.endTime}\nยอดเงิน: ฿${b.totalPrice.toStringAsFixed(0)} • สถานะ: ${b.status}'),
                        trailing: b.status == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    onPressed: () {
                                      MockStore.updateBookingStatus(
                                          b.id, 'confirmed');
                                      setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.red),
                                    onPressed: () {
                                      MockStore.updateBookingStatus(
                                          b.id, 'cancelled');
                                      setState(() {});
                                    },
                                  ),
                                ],
                              )
                            : Chip(label: Text(b.status)),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
