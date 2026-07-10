import 'package:get/get.dart';
import 'package:novelux/screen/library/controller/library_controller.dart';

class LibraryBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LibraryController>(() => LibraryController());
  }
  
}