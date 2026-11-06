// ignore_for_file: library_private_types_in_public_api, invalid_use_of_protected_member
part of '../../home_page.dart';

extension RenterFavoritesPage on _HomePageState {
  Widget _favoritePage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'รายการโปรด',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      ...demoSpaces.where((s) => favorites.contains(s.name)).map(_spaceCard),
      if (favorites.isEmpty)
        const Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'ยังไม่มีพื้นที่โปรด กดรูปหัวใจบนการ์ดพื้นที่เพื่อบันทึก',
          ),
        ),
    ],
  );
}
