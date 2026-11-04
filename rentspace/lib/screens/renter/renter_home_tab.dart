import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import 'space_detail_screen.dart';

class RenterHomeTab extends StatefulWidget {
  const RenterHomeTab({super.key});

  @override
  State<RenterHomeTab> createState() => _RenterHomeTabState();
}

class _RenterHomeTabState extends State<RenterHomeTab> {
  String _searchText = '';
  String _selectedCategory = 'ทั้งหมด';

  final List<String> _categories = const [
    'ทั้งหมด',
    'ห้องประชุม',
    'ห้องอ่านหนังสือ',
    'ห้องซ้อมดนตรี',
    'สตูดิโอ',
  ];

  List<SpaceItem> get _filteredSpaces {
    return sampleSpaces.where((space) {
      if (space.approvalStatus != 'approved' || !space.isActive) return false;
      if (_selectedCategory != 'ทั้งหมด' && space.categoryLabel != _selectedCategory) {
        return false;
      }
      if (_searchText.isNotEmpty) {
        final query = _searchText.toLowerCase();
        final matchTitle = space.name.toLowerCase().contains(query);
        final matchLoc = space.location.toLowerCase().contains(query);
        if (!matchTitle && !matchLoc) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredSpaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renter — ค้นหาพื้นที่เช่า'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อพื้นที่ หรือทำเล...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (text) => setState(() => _searchText = text),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('ไม่พบพื้นที่ที่ค้นหา'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final space = list[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SpaceDetailScreen(spaceRecord: space),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                space.imageUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  height: 160,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            space.name,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, size: 16, color: Colors.amber),
                                            const SizedBox(width: 4),
                                            Text(space.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${space.categoryLabel} • ${space.location}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '฿${space.pricePerHour.toStringAsFixed(0)} / ชม.',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Text('จุได้ ${space.capacity} คน', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
