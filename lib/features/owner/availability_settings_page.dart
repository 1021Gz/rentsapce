import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/availability_store.dart';

class AvailabilitySettingsPage extends StatefulWidget {
  const AvailabilitySettingsPage({super.key});
  @override
  State<AvailabilitySettingsPage> createState() =>
      _AvailabilitySettingsPageState();
}

class _AvailabilitySettingsPageState extends State<AvailabilitySettingsPage> {
  final days = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];
  final availability = AvailabilityStore.instance;
  List<bool> get open => availability.open;
  List<TimeOfDay> get starts => availability.starts;
  List<TimeOfDay> get ends => availability.ends;
  final blocks = <String>['10 พ.ย. 2026 · ปิดปรับปรุง'];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ตั้งเวลาว่าง')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'เวลาทำการประจำสัปดาห์',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const Text(
          'เลือกเวลาเปิดและปิดแยกแต่ละวัน ช่วงเวลานี้จะใช้ประกอบการค้นหาของผู้เช่า',
        ),
        const SizedBox(height: 12),
        ...List.generate(
          7,
          (i) => Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    value: open[i],
                    onChanged: (v) => setState(() => open[i] = v),
                    title: Text(days[i]),
                    subtitle: Text(
                      open[i]
                          ? '${starts[i].format(context)} – ${ends[i].format(context)}'
                          : 'ปิดรับจอง',
                    ),
                    secondary: const Icon(Icons.schedule, color: green),
                  ),
                  if (open[i])
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickTime(i, true),
                              icon: const Icon(Icons.login),
                              label: Text('เปิด ${starts[i].format(context)}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickTime(i, false),
                              icon: const Icon(Icons.logout),
                              label: Text('ปิด ${ends[i].format(context)}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'วันปิด/ช่วงเวลาปิด',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: _addBlock,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มช่วงปิด'),
            ),
          ],
        ),
        ...blocks.map(
          (b) => Card(
            child: ListTile(
              leading: const Icon(Icons.event_busy, color: Colors.deepOrange),
              title: Text(b),
              trailing: IconButton(
                onPressed: () => setState(() => blocks.remove(b)),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('บันทึกเวลาว่างแล้ว'))),
          child: const Text('บันทึกการตั้งค่า'),
        ),
      ],
    ),
  );

  Future<void> _pickTime(int day, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? starts[day] : ends[day],
    );
    if (picked == null || !mounted) return;
    final start = isStart ? picked : starts[day];
    final end = isStart ? ends[day] : picked;
    if ((end.hour * 60 + end.minute) <= (start.hour * 60 + start.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เวลาปิดต้องอยู่หลังเวลาเปิด')),
      );
      return;
    }
    setState(() {
      if (isStart) {
        starts[day] = picked;
      } else {
        ends[day] = picked;
      }
    });
  }

  void _addBlock() => setState(() => blocks.add('ช่วงปิดใหม่ · เลือกวันเวลา'));
}
