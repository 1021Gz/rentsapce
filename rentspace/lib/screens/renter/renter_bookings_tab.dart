import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../../main.dart';
import '../../models/app_models.dart';
import '../login_screen.dart';
import 'payment_screen.dart';

class RenterMyBookingsTab extends StatefulWidget {
  const RenterMyBookingsTab({super.key});

  @override
  State<RenterMyBookingsTab> createState() => _RenterMyBookingsTabState();
}

class _RenterMyBookingsTabState extends State<RenterMyBookingsTab> {
  @override
  void initState() {
    super.initState();
    _refreshFromDatabase();
  }

  Future<void> _refreshFromDatabase() async {
    final syncSuccess = await MysqlApiBridge.syncFromDatabase();
    if (mounted && syncSuccess) setState(() {});
  }

  void _executeCancellation(BookingItem bookingRecord) {
    final outcome = BookingController.cancelByRenter(bookingRecord);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor:
            outcome.isSuccess ? const Color(0xFF2E633D) : const Color(0xFFC53030),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToPayment(BookingItem bookingRecord, SpaceItem spaceRecord) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          bookingRecord: bookingRecord,
          spaceRecord: spaceRecord,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openReviewModal(BookingItem bookingRecord, SpaceItem spaceRecord) {
    int chosenStars = bookingRecord.rating ?? 5;
    final commentController = TextEditingController(
      text: bookingRecord.reviewComment,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ให้คะแนน ${spaceRecord.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (starIdx) {
                      final starVal = starIdx + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= chosenStars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 36,
                        ),
                        onPressed: () =>
                            setModalState(() => chosenStars = starVal),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ความคิดเห็นเพิ่มเติม',
                      hintText: 'บรรยากาศดี อุปกรณ์ครบครัน...',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC3562C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final outcome = BookingController.submitBookingReview(
                          booking: bookingRecord,
                          ratingScore: chosenStars,
                          reviewComment: commentController.text,
                        );
                        Navigator.pop(modalContext);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(outcome.message),
                            backgroundColor: const Color(0xFF2E633D),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'ส่งรีวิว',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _executeLogout() {
    AuthController.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeUser = currentSessionUser;
    final myBookings = globalBookings.where((bookingRecord) {
      if (activeUser == null) return true;
      return bookingRecord.renterId == activeUser.userId ||
          bookingRecord.renterName == activeUser.fullName;
    }).toList();

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
                '/ การจอง',
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
                  'การจองของฉัน',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 18),
                if (myBookings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(
                      child: Text(
                        'ยังไม่มีรายการจอง',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...myBookings.map((bookingRecord) {
                    final spaceRecord = globalSpaces.firstWhere(
                      (space) => space.id == bookingRecord.spaceId,
                      orElse: () => globalSpaces.first,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF283248)
                                : const Color(0xFFE8E2D8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.03,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RentSpaceImage(
                              path: spaceRecord.imageUrl,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          spaceRecord.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      StatusPill(status: bookingRecord.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${bookingRecord.startTime} (${bookingRecord.durationHours.toStringAsFixed(0)} ชม.)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '฿${bookingRecord.totalPrice.toInt()}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      _buildActionButtons(
                                        bookingRecord,
                                        spaceRecord,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BookingItem bookingRecord,
    SpaceItem spaceRecord,
  ) {
    final canCancel = bookingRecord.status == 'pending' ||
        (bookingRecord.status == 'confirmed' && !bookingRecord.paid);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bookingRecord.status == 'confirmed' && !bookingRecord.paid) ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC3562C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _navigateToPayment(bookingRecord, spaceRecord),
            child: const Text(
              'ชำระเงิน',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (bookingRecord.paid) ...[
          const Text(
            'ชำระแล้ว ✓',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E633D),
            ),
          ),
          const SizedBox(width: 6),
          if (bookingRecord.rating == null)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _openReviewModal(bookingRecord, spaceRecord),
              child: const Text(
                '★ รีวิว',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            )
          else
            Text(
              '★ ${bookingRecord.rating}/5',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF59E0B),
              ),
            ),
          const SizedBox(width: 6),
        ],
        if (canCancel)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC53030),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _executeCancellation(bookingRecord),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
