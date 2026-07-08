import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class AuditService {
  static Future<void> log({
    required String action,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final id = const Uuid().v4();

      await FirebaseFirestore.instance
          .collection('audit_logs')
          .doc(id)
          .set({
        'logId': id,
        'uid': user?.uid ?? 'system',
        'email': user?.email ?? 'system',
        'action': action,
        'description': description,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Never block main flow
      debugPrint('AuditService.log failed: $e');
    }
  }
}