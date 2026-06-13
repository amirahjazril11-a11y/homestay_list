class Homestay {
  final int id;
  final String name;
  final String state;
  final String district;
  final String description;
  final String imageUrl;
  final double? price;

  Homestay({
    required this.id,
    required this.name,
    required this.state,
    required this.district,
    required this.description,
    required this.imageUrl,
    this.price,
  });

  factory Homestay.fromJson(Map<String, dynamic> json) {
    return Homestay(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image'] ?? json['image_url'] ?? '',
      price: double.tryParse(
        (json['price'] ??
            json['price_per_night'] ??
            json['harga'] ??
          '')
        .toString(),
      ),
    );  
  }
}