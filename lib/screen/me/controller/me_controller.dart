import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/screen/auth/auth_controller.dart';

class MeController extends GetxController {
  final RxBool isLoading   = false.obs;
  final RxList bookmarks   = [].obs;
  final RxInt  unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBookmarks();
    fetchUnreadCount();
  }

  Future<void> fetchBookmarks() async {
    final res = await ApiService.getMyBookmarks();
    if (res['success']) {
      final d = res['data'];
      bookmarks.value = d is List ? d : (d['results'] ?? []);
    }
  }

  Future<void> fetchUnreadCount() async {
    final res = await ApiService.getUnreadCount();
    if (res['success']) unreadCount.value = res['data']['unread_count'] ?? 0;
  }

  Future<void> becomeAuthor() async {
    isLoading.value = true;
    final res = await ApiService.becomeAuthor();
    isLoading.value = false;
    if (res['success']) {
      await Get.find<AuthController>().fetchMe();
      AppAlert.success('Congratulations! — You are now an author on NoveluX!');
    } else {
      AppAlert.error(res['error'] ?? 'Failed');
    }
  }
}
