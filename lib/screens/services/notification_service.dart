import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static Future<void> send({
    required String uid,
    required String title,
    required String body,
    required String type,
    String? issueId,
  }) async {
    try {
      final id = const Uuid().v4();
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .set({
        'uid': uid,
        'title': title,
        'body': body,
        'type': type,
        'issueId': issueId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Notification failure should never block main flow
      debugPrint('NotificationService.send failed: $e');
    }
  }
}