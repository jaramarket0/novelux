import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ratings, without rewards (Play and App Store ban paying for reviews).
///
/// • [chapterFinished]: after a reader has moved on to a next chapter a few
///   times, the store's own rating pop-up is shown — once per install.
/// • [openStoreReview] ("Rate HuxNovel" in Me): opens the app's page in Google Play / the App Store so
/// the reader can leave a rating and review.
///
/// A button always opens the store page rather than the in-app review
/// pop-up: both stores limit how often that pop-up may appear and silently
/// skip it when over the limit, which would make the button look broken.
class AppReviewService {
  AppReviewService._();

  static const appStoreId = '6787187018';            // apps.apple.com/app/id6787187018
  static const androidPackage = 'com.daniel.huxnovel';

  static const promptAfterChapters = 5;
  static const _kCount = 'review_chapters_finished';
  static const _kAsked = 'review_prompt_shown';

  /// Call when a reader finishes a chapter and opens the next one.
  static Future<void> chapterFinished() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kAsked) ?? false) return;
      final n = (prefs.getInt(_kCount) ?? 0) + 1;
      await prefs.setInt(_kCount, n);
      if (n < promptAfterChapters) return;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await prefs.setBool(_kAsked, true);
      // Let the new chapter appear first, then ask.
      await Future<void>.delayed(const Duration(seconds: 2));
      await review.requestReview();
    } catch (e) {
      debugPrint('[Review] prompt failed: $e');
    }
  }

  /// Returns false if no store could be opened (e.g. a sideloaded build).
  static Future<bool> openStoreReview() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        // Goes straight to the "Write a Review" sheet
        final uri = Uri.parse('itms-apps://itunes.apple.com/app/id$appStoreId?action=write-review');
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
      }
      await InAppReview.instance.openStoreListing(appStoreId: appStoreId);
      return true;
    } catch (e) {
      debugPrint('[Review] store listing failed: $e');
    }
    final web = Uri.parse(!kIsWeb && Platform.isIOS
        ? 'https://apps.apple.com/app/id$appStoreId?action=write-review'
        : 'https://play.google.com/store/apps/details?id=$androidPackage');
    try {
      return await launchUrl(web, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
