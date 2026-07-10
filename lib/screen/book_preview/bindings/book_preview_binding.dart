import 'package:get/get.dart';
import 'package:novelux/screen/book_preview/controller/book_preview_controller.dart';

class BookPreviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookPreviewController>(
      () => BookPreviewController(),
    );
  }
}