import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressEntry {
  final String title, type;
  final int seconds;
  final bool completed;
  final DateTime at;
  ProgressEntry(this.title, this.type, this.seconds, this.completed, this.at);
}

/// Every Take 5 session is saved to users/{uid}/activity (finished or stopped early).
class ProgressService {
  static CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('activity');

  static Future<void> log(
    String title,
    String type,
    int seconds,
    bool completed,
  ) async {
    try {
      await _col.add({
        'title': title,
        'type': type,
        'seconds': seconds,
        'completed': completed,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Stream<List<ProgressEntry>> stream() => _col
      .orderBy('at', descending: true)
      .limit(500)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            ProgressEntry(
              d.data()['title'] ?? '',
              d.data()['type'] ?? '',
              (d.data()['seconds'] ?? 0) as int,
              d.data()['completed'] ?? true,
              (d.data()['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ),
        ],
      );
}
