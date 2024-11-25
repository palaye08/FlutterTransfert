import 'package:get/get.dart';

import '../controllers/annuler_controller.dart';

class AnnulerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnnulerController>(
      () => AnnulerController(),
    );
  }
}
