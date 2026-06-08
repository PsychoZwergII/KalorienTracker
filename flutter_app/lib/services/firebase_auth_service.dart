import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'logger_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
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
      if (googleUser == null) {
        LoggerService.info('Google Sign-In cancelled by user');
        return null; // User cancelled, not an error
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      LoggerService.info('Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase Auth Error [${e.code}]: ${e.message}', e);
      rethrow;
    } catch (e, st) {
      LoggerService.error('Google Sign-In Error', e, st);
      rethrow;
    }
  }

  /// Sign in with Email and Password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      LoggerService.info('Email sign-in successful: $email');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase Auth Error [${e.code}]: ${e.message}', e);
      rethrow;
    } catch (e, st) {
      LoggerService.error('Sign In Error', e, st);
      rethrow;
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
      
      LoggerService.info('Account created: $email ($displayName)');
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase Auth Error [${e.code}]: ${e.message}', e);
      rethrow;
    } catch (e, st) {
      LoggerService.error('Create Account Error', e, st);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      LoggerService.info('User signed out');
    } catch (e, st) {
      LoggerService.warning('Sign Out Error', e, st);
      rethrow;
    }
  }

  /// Get ID token for Cloud Function calls (with refresh)
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } catch (e, st) {
      LoggerService.error('Failed to get ID token', e, st);
      return null;
    }
  }

  /// Get user ID
  String? getUserId() => _auth.currentUser?.uid;

  /// Get user email
  String? getUserEmail() => _auth.currentUser?.email;

  /// Get user display name
  String? getUserDisplayName() => _auth.currentUser?.displayName;

  /// Check if user is authenticated
  bool isAuthenticated() => _auth.currentUser != null;

  /// Get user email verification status
  bool isEmailVerified() => _auth.currentUser?.emailVerified ?? false;

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      LoggerService.info('Password reset email sent to: $email');
    } catch (e, st) {
      LoggerService.error('Failed to send password reset email', e, st);
      rethrow;
    }
  }
}
