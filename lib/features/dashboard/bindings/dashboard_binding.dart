import 'package:get/get.dart';
import 'package:smart_khata_manager/features/dashboard/controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(DashboardController.new);
  }
}
