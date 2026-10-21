import 'dart:convert';

import 'package:get/get.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';

/// Opens the screen a notification points to, from its data payload
/// (e.g. {"screen": "story", "slug": "moonbound"}).
///
/// Used by push taps (app closed, in background or open) and by the in-app
/// notification list.
class NotificationRouter {
  NotificationRouter._();

  /// Data from the push that launched the app. It is opened once the main
  /// screen is up — navigating earlier would be replaced by the splash
  /// screen's own navigation.
  static Map<String, dynamic>? _pending;

  /// Whether this payload leads somewhere we can open.
  static bool canOpen(Map<String, dynamic>? data) {
    if (data == null) return false;
    final slug = data['slug'];
    return data['screen'] == 'story' && slug is String && slug.isNotEmpty;
  }

  /// Open now (the app's navigator is ready).
  static void open(Map<String, dynamic>? data) {
    if (!canOpen(data)) return;
    Get.to(() => StoryDetailScreen(slug: data!['slug'] as String));
  }

  /// Payload of a locally shown notification (stored as JSON).
  static void openPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (_) {}
  }

  /// Remember a launch payload until the main screen calls [consumePending].
  static void setPending(Map<String, dynamic> data) {
    if (canOpen(data)) _pending = data;
  }

  static void consumePending() {
    final data = _pending;
    _pending = null;
    open(data);
  }
}
