import 'cart_item.dart';

enum DeliveryType { delivery, pickup }

enum OrderStatus { pending, confirmed, delivering, completed, canceled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Ожидает';
      case OrderStatus.confirmed:
        return 'Принят';
      case OrderStatus.delivering:
        return 'В пути';
      case OrderStatus.completed:
        return 'Доставлен';
      case OrderStatus.canceled:
        return 'Отменён';
    }
  }
}

extension DeliveryTypeX on DeliveryType {
  String get label {
    switch (this) {
      case DeliveryType.delivery:
        return 'Доставка';
      case DeliveryType.pickup:
        return 'Самовывоз';
    }
  }
}

class AppOrder {
  final String id;
  final String userId;
  final String? userName;
  final List<CartItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final DeliveryType deliveryType;
  final String address;
  final String note;
  final OrderStatus status;
  final DateTime createdAt;

  final String? courierId;
  final String? courierName;
  final bool reviewLeft;
  final bool complaintFiled;

  AppOrder({
    required this.id,
    required this.userId,
    this.userName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryType,
    required this.address,
    required this.note,
    required this.status,
    required this.createdAt,
    this.courierId,
    this.courierName,
    this.reviewLeft = false,
    this.complaintFiled = false,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'deliveryType': deliveryType.name,
        'address': address,
        'note': note,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'courierId': courierId,
        'courierName': courierName,
        'reviewLeft': reviewLeft,
        'complaintFiled': complaintFiled,
      };

  factory AppOrder.fromMap(String id, Map<String, dynamic> m) {
    final itemsRaw = (m['items'] as List?) ?? [];
    final items = itemsRaw.map((it) {
      final mm = it as Map<String, dynamic>;
      return CartItem.fromMap(mm);
    }).toList();
    return AppOrder(
      id: id,
      userId: m['userId'] ?? '',
      userName: m['userName'],
      items: items,
      subtotal: (m['subtotal'] ?? 0) as int,
      deliveryFee: (m['deliveryFee'] ?? 0) as int,
      total: (m['total'] ?? 0) as int,
      deliveryType: DeliveryType.values.firstWhere(
        (e) => e.name == m['deliveryType'],
        orElse: () => DeliveryType.delivery,
      ),
      address: m['address'] ?? '',
      note: m['note'] ?? '',
      status: statusFromString(m['status']?.toString()),
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      courierId: m['courierId'],
      courierName: m['courierName'],
      reviewLeft: (m['reviewLeft'] ?? false) as bool,
      complaintFiled: (m['complaintFiled'] ?? false) as bool,
    );
  }

  static OrderStatus statusFromString(String? s) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => OrderStatus.pending,
    );
  }
}
