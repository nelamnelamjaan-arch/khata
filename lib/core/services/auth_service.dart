import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Firebase Authentication — email/password sign-in with per-user scope.
class AuthService extends GetxService {
  FirebaseAuth? _auth;

  final Rxn<User> currentUser = Rxn<User>();
  final RxnString authError = RxnString();

  FirebaseAuth get _firebaseAuth {
    if (_auth != null) return _auth!;
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not initialized yet.');
    }
    _auth = FirebaseAuth.instanceFor(app: Firebase.app());
    return _auth!;
  }

  String? get userId {
    if (!_isFirebaseReady) return null;
    try {
      return _firebaseAuth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn {
    if (!_isFirebaseReady) return false;
    try {
      return _firebaseAuth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  Stream<User?> authStateChanges() {
    if (!_isFirebaseReady) return const Stream<User?>.empty();
    return _firebaseAuth.authStateChanges();
  }

  Future<AuthService> init() async {
    if (!_isFirebaseReady) {
      currentUser.value = null;
      return this;
    }

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && user.isAnonymous) {
        try {
          await signOut();
        } catch (_) {
          currentUser.value = null;
        }
      } else {
        currentUser.value = user;
      }
      _firebaseAuth.authStateChanges().listen((u) => currentUser.value = u);
    } catch (_) {
      currentUser.value = null;
    }
    return this;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    authError.value = null;
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      currentUser.value = credential.user;
      return credential;
    } on FirebaseAuthException catch (e) {
      authError.value = _formatAuthError(e);
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    authError.value = null;
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      currentUser.value = credential.user;
      return credential;
    } on FirebaseAuthException catch (e) {
      authError.value = _formatAuthError(e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_isFirebaseReady) {
      await _firebaseAuth.signOut();
    }
    currentUser.value = null;
    authError.value = null;
  }

  String _formatAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.\n\n'
            'Enable it in Firebase Console → Authentication → Sign-in method.';
      default:
        if (kIsWeb && e.code == 'network-request-failed') {
          return '${e.message ?? e.code}\n\nCheck your connection and that your '
              'domain is listed under Firebase → Authentication → Authorized domains.';
        }
        return e.message ?? e.code;
    }
  }
}
