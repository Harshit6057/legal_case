import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._(); // private constructor

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _userCollection = 'users';

  // ================= CREATE USER =================
  static Future<void> createUser({
    required String uid,
    required String email,
    required String role, // 'client' | 'lawyer'
    required String name,
    String? barCouncilId, // only for lawyer
  }) async {
    await _firestore.collection(_userCollection).doc(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'barCouncilId': barCouncilId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= GET USER ROLE =================
  static Future<String> getUserRole(String uid) async {
    final doc =
    await _firestore.collection(_userCollection).doc(uid).get();

    if (!doc.exists) {
      throw Exception('User document does not exist');
    }

    return doc['role'] as String;
  }

  // ================= GET FULL USER DATA =================
  static Future<Map<String, dynamic>> getUserData(
      String uid) async {
    final doc =
    await _firestore.collection(_userCollection).doc(uid).get();

    if (!doc.exists) {
      throw Exception('User document does not exist');
    }

    return doc.data()!;
  }

  // ================= CHECK USER EXISTS =================
  static Future<bool> userExists(String uid) async {
    final doc =
    await _firestore.collection(_userCollection).doc(uid).get();
    return doc.exists;
  }

  // ================= SAVE GOOGLE USER =================
  static Future<void> saveGoogleUserIfNew({
    required String uid,
    required String email,
    required String role,
    String name = '',
  }) async {
    final exists = await userExists(uid);

    if (!exists) {
      await _firestore.collection(_userCollection).doc(uid).set({
        'uid': uid,
        'email': email,
        'role': role,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ================= UPDATE USER =================
  static Future<void> updateUser(
      String uid,
      Map<String, dynamic> data,
      ) async {
    await _firestore
        .collection(_userCollection)
        .doc(uid)
        .update(data);
  }

  // ================= DELETE USER =================
  static Future<void> deleteUser(String uid) async {
    await _firestore.collection(_userCollection).doc(uid).delete();
  }
}
