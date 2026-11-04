import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import 'payment_screen.dart';

class RenterMyBookingsTab extends StatefulWidget {
  const RenterMyBookingsTab({super.key});

  @override
  State<RenterMyBookingsTab> createState() => _RenterMyBookingsTabState();
}

class _RenterMyBookingsTabState extends State<RenterMyBookingsTab> {
  void _openReviewDialog(BookingItem b) {
    int rating = 5;
    final commentController = TextEditingController(text: b.reviewComment);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('ให้คะแนนและรีวิว'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'ความคิดเห็น (รีวิว)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () {
                b.rating = rating;
                b.reviewComment = commentController.text.trim();
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกรีวิวสำเร็จ ขอบคุณสำหรับข้อเสนอแนะ')),
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการจองของฉัน')),
      body: sampleBookings.isEmpty
          ? const Center(child: Text('ยังไม่มีประวัติการจอง'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sampleBookings.length,
              itemBuilder: (context, index) {
                final b = sampleBookings[index];
                Color statusColor = Colors.orange;
                String statusLabel = 'รอตรวจสอบ';
                if (b.status == 'confirmed') {
                  statusColor = Colors.green;
                  statusLabel = 'ยืนยันแล้ว';
                } else if (b.status == 'cancelled') {
                  statusColor = Colors.red;
                  statusLabel = 'ยกเลิกแล้ว';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b.spaceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Chip(
                              label: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: statusColor,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        Text('เวลา: ${b.startTime} - ${b.endTime}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '฿${b.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            Text(b.paid ? 'ชำระเงินแล้ว' : 'ยังไม่ชำระเงิน',
                                style: TextStyle(color: b.paid ? Colors.green : Colors.red, fontSize: 13)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!b.paid && b.status != 'cancelled')
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PaymentScreen(bookingRecord: b)),
                                  ).then((_) => setState(() {}));
                                },
                                child: const Text('ชำระเงิน'),
                              ),
                            if (b.paid) ...[
                              TextButton.icon(
                                onPressed: () => _openReviewDialog(b),
                                icon: const Icon(Icons.rate_review, size: 16),
                                label: Text(b.rating != null ? 'คะแนน: ${b.rating}★' : 'ให้คะแนนรีวิว'),
                              ),
                            ],
                            if (b.status == 'pending')
                              TextButton(
                                onPressed: () {
                                  b.status = 'cancelled';
                                  setState(() {});
                                },
                                child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
