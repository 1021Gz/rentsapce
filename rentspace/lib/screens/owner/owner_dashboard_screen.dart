import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../../main.dart';
import '../../models/app_models.dart';
import '../login_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _refreshFromDatabase();
  }

  Future<void> _refreshFromDatabase() async {
    final syncSuccess = await MysqlApiBridge.syncFromDatabase();
    if (mounted && syncSuccess) setState(() {});
  }

  void _executeLogout() {
    AuthController.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _toggleSpaceActive(SpaceItem spaceRecord) {
    final outcome = SpaceController.toggleSpaceActive(spaceRecord);
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

  void _deleteSpace(SpaceItem spaceRecord) {
    final outcome = SpaceController.deleteSpace(spaceRecord);
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

  void _showSlipPreviewDialog(BookingItem bookingRecord) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'หลักฐานการโอนเงิน #${bookingRecord.id}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ผู้เช่า: @${bookingRecord.renterName}'),
              Text('ยอดโอน: ฿${bookingRecord.totalPrice.toInt()}'),
              if (bookingRecord.paymentRef.isNotEmpty)
                Text('รหัสอ้างอิง: ${bookingRecord.paymentRef}'),
              const SizedBox(height: 12),
              RentSpaceImage(
                path: bookingRecord.slipImageUrl.isNotEmpty
                    ? bookingRecord.slipImageUrl
                    : 'assets/images/meeting.jpg',
                height: 180,
                width: 260,
                borderRadius: BorderRadius.circular(14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  void _confirmBooking(BookingItem bookingRecord) {
    final hasConflict = BookingController.hasOverlap(
      spaceId: bookingRecord.spaceId,
      start: bookingRecord.startDateTime,
      end: bookingRecord.endDateTime,
      excludeBookingId: bookingRecord.id,
    );

    if (hasConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ช่วงเวลาชนกับการจองที่ยืนยันแล้ว'),
          backgroundColor: Color(0xFFC53030),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final outcome = BookingController.updateBookingStatusByOwner(
      booking: bookingRecord,
      newStatus: 'confirmed',
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.isSuccess ? 'ยืนยันการจองแล้ว' : outcome.message,
        ),
        backgroundColor: const Color(0xFF2E633D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectBooking(BookingItem bookingRecord) {
    final outcome = BookingController.updateBookingStatusByOwner(
      booking: bookingRecord,
      newStatus: 'rejected',
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.isSuccess ? 'ปฏิเสธการจองแล้ว' : outcome.message,
        ),
        backgroundColor: const Color(0xFFC53030),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddSpaceModal({SpaceItem? existingSpace}) {
    final isEditMode = existingSpace != null;
    final titleController = TextEditingController(
      text: existingSpace?.name ?? 'ห้องประชุมโมเดิร์น',
    );
    final locationController = TextEditingController(
      text: existingSpace?.address ?? 'อารีย์, กรุงเทพฯ',
    );
    final priceController = TextEditingController(
      text: existingSpace != null
          ? existingSpace.pricePerHour.toInt().toString()
          : '500',
    );
    final capacityController = TextEditingController(
      text: existingSpace != null ? existingSpace.capacity.toString() : '8',
    );
    final descriptionController = TextEditingController(
      text: existingSpace?.description ??
          'ห้องประชุมพร้อมจอสมาร์ททีวีและอินเทอร์เน็ตความเร็วสูง',
    );
    final imageUrlController = TextEditingController(
      text: existingSpace?.imageUrl ??
          '${MysqlApiBridge.baseUrl}/uploads/meeting.jpg',
    );

    const validCategories = [
      'ห้องอ่านหนังสือ',
      'ห้องประชุม',
      'ห้องซ้อมดนตรี',
      'สตูดิโอ',
      'พื้นที่จัดเวิร์กช็อป',
    ];
    final initialCategoryLabel = existingSpace != null
        ? existingSpace.categoryLabel
        : 'ห้องประชุม';
    String selectedCategory = validCategories.contains(initialCategoryLabel)
        ? initialCategoryLabel
        : 'ห้องประชุม';

    final serverUploadSamples = [
      ('ห้องประชุม', '${MysqlApiBridge.baseUrl}/uploads/meeting.jpg'),
      ('สตูดิโอ', '${MysqlApiBridge.baseUrl}/uploads/studio.jpg'),
      ('ดนตรี', '${MysqlApiBridge.baseUrl}/uploads/music.jpg'),
      ('อ่านหนังสือ', '${MysqlApiBridge.baseUrl}/uploads/study.jpg'),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        final isDark = Theme.of(bottomSheetContext).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditMode
                              ? 'แก้ไขข้อมูลพื้นที่'
                              : 'เพิ่มประกาศพื้นที่ใหม่',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสถานที่',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'หมวดหมู่',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ห้องอ่านหนังสือ',
                          child: Text('ห้องอ่านหนังสือ'),
                        ),
                        DropdownMenuItem(
                          value: 'ห้องประชุม',
                          child: Text('ห้องประชุม'),
                        ),
                        DropdownMenuItem(
                          value: 'ห้องซ้อมดนตรี',
                          child: Text('ห้องซ้อมดนตรี'),
                        ),
                        DropdownMenuItem(
                          value: 'สตูดิโอ',
                          child: Text('สตูดิโอ'),
                        ),
                        DropdownMenuItem(
                          value: 'พื้นที่จัดเวิร์กช็อป',
                          child: Text('พื้นที่จัดเวิร์กช็อป'),
                        ),
                      ],
                      onChanged: (categoryChoice) {
                        if (categoryChoice != null) {
                          setModalState(() => selectedCategory = categoryChoice);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'ที่อยู่ / ทำเล',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ราคา (฿/ชม.)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: capacityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ความจุ (คน)',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL รูปภาพ (จาก server/uploads หรือลิงก์)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: serverUploadSamples.map((sample) {
                        return ActionChip(
                          label: Text(
                            'รูป: ${sample.$1}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setModalState(() {
                              imageUrlController.text = sample.$2;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'คำอธิบายพื้นที่',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                        onPressed: () {
                          final parsedPrice =
                              double.tryParse(priceController.text) ?? 500.0;
                          final parsedCapacity =
                              int.tryParse(capacityController.text) ?? 5;
                          final chosenImageUrl =
                              imageUrlController.text.trim().isNotEmpty
                                  ? imageUrlController.text.trim()
                                  : 'assets/images/meeting.jpg';

                          final outcome = isEditMode
                              ? SpaceController.updateSpace(
                                  space: existingSpace,
                                  name: titleController.text,
                                  category: selectedCategory,
                                  address: locationController.text,
                                  pricePerHour: parsedPrice,
                                  capacity: parsedCapacity,
                                  description: descriptionController.text,
                                  imageUrls: [chosenImageUrl],
                                )
                              : SpaceController.createSpace(
                                  name: titleController.text,
                                  category: selectedCategory,
                                  address: locationController.text,
                                  pricePerHour: parsedPrice,
                                  capacity: parsedCapacity,
                                  description: descriptionController.text,
                                  imageUrls: [chosenImageUrl],
                                );
                          Navigator.pop(bottomSheetContext);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(outcome.message),
                              backgroundColor: const Color(0xFF2E633D),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          isEditMode ? 'บันทึกการแก้ไข' : 'ลงประกาศพื้นที่',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeUser = currentSessionUser;
    final ownerName = activeUser?.fullName ?? 'คุณภูมิ';

    final mySpaces = globalSpaces.where((spaceRecord) {
      if (activeUser == null) return true;
      return spaceRecord.ownerId == activeUser.userId ||
          spaceRecord.ownerName == activeUser.fullName;
    }).toList();

    final spaceIdSet = mySpaces.map((s) => s.id).toSet();
    final allRequests = globalBookings.where((bookingRecord) {
      return spaceIdSet.contains(bookingRecord.spaceId);
    }).toList();

    final pendingRequests = allRequests.where((b) => b.status == 'pending').toList();
    final confirmedRequests = allRequests
        .where((b) => b.status == 'confirmed' || b.status == 'completed')
        .toList();
    final totalPaidRevenue = confirmedRequests
        .where((b) => b.paid)
        .fold<double>(0.0, (sum, b) => sum + b.totalPrice);

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
                '/ เจ้าของ',
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
                    'สวัสดี $ownerName',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildStatsRow(
                    mySpaces.length,
                    pendingRequests.length,
                    confirmedRequests.length,
                    totalPaidRevenue,
                    isDark,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'คำขอจอง',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPendingSection(pendingRequests, theme, isDark),
                  if (confirmedRequests.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'รายการจองที่ยืนยันแล้ว',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildConfirmedSection(confirmedRequests, theme, isDark),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ประกาศของฉัน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF1B382B)
                              : const Color(0xFFE4F0E8),
                          foregroundColor: isDark
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFF2E633D),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _openAddSpaceModal,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'เพิ่ม',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMySpacesList(mySpaces, theme, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    int spaceCount,
    int pendingCount,
    int confirmedCount,
    double totalRevenue,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatBox('ประกาศ', spaceCount.toString(), isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatBox('รอตอบ', pendingCount.toString(), isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatBox('ยืนยัน', confirmedCount.toString(), isDark)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B382B) : const Color(0xFFE4F0E8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF2E633D),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ยอดรายได้ชำระแล้วรวม',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF2E633D),
                    ),
                  ),
                ],
              ),
              Text(
                '฿${totalRevenue.toInt()}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFF2E633D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String labelText, String countValue, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192030) : const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
        ),
      ),
      child: Column(
        children: [
          Text(
            countValue,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFFC3562C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            labelText,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection(
    List<BookingItem> pendingRequests,
    ThemeData theme,
    bool isDark,
  ) {
    if (pendingRequests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'ไม่มีคำขอใหม่',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
      );
    }

    return Column(
      children: pendingRequests.map((bookingRecord) {
        final spaceRecord = globalSpaces.firstWhere(
          (space) => space.id == bookingRecord.spaceId,
          orElse: () => globalSpaces.first,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spaceRecord.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${bookingRecord.renterName} · ${bookingRecord.startTime}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC3562C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _confirmBooking(bookingRecord),
                        child: const Text(
                          'ยอมรับ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.black87,
                          side: BorderSide(
                            color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _rejectBooking(bookingRecord),
                        child: const Text(
                          'ปฏิเสธ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmedSection(
    List<BookingItem> confirmedRequests,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      children: confirmedRequests.map((bookingRecord) {
        final spaceRecord = globalSpaces.firstWhere(
          (space) => space.id == bookingRecord.spaceId,
          orElse: () => globalSpaces.first,
        );
        final isPaid = bookingRecord.paid;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spaceRecord.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${bookingRecord.renterName} · ${bookingRecord.startTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      if (bookingRecord.paymentRef.isNotEmpty)
                        InkWell(
                          onTap: () => _showSlipPreviewDialog(bookingRecord),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 13,
                                  color: Color(0xFF2E633D),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ดูสลิป (${bookingRecord.paymentRef})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2E633D),
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '฿${bookingRecord.totalPrice.toInt()}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFE4F0E8)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isPaid ? 'ชำระแล้ว ✓' : 'รอชำระเงิน',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPaid
                              ? const Color(0xFF2E633D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMySpacesList(List<SpaceItem> spaceEntries, ThemeData theme, bool isDark) {
    return Column(
      children: spaceEntries.map((spaceRecord) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    RentSpaceImage(
                      path: spaceRecord.imageUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spaceRecord.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${spaceRecord.pricePerHour.toInt()} ฿/ชม. · ${spaceRecord.capacity} คน',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      status: spaceRecord.isActive
                          ? spaceRecord.approvalStatus
                          : 'hidden',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC3562C),
                        side: const BorderSide(color: Color(0xFFC3562C)),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          _openAddSpaceModal(existingSpace: spaceRecord),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text(
                        'แก้ไข',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: spaceRecord.isActive
                            ? (isDark ? Colors.white70 : Colors.black87)
                            : const Color(0xFF2E633D),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF283248)
                              : const Color(0xFFE8E2D8),
                        ),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _toggleSpaceActive(spaceRecord),
                      icon: Icon(
                        spaceRecord.isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 15,
                      ),
                      label: Text(
                        spaceRecord.isActive ? 'ปิดชั่วคราว' : 'เปิดแสดงผล',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'ลบประกาศพื้นที่',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFC53030),
                      ),
                      onPressed: () => _deleteSpace(spaceRecord),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
