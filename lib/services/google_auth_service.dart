import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ FIX: Use a static lazy-initialized variable that is NULL on Web.
  // This prevents the GoogleSignIn package from trying to initialize 
  // on the web platform, which causes the "Null check operator" error 
  // if the Client ID is not found in index.html.
  static final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  GoogleAuthProvider _buildWebProvider() {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});
    return provider;
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = _buildWebProvider();

        // If the browser was redirected back from Google auth, return that user.
        final redirectResult = await _auth.getRedirectResult();
        if (redirectResult.user != null) {
          return redirectResult.user;
        }

        try {
          final userCredential = await _auth.signInWithPopup(googleProvider);
          return userCredential.user;
        } on FirebaseAuthException catch (e) {
          // Some browsers/webviews block popups; redirect flow is more reliable there.
          if (e.code == 'popup-blocked' || e.code == 'operation-not-supported-in-this-environment') {
            await _auth.signInWithRedirect(googleProvider);
            return null;
          }
          rethrow;
        }
      } else {
        // ✅ For Mobile: Use the package normally.
        if (_googleSignIn == null) return null; // Should never happen on mobile

        await _googleSignIn!.signOut();
        
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Google Sign-In Error: $e");
      }
      // If we still see a null check error, provide a more descriptive message.
      if (e.toString().contains('Null check operator')) {
        throw 'Initialization error: Ensure Google Auth is correctly enabled in your Firebase Console.';
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Sign Out Error: $e");
      }
    }
  }
}
