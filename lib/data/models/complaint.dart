enum ComplaintStatus { pending, approved, rejected }

enum ComplaintReason {
  notDelivered,
  wrongItems,
  cold,
  rude,
  late,
  other,
}

extension ComplaintStatusX on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.pending:
        return 'На рассмотрении';
      case ComplaintStatus.approved:
        return 'Одобрена (возврат)';
      case ComplaintStatus.rejected:
        return 'Отклонена';
    }
  }
}

extension ComplaintReasonX on ComplaintReason {
  String get label {
    switch (this) {
      case ComplaintReason.notDelivered:
        return 'Курьер не принёс заказ';
      case ComplaintReason.wrongItems:
        return 'Не те позиции / не хватает';
      case ComplaintReason.cold:
        return 'Еда холодная / испорчена';
      case ComplaintReason.rude:
        return 'Курьер грубил';
      case ComplaintReason.late:
        return 'Сильно опоздал';
      case ComplaintReason.other:
        return 'Другое';
    }
  }

  String get emoji {
    switch (this) {
      case ComplaintReason.notDelivered:
        return '📦';
      case ComplaintReason.wrongItems:
        return '❌';
      case ComplaintReason.cold:
        return '🥶';
      case ComplaintReason.rude:
        return '😡';
      case ComplaintReason.late:
        return '⏰';
      case ComplaintReason.other:
        return '💬';
    }
  }

  static ComplaintReason fromString(String? s) {
    return ComplaintReason.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ComplaintReason.other,
    );
  }
}

class Complaint {
  final String id;
  final String orderId;
  final String userId;
  final String userName;
  final String? courierId;
  final String? courierName;
  final ComplaintReason reason;
  final String description;
  final int orderTotal;
  final ComplaintStatus status;
  final String? adminComment;
  final int refundAmount;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Complaint({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    this.courierId,
    this.courierName,
    required this.reason,
    required this.description,
    required this.orderTotal,
    required this.status,
    this.adminComment,
    this.refundAmount = 0,
    required this.createdAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'userId': userId,
        'userName': userName,
        'courierId': courierId,
        'courierName': courierName,
        'reason': reason.name,
        'description': description,
        'orderTotal': orderTotal,
        'status': status.name,
        'adminComment': adminComment,
        'refundAmount': refundAmount,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory Complaint.fromMap(String id, Map<String, dynamic> m) {
    return Complaint(
      id: id,
      orderId: m['orderId'] ?? '',
      userId: m['userId'] ?? '',
      userName: m['userName'] ?? '',
      courierId: m['courierId'],
      courierName: m['courierName'],
      reason: ComplaintReasonX.fromString(m['reason']?.toString()),
      description: m['description'] ?? '',
      orderTotal: (m['orderTotal'] ?? 0) as int,
      status: ComplaintStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => ComplaintStatus.pending,
      ),
      adminComment: m['adminComment'],
      refundAmount: (m['refundAmount'] ?? 0) as int,
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      resolvedAt: m['resolvedAt'] != null
          ? DateTime.tryParse(m['resolvedAt'].toString())
          : null,
    );
  }
}
