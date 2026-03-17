import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= SIGN UP =================
  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    required String name,
    String? specialization,
    String? barCouncilId,
    String? courtType,
    String? state,
    String? district,
    // ✅ NEW OCR FIELDS
    String? fatherName,
    String? dob,
    String? address,
    String? validity,
    String? enrolmentNo,
    String? signingAuthority,
    String? panCardNo,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final Map<String, dynamic> userData = {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'avatarInitial': name.isNotEmpty ? name[0].toUpperCase() : 'U',
      'createdAt': FieldValue.serverTimestamp(),
      'status': role == 'lawyer' ? 'pending' : 'verified',
      'isVerified': false,
    };

    if (role == 'lawyer') {
      userData.addAll({
        'specialization': specialization ?? '',
        'barCouncilId': barCouncilId ?? '',
        'courtType': courtType ?? '',
        'state': state ?? '',
        'district': district ?? '',
        'experience': 0,
        // ✅ ADD NEW FIELDS
        'fatherName': fatherName ?? '',
        'dob': dob ?? '',
        'address': address ?? '',
        'validity': validity ?? '',
        'enrolmentNo': enrolmentNo ?? barCouncilId ?? '',
        'signingAuthority': signingAuthority ?? '',
        'panCardNo': panCardNo ?? '',
      });
    }

    await _firestore.collection('users').doc(uid).set(userData);
  }

  // ================= LOGIN =================
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  // ================= ROLE FETCH =================
  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found');
    }
    return doc['role'] as String;
  }

  // ================= CHECK USER EXISTS =================
  Future<bool> checkIfUserExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  // ================= GOOGLE SAVE/SIGNUP =================
  Future<void> saveGoogleUser({
    required User user,
    required String role,
    String? specialization,
    String? barCouncilId,
    String? courtType,
    String? state,
    String? district,
  }) async {
    final ref = _firestore.collection('users').doc(user.uid);
    
    final name = user.displayName ?? 'User';
    final Map<String, dynamic> data = {
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'avatarInitial': name.isNotEmpty ? name[0].toUpperCase() : 'U',
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'status': role == 'lawyer' ? 'pending' : 'verified',
      'isVerified': false,
    };

    if (role == 'lawyer') {
      data.addAll({
        'specialization': specialization ?? '',
        'barCouncilId': barCouncilId ?? '',
        'courtType': courtType ?? '',
        'state': state ?? '',
        'district': district ?? '',
        'experience': 0,
      });
    }

    await ref.set(data);
  }
}
