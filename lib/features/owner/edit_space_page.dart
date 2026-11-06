import 'package:flutter/material.dart';
import '../../models/space.dart';

class EditSpacePage extends StatefulWidget {
  const EditSpacePage({super.key, required this.space});
  final Space space;

  @override
  State<EditSpacePage> createState() => _EditSpacePageState();
}

class _EditSpacePageState extends State<EditSpacePage> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.space.name);
  late final category = TextEditingController(text: widget.space.category);
  late final location = TextEditingController(text: widget.space.location);
  late final price = TextEditingController(text: widget.space.price.toString());
  late final capacity = TextEditingController(
    text: widget.space.capacity.toString(),
  );
  late final amenities = TextEditingController(
    text: widget.space.amenities.join(', '),
  );
  late final image = TextEditingController(text: widget.space.image);
  late final description = TextEditingController(
    text: widget.space.description,
  );

  @override
  void dispose() {
    name.dispose();
    category.dispose();
    location.dispose();
    price.dispose();
    capacity.dispose();
    amenities.dispose();
    image.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('แก้ไขพื้นที่')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'ข้อมูลประกาศ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('แก้รายละเอียด ราคา และสิ่งอำนวยความสะดวกของพื้นที่'),
              const SizedBox(height: 16),
              _field(name, 'ชื่อพื้นที่'),
              _field(category, 'ประเภทพื้นที่'),
              _field(location, 'ที่ตั้ง'),
              Row(
                children: [
                  Expanded(child: _field(price, 'ราคา/ชั่วโมง', number: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(capacity, 'จำนวนคนที่รองรับ', number: true),
                  ),
                ],
              ),
              _field(
                amenities,
                'สิ่งอำนวยความสะดวก',
                hint: 'คั่นแต่ละรายการด้วยเครื่องหมายจุลภาค',
              ),
              _field(image, 'ลิงก์รูปภาพ', hint: 'https://...'),
              _field(description, 'รายละเอียดพื้นที่', maxLines: 4),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFFFF7E6),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF9A6B00)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'การแก้ราคาและข้อมูลประกาศมีผลกับการแสดงต่อผู้เช่าในตัวอย่างนี้ การเปลี่ยนแปลงยังไม่ได้บันทึกไปยังเซิร์ฟเวอร์',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('บันทึกการแก้ไข'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool number = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'กรุณากรอก$label';
        if (number && int.tryParse(value.trim()) == null)
          return 'กรุณากรอกเป็นตัวเลข';
        if (number && int.parse(value.trim()) <= 0) return 'ค่าต้องมากกว่า 0';
        return null;
      },
    ),
  );

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final space = widget.space;
    space
      ..name = name.text.trim()
      ..category = category.text.trim()
      ..location = location.text.trim()
      ..price = int.parse(price.text.trim())
      ..capacity = int.parse(capacity.text.trim())
      ..amenities = amenities.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList()
      ..image = image.text.trim()
      ..description = description.text.trim();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลพื้นที่แล้ว')));
    Navigator.pop(context, true);
  }
}
