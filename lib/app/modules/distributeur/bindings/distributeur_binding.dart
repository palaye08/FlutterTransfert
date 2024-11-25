import 'package:get/get.dart';
import 'package:getxcli/app/modules/distributeur/controllers/distributeur_controller.dart';

class DistributorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DistributorController>(() => DistributorController());
  }
}
