import 'package:get/get.dart';
import 'package:novelux/screen/notification_screen/controller/notifcation_controller.dart';

class NotifcationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NotificationController());
  }
}
