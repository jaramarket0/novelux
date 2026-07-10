import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';

class NotificationController extends GetxController {
  final RxBool isLoading     = false.obs;
  final RxList notifications = [].obs;
  final RxInt  unreadCount   = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    final res = await ApiService.getNotifications();
    isLoading.value = false;
    if (res['success']) {
      final d = res['data'];
      notifications.value = d is List ? d : (d['results'] ?? []);
      unreadCount.value = notifications.where((n) => !(n['is_read'] ?? false)).length;
    }
  }

  Future<void> markAllRead() async {
    await ApiService.markAllRead();
    for (var n in notifications) {
      (n as Map)['is_read'] = true;
    }
    notifications.refresh();
    unreadCount.value = 0;
  }

  Future<void> markRead(int id) async {
    await ApiService.markRead(id);
    final idx = notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      (notifications[idx] as Map)['is_read'] = true;
      notifications.refresh();
      unreadCount.value = notifications.where((n) => !(n['is_read'] ?? false)).length;
    }
  }
}
