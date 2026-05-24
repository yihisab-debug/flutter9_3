import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/complaint.dart';
import 'notification_service.dart';

class AdminNotificationsWatcher {
  AdminNotificationsWatcher._();
  static final AdminNotificationsWatcher instance =
      AdminNotificationsWatcher._();

  StreamSubscription? _sub;
  final Set<String> _known = {};
  bool _firstSnapshot = true;

  void start() {
    if (_sub != null) return;
    _firstSnapshot = true;
    _known.clear();

    _sub = FirebaseFirestore.instance
        .collection('complaints')
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        if (_firstSnapshot) {
          _known.add(change.doc.id);
          continue;
        }
        if (_known.contains(change.doc.id)) continue;
        _known.add(change.doc.id);
        try {
          final c = Complaint.fromMap(change.doc.id, change.doc.data()!);
          _notify(c);
        } catch (e) {
          debugPrint('AdminNotificationsWatcher parse error: $e');
        }
      }
      _firstSnapshot = false;
    }, onError: (e) {
      debugPrint('AdminNotificationsWatcher error: $e');
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _known.clear();
    _firstSnapshot = true;
  }

  void _notify(Complaint c) {
    NotificationService.instance.show(
      id: NotificationService.instance.idFromString(c.id),
      title: '⚠️ Новая жалоба',
      body: 'От ${c.userName} • заказ ${c.orderTotal} ₸',
      payload: 'complaint:${c.id}',
    );
  }
}
