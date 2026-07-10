import 'package:get/get.dart';
import 'package:novelux/screen/download_screen/controller/download_controller.dart';

class DownloadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DownloadController());
  }
}
