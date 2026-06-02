import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/exceptions/auth_cancelled_exception.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';

/// Handles email, Google, and phone authentication flows.
class AuthController extends GetxController {
  AuthController({AuthService? authService})
      : _auth = authService ?? Get.find<AuthService>();

  final AuthService _auth;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final phoneSession = Rxn<PhoneVerificationSession>();

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await _runGuarded(() async {
      await _auth.signInWithEmail(email: email, password: password);
      _goHome();
    });
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _runGuarded(() async {
      await _auth.registerWithEmail(email: email, password: password);
      _goHome();
    });
  }

  Future<void> loginWithGoogle() async {
    await _runGuarded(() async {
      await _auth.signInWithGoogle();
      _goHome();
    });
  }

  Future<void> sendPhoneCode(String phoneNumber) async {
    await _runGuarded(() async {
      phoneSession.value = null;
      try {
        phoneSession.value =
            await _auth.startPhoneVerification(phoneNumber);
      } on PhoneAutoVerifiedException {
        phoneSession.value = null;
        _goHome();
      }
    });
  }

  Future<void> confirmPhoneOtp(String smsCode) async {
    final session = phoneSession.value;
    if (session == null) {
      errorMessage.value = 'Request a verification code first.';
      return;
    }

    await _runGuarded(() async {
      await _auth.confirmPhoneCode(session: session, smsCode: smsCode);
      phoneSession.value = null;
      _goHome();
    });
  }

  void resetPhoneFlow() {
    phoneSession.value = null;
    errorMessage.value = null;
  }

  Future<void> signOut() async {
    phoneSession.value = null;
    await _auth.signOut();
    Get.offAllNamed(AppRoutes.auth);
  }

  void clearError() => errorMessage.value = null;

  void _goHome() => Get.offAllNamed(AppRoutes.dashboard);

  Future<void> _runGuarded(Future<void> Function() action) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await action();
    } on AuthCancelledException {
      // User dismissed the provider — no error banner.
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _auth.authError.value ?? e.message ?? e.code;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
