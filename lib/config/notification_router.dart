import 'dart:convert';

import 'package:get/get.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/author/author_dashboard_screen.dart';
import 'package:novelux/screen/author/author_profile_screen.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/screen/me/vip_screen.dart';
import 'package:novelux/screen/notification_screen/controller/notifcation_controller.dart';
import 'package:novelux/screen/notification_screen/notification_screen.dart';
import 'package:novelux/screen/reward_screen/reward_screen.dart';

/// Opens the screen a notification points to, from its data payload.
///
/// Payloads the backend sends:
///   {"screen": "story", "slug": "moonbound"}            — a book
///   {"story_slug": "moonbound", "chapter_number": "12"}  — new chapter / tip / comment
///   {"screen": "my_books" | "rejected_stories" | "earnings" | "contest", …} — author dashboard
///   {"screen": "rewards"}                                — rewards & tasks
///   {"screen": "vip"}                                    — VIP plans
///   {"username": "ada"}                                  — a new follower's profile
/// Anything else (announcements, KYC updates…) opens the notification list,
/// so a tap always lands somewhere useful.
///
/// Used by push taps (app closed, in background or open), by the in-app
/// notification list and by deep links.
class NotificationRouter {
  NotificationRouter._();

  /// Data from the push that launched the app. It is opened once the main
  /// screen is up — navigating earlier would be replaced by the splash
  /// screen's own navigation.
  static Map<String, dynamic>? _pending;

  static const _authorScreens = {'my_books', 'rejected_stories', 'earnings', 'contest'};

  static String? _str(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? _slug(Map<String, dynamic> data) => _str(data, 'slug') ?? _str(data, 'story_slug');

  /// Whether this payload leads to a specific screen (the notification list
  /// uses this to decide if an item is tappable).
  static bool canOpen(Map<String, dynamic>? data) {
    if (data == null) return false;
    final screen = _str(data, 'screen');
    if (screen == 'my_books' && !_isAuthor) return false;
    return _slug(data) != null ||
        _authorScreens.contains(screen) ||
        screen == 'rewards' ||
        screen == 'vip' ||
        _str(data, 'username') != null;
  }

  static bool get _isAuthor {
    try {
      return Get.find<AuthController>().isAuthor;
    } catch (_) {
      return false;
    }
  }

  /// Open now (the app's navigator is ready).
  static void open(Map<String, dynamic>? data, {bool fallbackToList = false}) {
    if (data == null) return;
    final screen = _str(data, 'screen');
    final slug = _slug(data);
    final username = _str(data, 'username');

    if (_authorScreens.contains(screen) && _isAuthor) {
      Get.to(() => const AuthorDashboardScreen());
    } else if (screen == 'rewards') {
      Get.to(() => const RewardsScreen());
    } else if (screen == 'vip') {
      Get.to(() => const VipScreen());
    } else if (slug != null) {
      Get.to(() => StoryDetailScreen(slug: slug));
    } else if (username != null) {
      Get.to(() => AuthorProfileScreen(username: username));
    } else if (fallbackToList) {
      if (!Get.isRegistered<NotificationController>()) Get.put(NotificationController());
      Get.to(() => const NotificationScreen());
    }
  }

  /// A push was tapped: open its target, or the notification list.
  static void openPush(Map<String, dynamic>? data) => open(data ?? const {}, fallbackToList: true);

  /// Payload of a locally shown notification (stored as JSON).
  static void openPayload(String? payload) {
    Map<String, dynamic> data = const {};
    if (payload != null && payload.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      } catch (_) {}
    }
    openPush(data);
  }

  /// Whether a push / link launched the app (the home screen then skips its
  /// launch promotion so the reader lands where they tapped).
  static bool get hasPending => _pending != null;

  /// Remember a launch payload until the main screen calls [consumePending].
  static void setPending(Map<String, dynamic> data) => _pending = data;

  static void consumePending() {
    final data = _pending;
    _pending = null;
    if (data != null) openPush(data);
  }
}
