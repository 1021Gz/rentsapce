import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import 'payment_screen.dart';

class SpaceDetailScreen extends StatefulWidget {
  final SpaceItem spaceRecord;

  const SpaceDetailScreen({super.key, required this.spaceRecord});

  SpaceItem get space => spaceRecord;

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  DateTime get _startDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

  DateTime get _endDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

  double get _totalHours {
    final diff = _endDateTime.difference(_startDateTime).inMinutes;
    return diff > 0 ? diff / 60.0 : 0.0;
  }

  double get _totalPrice => _totalHours * widget.space.pricePerHour;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _confirmBooking() {
    if (_totalHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น')),
      );
      return;
    }

    final newBooking = BookingItem(
      id: sampleBookings.length + 1,
      renterId: 1002,
      renterName: 'ณัฐ วงศ์ดี',
      spaceId: widget.space.id,
      spaceName: widget.space.name,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      totalPrice: _totalPrice,
      status: 'pending',
    );

    sampleBookings.insert(0, newBooking);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งคำขอจองพื้นที่สำเร็จ')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(bookingRecord: newBooking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = widget.space;

    return Scaffold(
      appBar: AppBar(title: Text(sp.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              sp.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                height: 220,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sp.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(sp.rating.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${sp.categoryLabel} • ${sp.location}', style: TextStyle(color: Colors.grey.shade700)),
                  Text(sp.address, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const Divider(height: 24),
                  const Text('รายละเอียดพื้นที่', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(sp.description, style: const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 18, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text('ความจุสูงสุด ${sp.capacity} คน'),
                      const SizedBox(width: 24),
                      const Icon(Icons.attach_money, size: 18, color: Colors.green),
                      Text('฿${sp.pricePerHour.toStringAsFixed(0)} / ชั่วโมง'),
                    ],
                  ),
                  const Divider(height: 28),
                  const Text('เลือกวันและเวลาที่ต้องการจอง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.calendar_month, color: Colors.blue),
                            title: const Text('วันที่จอง'),
                            subtitle: Text('${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                            trailing: TextButton(onPressed: _pickDate, child: const Text('เปลี่ยนวัน')),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: const Text('เริ่ม'),
                                  subtitle: Text(_startTime.format(context)),
                                  onTap: () => _pickTime(true),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: const Text('ถึง'),
                                  subtitle: Text(_endTime.format(context)),
                                  onTap: () => _pickTime(false),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('รวม $_totalHours ชั่วโมง', style: const TextStyle(fontSize: 15)),
                                Text(
                                  'ยอดรวม: ฿${_totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _confirmBooking,
                      child: const Text('จองพื้นที่นี้ (ดำเนินการชำระเงิน)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
