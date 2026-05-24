import 'dish.dart';

class CartItem {
  final Dish dish;
  int quantity;

  CartItem({required this.dish, this.quantity = 1});

  int get total => dish.price * quantity;

  Map<String, dynamic> toJson() => {
        'dishId': dish.id,
        'name': dish.name,
        'emoji': dish.emoji,
        'price': dish.price,
        'quantity': quantity,
        'total': total,
      };

  factory CartItem.fromMap(Map<String, dynamic> m) {
    final dish = Dish(
      id: m['dishId']?.toString() ?? '',
      name: m['name'] ?? '',
      description: '',
      price: (m['price'] ?? 0) as int,
      category: '',
      emoji: m['emoji'] ?? '🍽️',
      tags: const [],
      weight: 0,
    );
    return CartItem(dish: dish, quantity: (m['quantity'] ?? 1) as int);
  }
}
