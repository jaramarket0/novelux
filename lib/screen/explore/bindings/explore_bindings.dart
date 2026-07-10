import 'package:get/get.dart';
import 'package:novelux/screen/explore/controller/explore_controller.dart';

class ExploreBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExploreController>(() => ExploreController());
  }
  
}