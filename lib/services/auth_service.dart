import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= SIGN UP =================
  Future<void> signUp({
    required String email,
    required String password,
    required String role, // client | lawyer
    required String name,
    String? barCouncilId,
  }) async {
    final credential =
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'barCouncilId': barCouncilId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= LOGIN =================
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential =
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential.user!;
  }

  // ================= ROLE FETCH =================
  Future<String> getUserRole(String uid) async {
    final doc =
    await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('User profile not found');
    }

    return doc['role'];
  }

  // ================= GOOGLE LOGIN =================
  Future<void> saveGoogleUserIfNew({
    required User user,
    required String role,
  }) async {
    final doc =
    await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
