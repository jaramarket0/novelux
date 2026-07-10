import 'package:get/get.dart';
import 'package:novelux/screen/genres/controller/genres_controller.dart';

class GenresBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GenresController>(() => GenresController());
  }
  
}