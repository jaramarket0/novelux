import 'package:get/get.dart';
import 'package:novelux/screen/about/controller/about_controller.dart';

class AboutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AboutController());
  }
}
