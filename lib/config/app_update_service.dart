import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:upgrader/upgrader.dart';

/// Prompts readers to install a newer store version of the app.
///
/// Android uses Google Play's own in-app update UI:
///  * flexible (download in the background, then "Restart") by default;
///  * immediate (full-screen, blocking) when the release was published with
///    an in-app update priority of 4 or 5 in Play Console.
/// It only works for installs that came from Google Play.
///
/// iOS has no system equivalent, so we show a dialog that opens the App Store
/// listing, at most once every 3 days per version.
///
/// Shorebird patches need none of this — they apply silently on restart.
class AppUpdateService {
  AppUpdateService._();

  static bool _checked = false;

  /// Run once per app launch, after the first screen is up.
  static Future<void> checkForUpdate() async {
    if (_checked || kIsWeb) return;
    _checked = true;
    try {
      if (Platform.isAndroid) {
        await _checkAndroid();
      } else if (Platform.isIOS) {
        await _checkIOS();
      }
    } catch (e) {
      // Sideloaded APKs, emulators without Play, no network… never crash.
      debugPrint('[AppUpdate] check failed: $e');
    }
  }

  /// Manual "Check for updates" button. Unlike [checkForUpdate] this always
  /// gives the reader feedback — a spinner while it checks, then either an
  /// update flow or a "you're up to date" message — and ignores the one-shot
  /// and throttle guards so it works every time it's tapped.
  static Future<void> checkForUpdateInteractive() async {
    if (kIsWeb) {
      _snack('Updates', 'Update checks are not available on the web.');
      return;
    }

    // Blocking spinner so a slow network call doesn't look like a dead button.
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final bool updateStarted;
      if (Platform.isAndroid) {
        updateStarted = await _checkAndroidInteractive();
      } else if (Platform.isIOS) {
        updateStarted = await _checkIOSInteractive();
      } else {
        updateStarted = false;
      }
      _closeLoader();
      if (!updateStarted) {
        _snack('You\'re up to date', 'You have the latest version installed.');
      }
    } catch (e) {
      debugPrint('[AppUpdate] interactive check failed: $e');
      _closeLoader();
      _snack(
        'Couldn\'t check for updates',
        'Please check your connection and try again.',
      );
    }
  }

  static void _closeLoader() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  static void _snack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 90),
      duration: const Duration(seconds: 4),
    );
  }

  // ── Interactive variants (used by the manual button) ─────────────────────

  /// Returns true if an update flow was started (so the caller skips the
  /// "up to date" message).
  static Future<bool> _checkAndroidInteractive() async {
    final info = await InAppUpdate.checkForUpdate();

    if (info.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress) {
      await InAppUpdate.performImmediateUpdate();
      return true;
    }
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return false;
    }

    if (info.updatePriority >= 4 && info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
      return true;
    }
    if (info.flexibleUpdateAllowed) {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        Get.snackbar(
          'Update ready',
          'A new version of HuxNovel has been downloaded.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 10),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 90),
          mainButton: TextButton(
            onPressed: InAppUpdate.completeFlexibleUpdate,
            child: const Text('RESTART'),
          ),
        );
      }
      return true;
    }
    // An update exists but Play can't update in-app (e.g. too old a jump) —
    // still tell the reader rather than claiming they're up to date.
    _snack('Update available', 'A new version is available on Google Play.');
    return true;
  }

  static Future<bool> _checkIOSInteractive() async {
    final upgrader = Upgrader();
    await upgrader.initialize();
    if (!upgrader.isUpdateAvailable()) return false;

    _closeLoader();
    final storeVersion = upgrader.currentAppStoreVersion;
    await Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Update available'),
        content: Text(
          storeVersion == null
              ? 'A new version of HuxNovel is available on the App Store.'
              : 'HuxNovel $storeVersion is available on the App Store.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Get.back(),
            child: const Text('Later'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Get.back();
              upgrader.sendUserToAppStore();
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return true;
  }

  // ── Android: Google Play in-app updates ──────────────────────────────────

  static Future<void> _checkAndroid() async {
    final info = await InAppUpdate.checkForUpdate();

    if (info.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress) {
      // A blocking update was interrupted — resume it.
      await InAppUpdate.performImmediateUpdate();
      return;
    }
    if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

    if (info.updatePriority >= 4 && info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
      return;
    }
    if (!info.flexibleUpdateAllowed) return;

    final result = await InAppUpdate.startFlexibleUpdate();
    if (result != AppUpdateResult.success) return;

    // Downloaded in the background — let the reader choose when to restart.
    Get.snackbar(
      'Update ready',
      'A new version of HuxNovel has been downloaded.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 10),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 90),
      mainButton: TextButton(
        onPressed: InAppUpdate.completeFlexibleUpdate,
        child: const Text('RESTART'),
      ),
    );
  }

  // ── iOS: App Store version check ─────────────────────────────────────────

  static Future<void> _checkIOS() async {
    final upgrader = Upgrader(
      durationUntilAlertAgain: const Duration(days: 3),
    );
    await upgrader.initialize();
    if (!upgrader.shouldDisplayUpgrade()) return;

    final storeVersion = upgrader.currentAppStoreVersion;
    await Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Update available'),
        content: Text(
          storeVersion == null
              ? 'A new version of HuxNovel is available on the App Store.'
              : 'HuxNovel $storeVersion is available on the App Store.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              upgrader.saveLastAlerted();
              Get.back();
            },
            child: const Text('Later'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Get.back();
              upgrader.sendUserToAppStore();
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
