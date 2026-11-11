import 'package:cloud_firestore/cloud_firestore.dart';

import 'social_service.dart';

/// conversations/{uidA_uidB}            members, to, initiator, status (active|request|blocked), names, lastText...
/// conversations/{id}/messages/{mid}    from, text, at
class ChatService {
  static final _db = FirebaseFirestore.instance;
  static String get uid => SocialService.uid;
  static String cid(String a, String b) =>
      a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
  static DocumentReference<Map<String, dynamic>> _ref(String id) =>
      _db.collection('conversations').doc(id);

  static Stream<List<Doc>> conversations() => _db
      .collection('conversations')
      .where('members', arrayContains: uid)
      .snapshots()
      .map((s) {
        int t(Doc d) =>
            (d['lastAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 1 << 50;
        return s.docs.toList()..sort((a, b) => t(b).compareTo(t(a)));
      });

  static Stream<DocumentSnapshot<Map<String, dynamic>>> conversation(
    String id,
  ) => _ref(id).snapshots();
  static Stream<List<Doc>> messages(String id) =>
      _ref(id)
          .collection('messages')
          .orderBy('at')
          .snapshots()
          .map((s) => s.docs);

  /// Starts a conversation if needed (friends = active, strangers = message request), then sends.
  static Future<void> send({
    required String otherUid,
    required String myLabel,
    required String otherLabel,
    required String text,
  }) async {
    final id = cid(uid, otherUid), ref = _ref(id);
    final snap = await ref.get();
    if (!snap.exists) {
      final f = await _db.collection('friendships').doc(id).get();
      final friends = f.exists && f.data()?['status'] == 'accepted';
      await ref.set({
        'members': [uid, otherUid],
        'to': otherUid,
        'initiator': uid,
        'names': {uid: myLabel, otherUid: otherLabel},
        'status': friends ? 'active' : 'request',
        'lastText': text,
        'lastAt': FieldValue.serverTimestamp(),
        'lastFrom': uid,
      });
    }
    final b = _db.batch();
    b.set(ref.collection('messages').doc(), {
      'from': uid,
      'text': text,
      'at': FieldValue.serverTimestamp(),
    });
    if (snap.exists)
      b.update(ref, {
        'lastText': text,
        'lastAt': FieldValue.serverTimestamp(),
        'lastFrom': uid,
      });
    await b.commit();
  }

  /// Unread = someone else sent the latest message after the last time I opened the chat.
  static bool isUnread(Doc d) {
    final m = d.data();
    final read = (m['reads'] as Map?)?[uid] as Timestamp?;
    final at = m['lastAt'] as Timestamp?;
    return m['status'] != 'blocked' &&
        m['lastFrom'] != uid &&
        at != null &&
        (read == null || at.compareTo(read) > 0);
  }

  static Stream<int> unreadCount() =>
      conversations().map((l) => l.where(isUnread).length);

  static Future<void> markRead(String id) =>
      _ref(id)
          .update({'reads.$uid': FieldValue.serverTimestamp()})
          .catchError((_) {});

  static Future<void> accept(String id) =>
      _ref(id).update({'status': 'active'});
  static Future<void> block(String id) =>
      _ref(id).update({'status': 'blocked'});
  static Future<void> report(String id) => _db.collection('reports').add({
    'convId': id,
    'by': uid,
    'at': FieldValue.serverTimestamp(),
  });

  // Opt-out: when false, people who are not friends cannot start a conversation with you.
  static Future<bool> allowMessages() async =>
      (await _db.collection('users').doc(uid).get()).data()?['allowMessages'] ??
      true;
  static Future<void> setAllowMessages(bool v) async {
    await _db.collection('users').doc(uid).set({
      'allowMessages': v,
    }, SetOptions(merge: true));
    final pub = _db.collection('publicProfiles').doc(uid);
    if ((await pub.get()).exists) await pub.update({'allowMessages': v});
  }
}
