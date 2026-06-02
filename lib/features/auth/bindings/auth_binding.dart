import 'package:get/get.dart';
import 'package:smart_khata_manager/features/auth/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController());
    }
  }
}
