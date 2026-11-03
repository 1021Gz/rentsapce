import 'package:flutter/material.dart';
import '../../controllers/rentspace_controller.dart';
import '../../main.dart';
import '../../models/app_models.dart';
import '../login_screen.dart';
import 'space_detail_screen.dart';

class RenterHomeTab extends StatefulWidget {
  const RenterHomeTab({super.key});

  @override
  State<RenterHomeTab> createState() => _RenterHomeTabState();
}

class _RenterHomeTabState extends State<RenterHomeTab> {
  String _searchFilterText = '';
  String _selectedCategory = 'All';
  double _priceLimit = 5000;

  final List<String> _categoryOptions = const [
    'All',
    'ห้องอ่านหนังสือ',
    'ห้องประชุม',
    'ห้องซ้อมดนตรี',
    'สตูดิโอ',
    'พื้นที่จัดเวิร์กช็อป',
  ];

  @override
  void initState() {
    super.initState();
    _refreshFromDatabase();
  }

  Future<void> _refreshFromDatabase() async {
    final syncSuccess = await MysqlApiBridge.syncFromDatabase();
    if (mounted && syncSuccess) setState(() {});
  }

  void _navigateToDetail(SpaceItem spaceRecord) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpaceDetailScreen(spaceRecord: spaceRecord),
      ),
    ).then((_) => _refreshFromDatabase());
  }

  void _executeLogout() {
    AuthController.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  List<SpaceItem> _filterSpaces() {
    final query = _searchFilterText.trim().toLowerCase();
    return globalSpaces.where((spaceRecord) {
      if (spaceRecord.approvalStatus != 'approved' || !spaceRecord.isActive) {
        return false;
      }
      final matchesQuery = query.isEmpty ||
          spaceRecord.name.toLowerCase().contains(query) ||
          spaceRecord.location.toLowerCase().contains(query) ||
          spaceRecord.address.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' ||
          spaceRecord.category == _selectedCategory ||
          spaceRecord.categoryLabel == _selectedCategory;
      final matchesPrice = spaceRecord.pricePerHour <= _priceLimit;
      return matchesQuery && matchesCategory && matchesPrice;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matchedSpaces = _filterSpaces();

    return ResponsiveFrame(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'RentSpace',
                    style: TextStyle(
                      color: Color(0xFFC3562C),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ค้นหา',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                'Renter — ค้นหาพื้นที่เช่า',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black45,
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
                  _buildHeroHeader(isDark),
                  const SizedBox(height: 20),
                  _buildSearchBar(theme, isDark),
                  const SizedBox(height: 16),
                  _buildCategoryScroll(theme, isDark),
                  const SizedBox(height: 16),
                  _buildPriceSlider(theme, isDark),
                  const SizedBox(height: 20),
                  _buildSpaceList(matchedSpaces, theme, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          height: 1.25,
        ),
        children: const [
          TextSpan(text: 'วันนี้อยากได้\n'),
          TextSpan(
            text: 'พื้นที่แบบไหน?',
            style: TextStyle(color: Color(0xFFC3562C)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white54 : Colors.black45,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (textString) =>
                  setState(() => _searchFilterText = textString),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อหรือย่าน',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScroll(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categoryOptions.map((categoryOption) {
          final isSelected = _selectedCategory == categoryOption;
          final displayTitle = categoryOption == 'All' ? 'ทั้งหมด' : categoryOption;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(displayTitle),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = categoryOption),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              selectedColor: const Color(0xFFC3562C),
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFC3562C)
                      : (isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8)),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSlider(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ราคาไม่เกิน ',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            Text(
              '${_priceLimit.toInt()} ฿/ชม.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFC3562C),
            thumbColor: const Color(0xFFC3562C),
            inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
            trackHeight: 4,
          ),
          child: Slider(
            min: 100,
            max: 5000,
            divisions: 49,
            value: _priceLimit.clamp(100, 5000),
            onChanged: (newAmount) => setState(() => _priceLimit = newAmount),
          ),
        ),
      ],
    );
  }

  Widget _buildSpaceList(List<SpaceItem> spaceEntries, ThemeData theme, bool isDark) {
    if (spaceEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: Text(
            'ไม่พบพื้นที่ที่ตรงเงื่อนไข',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black45,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: spaceEntries.map((spaceRecord) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: InkWell(
            onTap: () => _navigateToDetail(spaceRecord),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF283248) : const Color(0xFFE8E2D8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RentSpaceImage(
                    path: spaceRecord.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spaceRecord.categoryLabel,
                                    style: const TextStyle(
                                      color: Color(0xFFC3562C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    spaceRecord.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${spaceRecord.pricePerHour.toInt()}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  ' ฿/ชม.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildInfoTag(
                              Icons.location_on_outlined,
                              spaceRecord.location,
                              isDark,
                            ),
                            const SizedBox(width: 14),
                            _buildInfoTag(
                              Icons.people_outline_rounded,
                              '${spaceRecord.capacity} คน',
                              isDark,
                            ),
                            const SizedBox(width: 14),
                            _buildRatingTag(spaceRecord.rating, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoTag(IconData iconSymbol, String descriptionText, bool isDark) {
    return Row(
      children: [
        Icon(iconSymbol, size: 16, color: isDark ? Colors.white60 : Colors.black54),
        const SizedBox(width: 4),
        Text(
          descriptionText,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingTag(double scoreNumber, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
        const SizedBox(width: 3),
        Text(
          scoreNumber.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
