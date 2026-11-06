import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AdminIssuesPage extends StatefulWidget {
  const AdminIssuesPage({super.key});
  @override
  State<AdminIssuesPage> createState() => _AdminIssuesPageState();
}

class _AdminIssuesPageState extends State<AdminIssuesPage> {
  final items = <Map<String, String>>[
    {
      'id': 'ISS-204',
      'booking': 'RS-582941',
      'title': 'พื้นที่ไม่ตรงกับรายละเอียด',
      'from': 'คุณมินตรา',
      'status': 'เปิดใหม่',
    },
    {
      'id': 'ISS-203',
      'booking': 'RS-582812',
      'title': 'เจ้าของยกเลิกหลังยืนยัน',
      'from': 'คุณธนา',
      'status': 'กำลังตรวจสอบ',
    },
  ];
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'ปัญหาและข้อพิพาท',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text('ตรวจสอบเรื่องร้องเรียนที่ผูกกับรายการจอง'),
      const SizedBox(height: 12),
      ...items.map(
        (x) => Card(
          child: ListTile(
            leading: const Icon(Icons.support_agent, color: green),
            title: Text(x['title']!),
            subtitle: Text('${x['id']} · ${x['booking']} · ${x['from']}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => setState(() => x['status'] = v),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'กำลังตรวจสอบ',
                  child: Text('รับเรื่องตรวจสอบ'),
                ),
                PopupMenuItem(
                  value: 'รอข้อมูลเพิ่ม',
                  child: Text('ขอข้อมูลเพิ่ม'),
                ),
                PopupMenuItem(value: 'ปิดเรื่องแล้ว', child: Text('ปิดเรื่อง')),
              ],
              child: Chip(label: Text(x['status']!)),
            ),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(x['title']!),
                content: Text(
                  'เลขปัญหา ${x['id']}\nBooking ${x['booking']}\nผู้แจ้ง ${x['from']}\n\nตรวจประวัติการจองและหลักฐานประกอบก่อนพิจารณา',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('ปิด'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
