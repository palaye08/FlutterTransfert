import 'package:get/get.dart';
import 'package:getxcli/app/modules/planifier/controllers/planifier_controller.dart';

class PlanifierBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlanifierController>(() => PlanifierController());
  }
}