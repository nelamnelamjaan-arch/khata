import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_khata_manager/core/config/auth_config.dart';
import 'package:smart_khata_manager/core/exceptions/auth_cancelled_exception.dart';

/// Holds in-progress phone verification state (native SMS or web reCAPTCHA).
class PhoneVerificationSession {
  const PhoneVerificationSession({
    required this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.confirmationResult,
  });

  final String phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final ConfirmationResult? confirmationResult;

  bool get isWeb => confirmationResult != null;
}

/// Firebase Authentication — email, Google, and phone sign-in with per-user scope.
class AuthService extends GetxService {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

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

  GoogleSignIn get _google {
    return _googleSignIn ??= GoogleSignIn(
      clientId: kIsWeb && AuthConfig.hasGoogleWebClientId
          ? AuthConfig.googleWebClientId
          : null,
      scopes: const ['email', 'profile'],
    );
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

  // ── Email / password ──────────────────────────────────────────────────────

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

  // ── Google ────────────────────────────────────────────────────────────────

  Future<UserCredential> signInWithGoogle() async {
    authError.value = null;

    try {
      if (kIsWeb && !AuthConfig.hasGoogleWebClientId) {
        return _signInWithGooglePopup();
      }
      return _signInWithGoogleSignIn();
    } on AuthCancelledException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (_isUserCancelled(e)) {
        throw AuthCancelledException();
      }
      authError.value = _formatAuthError(e);
      rethrow;
    } catch (e) {
      if (_looksLikeCancellation(e)) {
        throw AuthCancelledException();
      }
      authError.value = e.toString();
      rethrow;
    }
  }

  Future<UserCredential> _signInWithGooglePopup() async {
    try {
      final credential =
          await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
      currentUser.value = credential.user;
      return credential;
    } on FirebaseAuthException catch (e) {
      if (_isUserCancelled(e)) {
        throw AuthCancelledException();
      }
      rethrow;
    }
  }

  Future<UserCredential> _signInWithGoogleSignIn() async {
    final account = await _google.signIn();
    if (account == null) {
      throw AuthCancelledException('Google sign-in was cancelled.');
    }

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    currentUser.value = userCredential.user;
    return userCredential;
  }

  // ── Phone ─────────────────────────────────────────────────────────────────

  Future<PhoneVerificationSession> startPhoneVerification(
    String rawPhoneNumber,
  ) async {
    authError.value = null;
    final phoneNumber = _normalizePhone(rawPhoneNumber);

    if (kIsWeb) {
      return _startPhoneVerificationWeb(phoneNumber);
    }
    return _startPhoneVerificationNative(phoneNumber);
  }

  Future<PhoneVerificationSession> _startPhoneVerificationWeb(
    String phoneNumber,
  ) async {
    try {
      final confirmationResult =
          await _firebaseAuth.signInWithPhoneNumber(phoneNumber);
      return PhoneVerificationSession(
        phoneNumber: phoneNumber,
        confirmationResult: confirmationResult,
      );
    } on FirebaseAuthException catch (e) {
      authError.value = _formatAuthError(e);
      rethrow;
    }
  }

  Future<PhoneVerificationSession> _startPhoneVerificationNative(
    String phoneNumber,
  ) async {
    final completer = Completer<PhoneVerificationSession>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (completer.isCompleted) return;
        try {
          final userCredential =
              await _firebaseAuth.signInWithCredential(credential);
          currentUser.value = userCredential.user;
          completer.completeError(
            PhoneAutoVerifiedException(userCredential),
          );
        } catch (e, stack) {
          if (!completer.isCompleted) {
            completer.completeError(e, stack);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          authError.value = _formatAuthError(e);
          completer.completeError(e);
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(
              phoneNumber: phoneNumber,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  Future<UserCredential> confirmPhoneCode({
    required PhoneVerificationSession session,
    required String smsCode,
  }) async {
    authError.value = null;
    final code = smsCode.trim();

    try {
      if (session.isWeb) {
        final result = await session.confirmationResult!.confirm(code);
        currentUser.value = result.user;
        return result;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: session.verificationId!,
        smsCode: code,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      currentUser.value = userCredential.user;
      return userCredential;
    } on FirebaseAuthException catch (e) {
      authError.value = _formatAuthError(e);
      rethrow;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    if (_isFirebaseReady) {
      await _firebaseAuth.signOut();
    }
    try {
      await _googleSignIn?.signOut();
    } catch (_) {}
    currentUser.value = null;
    authError.value = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _normalizePhone(String raw) {
    var phone = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!phone.startsWith('+')) {
      phone = '+$phone';
    }
    return phone;
  }

  bool _isUserCancelled(FirebaseAuthException e) {
    return e.code == 'popup-closed-by-user' ||
        e.code == 'cancelled-popup-request' ||
        e.code == 'web-context-cancelled';
  }

  bool _looksLikeCancellation(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('cancel') ||
        text.contains('popup_closed') ||
        text.contains('sign_in_canceled');
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
      case 'invalid-phone-number':
        return 'Invalid phone number. Use international format, e.g. +923001234567.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'session-expired':
      case 'code-expired':
        return 'Verification code expired. Request a new code.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.\n\n'
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
