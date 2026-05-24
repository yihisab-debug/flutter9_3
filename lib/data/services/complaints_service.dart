import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint.dart';

class ComplaintsService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> fileComplaint({
    required String orderId,
    required String userId,
    required String userName,
    String? courierId,
    String? courierName,
    required ComplaintReason reason,
    required String description,
    required int orderTotal,
  }) async {
    try {
      final exists = await _db
          .collection('complaints')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();
      if (exists.docs.isNotEmpty) {
        debugPrint('Жалоба по этому заказу уже существует');
        return null;
      }

      final complaint = Complaint(
        id: '',
        orderId: orderId,
        userId: userId,
        userName: userName,
        courierId: courierId,
        courierName: courierName,
        reason: reason,
        description: description,
        orderTotal: orderTotal,
        status: ComplaintStatus.pending,
        createdAt: DateTime.now(),
      );

      final ref =
          await _db.collection('complaints').add(complaint.toFirestore());

      await _db.collection('orders').doc(orderId).update({
        'complaintFiled': true,
      });

      return ref.id;
    } catch (e) {
      debugPrint('fileComplaint error: $e');
      return null;
    }
  }

  Stream<List<Complaint>> userComplaintsStream(String userId) {
    return _db
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Complaint.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Complaint>> allComplaintsStream() {
    return _db.collection('complaints').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Complaint.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<bool> approveComplaint({
    required Complaint complaint,
    required int refundAmount,
    String adminComment = '',
  }) async {
    try {
      await _db.collection('complaints').doc(complaint.id).update({
        'status': ComplaintStatus.approved.name,
        'refundAmount': refundAmount,
        'adminComment': adminComment,
        'resolvedAt': DateTime.now().toIso8601String(),
      });

      await _db.collection('users').doc(complaint.userId).update({
        'balance': FieldValue.increment(refundAmount),
      });

      await _db.collection('orders').doc(complaint.orderId).update({
        'status': 'canceled',
      });

      return true;
    } catch (e) {
      debugPrint('approveComplaint error: $e');
      return false;
    }
  }

  Future<bool> rejectComplaint({
    required Complaint complaint,
    String adminComment = '',
  }) async {
    try {
      await _db.collection('complaints').doc(complaint.id).update({
        'status': ComplaintStatus.rejected.name,
        'adminComment': adminComment,
        'resolvedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('rejectComplaint error: $e');
      return false;
    }
  }
}
