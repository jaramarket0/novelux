import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:novelux/config/notification_router.dart';

/// Opens the app's book screen for website links (Android App Links / iOS
/// Universal Links), e.g.
///   https://www.novelux.app/explore/<slug>/
///   https://www.novelux.app/explore/<slug>/chapter/<n>/
///   https://www.novelux.app/story/<slug>/      (share links)
///
/// The site serves /.well-known/assetlinks.json and
/// apple-app-site-association so the phone trusts these links.
class DeepLinkService {
  DeepLinkService._();

  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  /// Call once after runApp().
  static Future<void> init() async {
    try {
      // Link that launched the app — opened by MainScreen once it's up.
      final initial = await _appLinks.getInitialLink();
      final data = _toRouteData(initial);
      if (data != null) NotificationRouter.setPending(data);
    } catch (e) {
      debugPrint('[DeepLink] initial link failed: $e');
    }
    // Links tapped while the app is already running.
    _sub ??= _appLinks.uriLinkStream.listen(
      (uri) => NotificationRouter.open(_toRouteData(uri)),
      onError: (e) => debugPrint('[DeepLink] stream error: $e'),
    );
  }

  /// /explore/<slug>/…  or  /story/<slug>/…  →  {"screen": "story", "slug": …}
  static Map<String, dynamic>? _toRouteData(Uri? uri) {
    if (uri == null) return null;
    final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2 && (parts[0] == 'explore' || parts[0] == 'story')) {
      return {'screen': 'story', 'slug': parts[1]};
    }
    return null;
  }
}
