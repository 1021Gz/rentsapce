import '../data/app_store.dart';
import '../models/domain.dart';
import 'booking_controller.dart';

class SpaceController {
  SpaceController(this.store);
  final AppStore store;

  List<Space> filterSpaces({
    bool favoritesOnly = false,
    String category = 'ทั้งหมด',
    String query = '',
    SpaceSort sort = SpaceSort.recommended,
    int? maxPrice,
    int? minCapacity,
  }) {
    final filtered = store.spaces
        .where(
          (s) => _matchesFilter(
            s,
            favoritesOnly: favoritesOnly,
            category: category,
            query: query,
            maxPrice: maxPrice,
            minCapacity: minCapacity,
          ),
        )
        .toList();
    _sortSpaces(filtered, sort);
    return filtered;
  }

  bool _matchesFilter(
    Space space, {
    required bool favoritesOnly,
    required String category,
    required String query,
    int? maxPrice,
    int? minCapacity,
  }) {
    if (space.status != SpaceStatus.approved ||
        !store.user(space.ownerId).active) {
      return false;
    }
    if (favoritesOnly && !(store.currentUser?.favorites.contains(space.id) ?? false)) {
      return false;
    }
    return _matchesAttributes(space, category, query, maxPrice, minCapacity);
  }

  bool _matchesAttributes(
    Space space,
    String category,
    String query,
    int? maxPrice,
    int? minCapacity,
  ) {
    final searchable =
        '${space.name} ${space.location} ${space.amenities.join(' ')}'
            .toLowerCase();
    return (category == 'ทั้งหมด' || space.category == category) &&
        (maxPrice == null || space.price <= maxPrice) &&
        (minCapacity == null || space.capacity >= minCapacity) &&
        searchable.contains(query.trim().toLowerCase());
  }

  void _sortSpaces(List<Space> list, SpaceSort sort) {
    switch (sort) {
      case SpaceSort.recommended:
        return;
      case SpaceSort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case SpaceSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case SpaceSort.capacityDesc:
        list.sort((a, b) => b.capacity.compareTo(a.capacity));
    }
  }
  Space save({
    String? id,
    required String name,
    required String category,
    required String location,
    required int price,
    required int capacity,
    required String description,
    required List<String> amenities,
    String image = '',
  }) {
    final u = store.requireUser(UserRole.owner);
    if ([name, category, location, description].any((s) => s.trim().isEmpty) ||
        price <= 0 ||
        capacity <= 0) {
      throw DomainError('กรอกข้อมูลให้ครบ ราคาและความจุต้องมากกว่า 0');
    }
    if (image.isNotEmpty && !(Uri.tryParse(image)?.scheme == 'https')) {
      throw DomainError('ลิงก์ภาพต้องขึ้นต้นด้วย https://');
    }
    final s = id == null
        ? Space(
            id: store.nextId('SPACE'),
            ownerId: u.id,
            name: name.trim(),
            category: category.trim(),
            location: location.trim(),
            price: price,
            capacity: capacity,
            description: description.trim(),
          )
        : store.space(id);
    if (s.ownerId != u.id) throw DomainError('แก้ไขได้เฉพาะพื้นที่ของคุณ');
    s.name = name.trim();
    s.category = category.trim();
    s.location = location.trim();
    s.price = price;
    s.capacity = capacity;
    s.description = description.trim();
    s.amenities = amenities
        .where((a) => a.trim().isNotEmpty)
        .map((a) => a.trim())
        .toList();
    s.image = image.trim();
    s.status = SpaceStatus.pending;
    s.reviewReason = '';
    if (id == null) store.spaces.add(s);
    store.changed('ส่งประกาศ ${s.name} ให้ Admin ตรวจสอบ');
    return s;
  }

  void review(String id, bool approve, String reason) {
    store.requireUser(UserRole.admin);
    final s = store.space(id);
    if (s.status != SpaceStatus.pending) {
      throw DomainError('ประกาศนี้ได้รับการตรวจแล้ว');
    }
    if (!approve && reason.trim().isEmpty) {
      throw DomainError('กรุณาระบุเหตุผลที่ปฏิเสธ');
    }
    s.status = approve ? SpaceStatus.approved : SpaceStatus.rejected;
    s.reviewReason = reason.trim();
    store.changed('${s.status.label}: ${s.name}');
  }

  void suspendSpace(String id, String reason) {
    store.requireUser(UserRole.admin);
    final s = store.space(id);
    if (reason.trim().isEmpty) {
      throw DomainError('กรุณาระบุเหตุผลการระงับพื้นที่');
    }
    s.status = SpaceStatus.rejected;
    s.reviewReason = reason.trim();
    store.changed('ระงับประกาศ: ${s.name} ($reason)');
  }

  void activateSpace(String id) {
    store.requireUser(UserRole.admin);
    final s = store.space(id);
    s.status = SpaceStatus.approved;
    s.reviewReason = '';
    store.changed('เปิดใช้งานประกาศ: ${s.name}');
  }

  void saveAvailability(String id, Availability value) {
    final u = store.requireUser(UserRole.owner), s = store.space(id);
    if (s.ownerId != u.id) throw DomainError('แก้ไขได้เฉพาะพื้นที่ของคุณ');
    BookingController(store).sweep();
    if (value.days.length != 7 ||
        value.days.any(
          (d) => d.start < 0 || d.end > 1440 || d.end <= d.start,
        )) {
      throw DomainError('เวลาปิดต้องอยู่หลังเวลาเปิด');
    }
    if (value.blocks.any(
      (b) => !b.end.isAfter(b.start) || b.reason.trim().isEmpty,
    )) {
      throw DomainError('ช่วงปิดหรือเหตุผลไม่ถูกต้อง');
    }
    if (store.bookings.any(
      (b) =>
          b.spaceId == id &&
          b.status.holdsTime &&
          b.endsAt.isAfter(store.clock()) &&
          !value.acceptsRange(
            b.date,
            b.startMinutes,
            b.endMinutes,
            days: b.days,
          ),
    )) {
      throw DomainError('เวลาที่ตั้งทับรายการจองเดิม กรุณาจัดการการจองก่อน');
    }
    s.availability = value.copy();
    store.changed('บันทึกเวลาว่าง: ${s.name}');
  }

  void favorite(String id) {
    final u = store.requireUser(UserRole.renter);
    store.space(id);
    if (!u.favorites.add(id)) u.favorites.remove(id);
    store.changed('อัปเดตรายการโปรด');
  }

  void report(String subject, String detail) {
    final u = store.requireUser();
    if (detail.trim().isEmpty) throw DomainError('กรุณาระบุรายละเอียด');
    store.issues.insert(
      0,
      Issue(
        id: store.nextId('ISSUE'),
        reporterId: u.id,
        subject: subject,
        detail: detail.trim(),
      ),
    );
    store.changed('แจ้งปัญหา: $subject');
  }

  void closeIssue(String id, String resolution) {
    store.requireUser(UserRole.admin);
    if (resolution.trim().isEmpty) throw DomainError('กรุณาระบุผลการแก้ไข');
    final i = store.issues.firstWhere(
      (i) => i.id == id,
      orElse: () => throw DomainError('ไม่พบรายงาน'),
    );
    if (i.closed) throw DomainError('รายงานนี้ปิดแล้ว');
    i.closed = true;
    i.resolution = resolution.trim();
    store.changed('ปิดรายงาน ${i.id}: ${i.resolution}');
  }

  List<Booking> reviewedBookings(String spaceId) => store.bookings
      .where((b) => b.spaceId == spaceId && b.review != null)
      .toList();

  double? averageRating(String spaceId) {
    final reviewed = reviewedBookings(spaceId);
    if (reviewed.isEmpty) return null;
    final sum = reviewed.fold<int>(0, (total, b) => total + b.review!.rating);
    return sum / reviewed.length;
  }
}
