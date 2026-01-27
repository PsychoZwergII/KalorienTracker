import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Sign in with Email and Password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found with this email');
      } else if (e.code == 'wrong-password') {
        print('Wrong password');
      }
      return null;
    } catch (e) {
      print('Sign In Error: $e');
      return null;
    }
  }

  /// Create account with Email and Password
  Future<User?> createAccountWithEmail(String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('Password is too weak');
      } else if (e.code == 'email-already-in-use') {
        print('Email already in use');
      }
      return null;
    } catch (e) {
      print('Create Account Error: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }

  /// Get ID token for Cloud Function calls
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      print('Get ID Token Error: $e');
      return null;
    }
  }

  /// Get user ID
  String? getUserId() => _auth.currentUser?.uid;

  /// Get user email
  String? getUserEmail() => _auth.currentUser?.email;

  /// Get user display name
  String? getUserDisplayName() => _auth.currentUser?.displayName;
}
