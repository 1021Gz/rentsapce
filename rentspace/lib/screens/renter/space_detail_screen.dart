import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../../main.dart';
import '../../models/app_models.dart';

class SpaceDetailScreen extends StatefulWidget {
  final SpaceItem spaceRecord;

  const SpaceDetailScreen({
    super.key,
    required this.spaceRecord,
  });

  SpaceItem get space => spaceRecord;

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  DateTime _bookingDate = DateTime(2026, 11, 12);
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  DateTime get _startDateTimeObject => DateTime(
        _bookingDate.year,
        _bookingDate.month,
        _bookingDate.day,
        _startTime.hour,
        _startTime.minute,
      );

  DateTime get _endDateTimeObject => DateTime(
        _bookingDate.year,
        _bookingDate.month,
        _bookingDate.day,
        _endTime.hour,
        _endTime.minute,
      );

  Future<void> _selectBookingDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _bookingDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (pickedDate != null) {
      setState(() => _bookingDate = pickedDate);
    }
  }

  Future<void> _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (pickedTime != null) {
      setState(() => _startTime = pickedTime);
    }
  }

  Future<void> _selectEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (pickedTime != null) {
      setState(() => _endTime = pickedTime);
    }
  }

  void _dispatchBooking() {
    final outcome = BookingController.createBookingRequest(
      space: widget.spaceRecord,
      start: _startDateTimeObject,
      end: _endDateTimeObject,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.isSuccess ? 'ส่งคำขอจองแล้ว รอเจ้าของยืนยัน' : outcome.message,
        ),
        backgroundColor:
            outcome.isSuccess ? const Color(0xFF2E633D) : const Color(0xFFC53030),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (outcome.isSuccess) {
      Navigator.pop(context);
    }
  }

  String _formatTimeDisplay(TimeOfDay timeOfDay) {
    final hourString = timeOfDay.hour.toString().padLeft(2, '0');
    final minuteString = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }

  String _formatDateDisplay(DateTime dateTime) {
    final yearString = dateTime.year.toString();
    final monthString = dateTime.month.toString().padLeft(2, '0');
    final dayString = dateTime.day.toString().padLeft(2, '0');
    return '$yearString-$monthString-$dayString';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hoursCount =
        _endDateTimeObject.difference(_startDateTimeObject).inMinutes / 60.0;
    final hasConflict = BookingController.hasOverlap(
      spaceId: widget.spaceRecord.id,
      start: _startDateTimeObject,
      end: _endDateTimeObject,
    );

    final validationError = hoursCount <= 0
        ? 'เวลาสิ้นสุดต้องมากกว่าเวลาเริ่ม'
        : (hasConflict ? 'ช่วงเวลานี้ถูกจองแล้ว' : null);

    final totalCost = hoursCount > 0
        ? (hoursCount * widget.spaceRecord.pricePerHour).roundToDouble()
        : 0.0;

    final confirmedSlots = globalBookings
        .where(
          (booking) =>
              booking.spaceId == widget.spaceRecord.id &&
              booking.status == 'confirmed',
        )
        .toList();

    final spaceReviews = globalBookings
        .where(
          (booking) =>
              booking.spaceId == widget.spaceRecord.id &&
              booking.rating != null,
        )
        .toList();

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
                '/ รายละเอียด',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RentSpaceImage(
                  path: widget.spaceRecord.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.spaceRecord.categoryLabel,
                        style: const TextStyle(
                          color: Color(0xFFC3562C),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.spaceRecord.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildMetaRow(isDark),
                      const SizedBox(height: 16),
                      Text(
                        widget.spaceRecord.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBookingForm(
                        validationError,
                        confirmedSlots,
                        theme,
                        isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildReviewsSection(spaceReviews, theme, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomSheet: _buildBottomBar(
          hoursCount,
          totalCost,
          validationError != null,
          theme,
          isDark,
        ),
      ),
    );
  }

  Widget _buildMetaRow(bool isDark) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildMetaItem(
          Icons.location_on_outlined,
          widget.spaceRecord.address,
          isDark,
        ),
        _buildMetaItem(
          Icons.people_outline_rounded,
          'สูงสุด ${widget.spaceRecord.capacity} คน',
          isDark,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              widget.spaceRecord.rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaItem(IconData iconSymbol, String textContent, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconSymbol, size: 16, color: isDark ? Colors.white60 : Colors.black54),
        const SizedBox(width: 4),
        Text(
          textContent,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingForm(
    String? validationError,
    List<BookingItem> confirmedSlots,
    ThemeData theme,
    bool isDark,
  ) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'จองพื้นที่',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          _buildSelectorField(
            'วันที่',
            _formatDateDisplay(_bookingDate),
            _selectBookingDate,
            theme,
            isDark,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSelectorField(
                  'เริ่ม',
                  _formatTimeDisplay(_startTime),
                  _selectStartTime,
                  theme,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectorField(
                  'สิ้นสุด',
                  _formatTimeDisplay(_endTime),
                  _selectEndTime,
                  theme,
                  isDark,
                ),
              ),
            ],
          ),
          if (confirmedSlots.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'ตารางคิวที่ถูกจองแล้ว (Confirmed):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: confirmedSlots.map((slot) {
                final dateLabel =
                    '${slot.startDateTime.day.toString().padLeft(2, '0')}/${slot.startDateTime.month.toString().padLeft(2, '0')}';
                final startLabel =
                    '${slot.startDateTime.hour.toString().padLeft(2, '0')}:${slot.startDateTime.minute.toString().padLeft(2, '0')}';
                final endLabel =
                    '${slot.endDateTime.hour.toString().padLeft(2, '0')}:${slot.endDateTime.minute.toString().padLeft(2, '0')}';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC53030).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFC53030).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$dateLabel · $startLabel–$endLabel',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC53030),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (validationError != null) ...[
            const SizedBox(height: 12),
            Text(
              validationError,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC53030),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectorField(
    String fieldLabel,
    String valueDisplay,
    VoidCallback onTapAction,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fieldLabel,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTapAction,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141926) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
            child: Text(
              valueDisplay,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(
    List<BookingItem> spaceReviews,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'รีวิวจากผู้ใช้งาน (${spaceReviews.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  widget.spaceRecord.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (spaceReviews.isEmpty)
          Text(
            'ยังไม่มีความคิดเห็นสำหรับสถานที่นี้',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          )
        else
          ...spaceReviews.map((reviewEntry) {
            final starCount = reviewEntry.rating ?? 5;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF283248)
                        : const Color(0xFFE8E2D8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '@${reviewEntry.renterName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Row(
                          children: List.generate(5, (idx) {
                            return Icon(
                              idx < starCount
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 15,
                              color: const Color(0xFFF59E0B),
                            );
                          }),
                        ),
                      ],
                    ),
                    if (reviewEntry.reviewComment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reviewEntry.reviewComment,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildBottomBar(
    double hoursCount,
    double totalCost,
    bool isActionDisabled,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hoursCount > 0
                    ? '${hoursCount.toStringAsFixed(0)} ชม. × ${widget.spaceRecord.pricePerHour.toInt()} ฿'
                    : '—',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Text(
                '฿${totalCost.toInt().toString()}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC3562C),
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: isActionDisabled ? null : _dispatchBooking,
            child: const Text(
              'ขอจอง',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
