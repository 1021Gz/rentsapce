import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../../main.dart';
import '../../models/app_models.dart';

class PaymentScreen extends StatefulWidget {
  final BookingItem bookingRecord;
  final SpaceItem spaceRecord;

  const PaymentScreen({
    super.key,
    required this.bookingRecord,
    required this.spaceRecord,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  late final TextEditingController _slipRefController = TextEditingController(
    text: 'SLIP-${widget.bookingRecord.id}',
  );
  late final TextEditingController _slipImageController = TextEditingController(
    text: widget.bookingRecord.slipImageUrl.isNotEmpty
        ? widget.bookingRecord.slipImageUrl
        : '${MysqlApiBridge.baseUrl}/uploads/meeting.jpg',
  );

  @override
  void dispose() {
    _slipRefController.dispose();
    _slipImageController.dispose();
    super.dispose();
  }

  Future<void> _generateAndUploadSampleSlip() async {
    setState(() => _isProcessing = true);
    const tinyPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    final uploadedUrl = await MysqlApiBridge.uploadBase64Image(
      filename: 'slip_${widget.bookingRecord.id}.png',
      base64Data: tinyPngBase64,
    );
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        _slipImageController.text = uploadedUrl;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uploadedUrl != null
              ? 'อัปโหลดรูปสลิปไปยัง server/uploads/ สำเร็จ!'
              : 'ใช้ URL รูปสลิปที่ระบุเรียบร้อย',
        ),
        backgroundColor: const Color(0xFF2E633D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _executeTransferConfirmation() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      BookingController.markBookingPaid(
        widget.bookingRecord,
        paymentRef: _slipRefController.text,
        slipImageUrl: _slipImageController.text,
      );
      setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hoursCount = widget.bookingRecord.durationHours > 0
        ? widget.bookingRecord.durationHours
        : 1.0;
    final subtotalAmount = hoursCount * widget.spaceRecord.pricePerHour;
    final feeAmount = (subtotalAmount * 0.03).roundToDouble();
    final totalAmount = subtotalAmount + feeAmount;

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
              const SizedBox(width: 8),
              Text(
                '/ ชำระเงิน',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: const [
            ThemeToggleButton(),
            SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: widget.bookingRecord.paid
              ? _buildSuccessView(totalAmount, isDark)
              : _buildCheckoutView(
                  theme,
                  isDark,
                  hoursCount,
                  subtotalAmount,
                  feeAmount,
                  totalAmount,
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(double totalAmount, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E633D),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'ชำระเงินสำเร็จ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.spaceRecord.name} · ${widget.bookingRecord.startTime}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '฿${totalAmount.toInt().toString()}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC3562C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'กลับไปหน้าการจอง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutView(
    ThemeData theme,
    bool isDark,
    double hoursCount,
    double subtotalAmount,
    double feeAmount,
    double totalAmount,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ชำระเงิน',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildSpaceSummaryCard(theme, isDark, hoursCount),
          const SizedBox(height: 20),
          _buildPromptPayCard(theme, isDark, totalAmount),
          const SizedBox(height: 24),
          _buildFeeBreakdown(
            isDark,
            hoursCount,
            subtotalAmount,
            feeAmount,
            totalAmount,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _slipRefController,
            decoration: const InputDecoration(
              labelText: 'รหัสอ้างอิงสลิปการโอนเงิน (Slip Reference)',
              prefixIcon: Icon(Icons.receipt_long_rounded, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _slipImageController,
                  decoration: const InputDecoration(
                    labelText: 'รูปสลิปโอนเงิน (URL / server/uploads)',
                    prefixIcon: Icon(Icons.image_outlined, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC3562C),
                  side: const BorderSide(color: Color(0xFFC3562C)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing ? null : _generateAndUploadSampleSlip,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text(
                  'แนบสลิป',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC3562C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isProcessing ? null : _executeTransferConfirmation,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'ฉันโอนเงินแล้ว',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'หน้าตัวอย่าง — ไม่มีการตัดเงินจริง',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceSummaryCard(ThemeData theme, bool isDark, double hoursCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
        ),
      ),
      child: Row(
        children: [
          RentSpaceImage(
            path: widget.spaceRecord.imageUrl,
            width: 64,
            height: 64,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.spaceRecord.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.bookingRecord.startTime} (${hoursCount.toStringAsFixed(0)} ชม.)',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptPayCard(ThemeData theme, bool isDark, double totalAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192030) : const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, color: Color(0xFFC3562C), size: 22),
              SizedBox(width: 8),
              Text(
                'พร้อมเพย์',
                style: TextStyle(
                  color: Color(0xFFC3562C),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 180,
              height: 180,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 21,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                ),
                itemCount: 441,
                itemBuilder: (context, gridIndex) {
                  final rowCoordinate = gridIndex ~/ 21;
                  final columnCoordinate = gridIndex % 21;
                  final isCornerMarker =
                      (rowCoordinate < 7 && columnCoordinate < 7) ||
                      (rowCoordinate < 7 && columnCoordinate > 13) ||
                      (rowCoordinate > 13 && columnCoordinate < 7);
                  final isCornerEdge =
                      rowCoordinate == 0 ||
                      columnCoordinate == 0 ||
                      rowCoordinate == 6 ||
                      columnCoordinate == 6 ||
                      rowCoordinate == 14 ||
                      columnCoordinate == 14 ||
                      rowCoordinate == 20 ||
                      columnCoordinate == 20;
                  final isCornerCenter =
                      (rowCoordinate >= 2 &&
                          rowCoordinate <= 4 &&
                          columnCoordinate >= 2 &&
                          columnCoordinate <= 4) ||
                      (rowCoordinate >= 2 &&
                          rowCoordinate <= 4 &&
                          columnCoordinate >= 16 &&
                          columnCoordinate <= 18) ||
                      (rowCoordinate >= 16 &&
                          rowCoordinate <= 18 &&
                          columnCoordinate >= 2 &&
                          columnCoordinate <= 4);
                  final isPatternPixel =
                      (isCornerMarker && (isCornerEdge || isCornerCenter)) ||
                      (((gridIndex * 2654435761) & 0xFFFFFFFF) % 7 < 3);

                  return Container(
                    color: isPatternPixel
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'สแกนด้วยแอปธนาคารเพื่อชำระ ฿${totalAmount.toInt().toString()}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown(
    bool isDark,
    double hoursCount,
    double subtotalAmount,
    double feeAmount,
    double totalAmount,
  ) {
    return Column(
      children: [
        _buildPriceRow(
          'ค่าเช่า ${hoursCount.toStringAsFixed(0)} ชม. × ฿${widget.spaceRecord.pricePerHour.toInt()}',
          '฿${subtotalAmount.toInt()}',
          isBold: false,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildPriceRow(
          'ค่าธรรมเนียมแพลตฟอร์ม (3%)',
          '฿${feeAmount.toInt()}',
          isBold: false,
          isDark: isDark,
        ),
        Divider(
          height: 24,
          color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
        ),
        _buildPriceRow(
          'รวมทั้งหมด',
          '฿${totalAmount.toInt()}',
          isBold: true,
          textSize: 18,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String labelText,
    String priceText, {
    required bool isBold,
    required bool isDark,
    double textSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: textSize,
            color: isBold
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white60 : Colors.black54),
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          priceText,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold
                ? const Color(0xFFC3562C)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}
