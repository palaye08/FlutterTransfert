import 'package:get/get.dart';
import '../controllers/transfert_controller.dart';

class TransfertBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransfertController>(() => TransfertController());
  }
}