class Dish {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final String emoji;
  final List<String> tags;
  final int weight;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.emoji,
    required this.tags,
    required this.weight,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is int)
          ? json['price']
          : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      category: json['category'] ?? 'Все',
      emoji: json['emoji'] ?? '🍽️',
      tags: (json['tags'] is List)
          ? List<String>.from(json['tags'])
          : <String>[],
      weight: (json['weight'] is int)
          ? json['weight']
          : int.tryParse(json['weight']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'emoji': emoji,
        'tags': tags,
        'weight': weight,
      };
}
