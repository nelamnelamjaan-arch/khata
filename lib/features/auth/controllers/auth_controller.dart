import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';

/// Handles email/password authentication.
class AuthController extends GetxController {
  AuthController({AuthService? authService})
      : _auth = authService ?? Get.find<AuthService>();

  final AuthService _auth;

  final isLoading = false.obs;
  final errorMessage = RxnString();

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

  Future<void> signOut() async {
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
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _auth.authError.value ?? e.message ?? e.code;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
