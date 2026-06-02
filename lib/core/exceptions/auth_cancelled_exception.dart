import 'package:firebase_auth/firebase_auth.dart';

/// Thrown when the user dismisses or cancels a sign-in flow (Google popup, etc.).
class AuthCancelledException implements Exception {
  AuthCancelledException([this.message = 'Sign-in was cancelled.']);

  final String message;

  @override
  String toString() => message;
}

/// Native Android auto-verified the phone before manual OTP entry.
class PhoneAutoVerifiedException implements Exception {
  PhoneAutoVerifiedException(this.credential);

  final UserCredential credential;
}
