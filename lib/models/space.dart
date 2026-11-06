class Space {
  Space(
    this.name,
    this.category,
    this.location,
    this.price,
    this.rating,
    this.capacity,
    this.amenities,
    this.image,
    this.description,
  );
  String name, category, location, image, description;
  int price, capacity;
  final double rating;
  List<String> amenities;
}
