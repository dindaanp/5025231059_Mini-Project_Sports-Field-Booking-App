class FieldModel {
  final String id;
  final String name;
  final String type;
  final int price;
  final String location;
  final String imageUrl;
  final String description;

  FieldModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.location,
    this.imageUrl = '',
    this.description = '',
  });

  factory FieldModel.fromMap(String id, Map<String, dynamic> map) {
    return FieldModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      price: map['price'] ?? 0,
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'price': price,
      'location': location,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}