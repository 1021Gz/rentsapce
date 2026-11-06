// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension RenterExplorePage on _HomePageState {
  Widget _browse() {
    final list = demoSpaces
        .where(
          (s) =>
              (s.name + s.location).toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (category == 'ทั้งหมด' || s.category == category),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('สวัสดี 👋', style: Theme.of(context).textTheme.titleMedium),
        Text(
          'ค้นหาพื้นที่ที่ใช่สำหรับไอเดียของคุณ',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'ค้นหาชื่อหรือทำเล',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(
            labelText: 'ประเภทพื้นที่',
            border: OutlineInputBorder(),
          ),
          items: [
            'ทั้งหมด',
            'สตูดิโอ',
            'ห้องประชุม',
            'ห้องอ่านหนังสือ',
          ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (v) => setState(() => category = v ?? 'ทั้งหมด'),
        ),
        const SizedBox(height: 20),
        Text(
          'พื้นที่แนะนำ · ${list.length} แห่ง',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...list.map(_spaceCard),
      ],
    );
  }

  Widget _spaceCard(Space s) {
    final fav = favorites.contains(s.name);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.network(
              s.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: mint,
                child: const Icon(Icons.home_work, size: 48, color: green),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(
                        () => fav
                            ? favorites.remove(s.name)
                            : favorites.add(s.name),
                      ),
                      icon: Icon(
                        fav ? Icons.favorite : Icons.favorite_border,
                        color: fav ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${s.location} · ${s.category} · รองรับ ${s.capacity} คน',
                  style: const TextStyle(color: Colors.black54),
                ),
                Wrap(
                  spacing: 6,
                  children: s.amenities
                      .map(
                        (a) => Chip(
                          label: Text(a),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
                Row(
                  children: [
                    Text(
                      '★ ${s.rating}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '฿${s.price} / ชั่วโมง',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => _showSpace(s),
                      child: const Text('ดูพื้นที่'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSpace(Space s) {
    var selectedDate = DateTime.now().add(const Duration(days: 1));
    var start = const TimeOfDay(hour: 10, minute: 0);
    var end = const TimeOfDay(hour: 12, minute: 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final outsideHours = !AvailabilityStore.instance.accepts(
            selectedDate,
            start.hour * 60 + start.minute,
            end.hour * 60 + end.minute,
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    s.image,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(height: 120, child: Icon(Icons.home)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${s.location} · รองรับ ${s.capacity} คน'),
                const SizedBox(height: 10),
                Text(s.description),
                Wrap(
                  children: s.amenities
                      .map((x) => Chip(label: Text(x)))
                      .toList(),
                ),
                Text('★ ${s.rating} · รีวิวจากผู้ใช้'),
                Text(
                  'ราคา ฿${s.price} / ชั่วโมง',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                const Text(
                  'เลือกวันและเวลาเช่า',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month, color: green),
                  title: const Text('วันที่เช่า'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('th'),
                    );
                    if (picked != null)
                      setModalState(() => selectedDate = picked);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        leading: const Icon(Icons.login, color: green),
                        title: const Text('เริ่ม'),
                        subtitle: Text(start.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: start,
                          );
                          if (picked != null)
                            setModalState(() => start = picked);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: green),
                        title: const Text('สิ้นสุด'),
                        subtitle: Text(end.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: end,
                          );
                          if (picked != null) setModalState(() => end = picked);
                        },
                      ),
                    ),
                  ],
                ),
                if ((end.hour * 60 + end.minute) <=
                    (start.hour * 60 + start.minute))
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (outsideHours &&
                    (end.hour * 60 + end.minute) >
                        (start.hour * 60 + start.minute))
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'ช่วงเวลาที่เลือกอยู่นอกเวลาเปิดให้บริการของวันนี้',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                FilledButton(
                  onPressed:
                      (end.hour * 60 + end.minute) <=
                              (start.hour * 60 + start.minute) ||
                          outsideHours
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          _bookingDialog(s, selectedDate, start, end);
                        },
                  child: const Text('ตรวจสอบราคาและส่งคำขอ'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _bookingDialog(Space s, DateTime date, TimeOfDay start, TimeOfDay end) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CheckoutPage(space: s, date: date, start: start, end: end),
      ),
    );
  }
}
