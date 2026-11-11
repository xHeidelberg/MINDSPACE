import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

typedef Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

class SocialService {
  static final _db = FirebaseFirestore.instance;
  static String get uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<String> uploadAvatar(Uint8List b) async {
    final png = b.length > 4 && b[0] == 0x89;
    final r = FirebaseStorage.instance.ref('avatars/$uid/avatar');
    await r.putData(
      b,
      SettableMetadata(contentType: png ? 'image/png' : 'image/jpeg'),
    );
    return r.getDownloadURL();
  }

  /// Saves profile + claims a unique username. Only adults who opt in get a public (searchable) profile.
  static Future<void> saveProfile({
    required String name,
    required String username,
    required String bio,
    required bool discoverable,
    String? photoUrl,
  }) => _db.runTransaction((tx) async {
    final userRef = _db.collection('users').doc(uid);
    final cur = (await tx.get(userRef)).data() ?? {};
    final old = (cur['username'] ?? '') as String;
    DocumentReference<Map<String, dynamic>>? claim;
    if (username.isNotEmpty && username != old) {
      claim = _db.collection('usernames').doc(username);
      if ((await tx.get(claim)).exists) {
        throw Exception('That username is taken.');
      }
    }
    final photo = photoUrl ?? cur['photoUrl'] ?? '';
    if (claim != null) {
      tx.set(claim, {'uid': uid});
      if (old.isNotEmpty) tx.delete(_db.collection('usernames').doc(old));
    }
    tx.set(userRef, {
      'name': name,
      'username': username,
      'bio': bio,
      'photoUrl': photo,
      'discoverable': discoverable,
    }, SetOptions(merge: true));
    final pub = _db.collection('publicProfiles').doc(uid);
    discoverable
        ? tx.set(pub, {
            'username': username,
            'name': name,
            'bio': bio,
            'photoUrl': photo,
            'allowMessages': cur['allowMessages'] ?? true,
          })
        : tx.delete(pub);
  });

  // ----- friends -----
  static String _fid(String a, String b) =>
      a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

  static Stream<List<Doc>> friendships() => _db
      .collection('friendships')
      .where('members', arrayContains: uid)
      .snapshots()
      .map((s) => s.docs);

  static Future<List<Map<String, dynamic>>> search(String q) async {
    q = q.trim().toLowerCase().replaceAll('@', '');
    if (q.length < 2) return [];
    final s = await _db
        .collection('publicProfiles')
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThan: '$q\uf8ff')
        .limit(10)
        .get();
    return [
      for (final d in s.docs)
        if (d.id != uid) {...d.data(), 'uid': d.id},
    ];
  }

  static Future<void> request(
    String other,
    String myLabel,
    String otherLabel,
  ) => _db.collection('friendships').doc(_fid(uid, other)).set({
    'members': [uid, other],
    'from': uid,
    'to': other,
    'status': 'pending',
    'names': {uid: myLabel, other: otherLabel},
  });

  static Future<void> accept(String id) =>
      _db.collection('friendships').doc(id).update({'status': 'accepted'});
  static Future<void> removeFriendship(String id) =>
      _db.collection('friendships').doc(id).delete();

  // ----- notes / day cards -----
  static Future<void> addNote({
    required String text,
    required String mood,
    required int seed,
    required bool share,
    required String authorName,
  }) async {
    var shared = <String>[];
    if (share) {
      final f = await _db
          .collection('friendships')
          .where('members', arrayContains: uid)
          .get();
      shared = [
        for (final d in f.docs)
          if (d['status'] == 'accepted')
            (d['members'] as List).firstWhere((m) => m != uid) as String,
      ];
    }
    await _db.collection('notes').add({
      'authorId': uid,
      'authorName': authorName,
      'text': text,
      'mood': mood,
      'seed': seed,
      'sharedWith': shared,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static List<Doc> _sorted(List<Doc> d) {
    int t(Doc x) =>
        (x['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 1 << 50;
    return d..sort((a, b) => t(b).compareTo(t(a)));
  }

  static Stream<List<Doc>> myNotes() => _db
      .collection('notes')
      .where('authorId', isEqualTo: uid)
      .snapshots()
      .map((s) => _sorted(s.docs));
  static Stream<List<Doc>> sharedWithMe() => _db
      .collection('notes')
      .where('sharedWith', arrayContains: uid)
      .snapshots()
      .map((s) => _sorted(s.docs));
  static Future<void> deleteNote(String id) =>
      _db.collection('notes').doc(id).delete();
  static Future<void> report(String noteId) => _db.collection('reports').add({
    'noteId': noteId,
    'by': uid,
    'at': FieldValue.serverTimestamp(),
  });
}
