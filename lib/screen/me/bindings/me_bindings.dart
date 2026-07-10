import 'package:get/get.dart';
import 'package:novelux/screen/me/controller/me_controller.dart';

class MeBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MeController>(() => MeController());
  }
  
}