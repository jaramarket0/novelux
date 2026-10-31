import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Thin wrapper around Firebase Analytics.
///
/// Registered once at startup ([AnalyticsService.init]) and reachable anywhere
/// with `AnalyticsService.to`. Automatic screen tracking is handled by
/// [observer], which is added to GetMaterialApp's navigatorObservers.
///
/// Every call is wrapped so a logging failure (no network, Play Services
/// missing on an emulator, etc.) can never crash the app.
class AnalyticsService extends GetxService {
  static AnalyticsService get to => Get.find<AnalyticsService>();

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// Drop this into `navigatorObservers` for automatic `screen_view` events.
  late final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  /// Must run after `Firebase.initializeApp`. Disables collection in debug so
  /// development traffic doesn't pollute the production dashboards.
  static Future<AnalyticsService> init() async {
    final svc = AnalyticsService();
    try {
      await svc.analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    } catch (e) {
      debugPrint('[Analytics] init failed: $e');
    }
    return svc;
  }

  // ── Generic logging ────────────────────────────────────────────────────────

  /// Logs a custom event. Parameter values must be String or num; everything
  /// else is coerced to a string so a bad value can't throw.
  Future<void> logEvent(String name, [Map<String, Object?>? params]) async {
    try {
      Map<String, Object>? clean;
      if (params != null) {
        clean = {
          for (final e in params.entries)
            if (e.value != null)
              e.key: (e.value is num || e.value is String)
                  ? e.value as Object
                  : e.value.toString(),
        };
      }
      await analytics.logEvent(name: name, parameters: clean);
    } catch (e) {
      debugPrint('[Analytics] logEvent($name) failed: $e');
    }
  }

  Future<void> logScreen(String screenName, {String? screenClass}) async {
    try {
      await analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('[Analytics] logScreen($screenName) failed: $e');
    }
  }

  // ── Auth lifecycle ─────────────────────────────────────────────────────────

  Future<void> logLogin({String method = 'password'}) async {
    try {
      await analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('[Analytics] logLogin failed: $e');
    }
  }

  Future<void> logSignUp({String method = 'password'}) async {
    try {
      await analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('[Analytics] logSignUp failed: $e');
    }
  }

  /// Tie events to the signed-in reader and set a few segmentation properties.
  Future<void> setUser({
    required String id,
    String? role,
    bool? isVip,
  }) async {
    try {
      await analytics.setUserId(id: id.isEmpty ? null : id);
      if (role != null) {
        await analytics.setUserProperty(name: 'role', value: role);
      }
      if (isVip != null) {
        await analytics.setUserProperty(
          name: 'is_vip',
          value: isVip.toString(),
        );
      }
    } catch (e) {
      debugPrint('[Analytics] setUser failed: $e');
    }
  }

  /// Clear identity on sign-out.
  Future<void> clearUser() async {
    try {
      await analytics.setUserId(id: null);
      await analytics.resetAnalyticsData();
    } catch (e) {
      debugPrint('[Analytics] clearUser failed: $e');
    }
  }

  // ── App-specific convenience events ────────────────────────────────────────

  Future<void> logStoryOpen(String slug, {String? title}) =>
      logEvent('story_open', {'story_slug': slug, 'story_title': title});

  Future<void> logChapterRead(
    String slug,
    int chapterNumber, {
    String? title,
  }) =>
      logEvent('chapter_read', {
        'story_slug': slug,
        'chapter_number': chapterNumber,
        'chapter_title': title,
      });

  Future<void> logSearch(String query) =>
      logEvent('search', {'search_term': query});
}
