class Homestay {
  final int id;
  final String name;
  final String state;
  final String district;
  final String description;
  final String imageUrl;
  final double? price;

  HomeStay({
    required this.id,
    required this.name,
    required this.state,
    required this.district,
    required this.description,
    required this.imageUrl,
    required this.price,
  });
}

factory HomeStay.fromJson(Map<String, dynamic> json) {
  return HomeStay(
    id: json['id'] ?? 0,
    name: json['name']?? '',
    state: json['state']?? '',
    district: json['district'] ?? '',
    description: json['description'] ?? '',
    imageUrl: json['image'] ?? json['image_url'] ,
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
  );
}