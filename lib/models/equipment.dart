
class Equipment {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final int quantity;
  final bool isAvailable;

  const Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.quantity,
    required this.isAvailable,
  });

  factory Equipment.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return Equipment(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      isAvailable: data['isAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'isAvailable': isAvailable,
    };
  }
}
