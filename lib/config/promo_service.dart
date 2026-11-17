import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Book promotions shown when the app opens on the home screen.
///
/// The team creates them at /promotions/ (admins, chief and senior editors).
/// Two styles: a full-screen poster with a "Skip" countdown, or a pop-up card.
/// Each promotion is shown once per reader (the server remembers signed-in
/// readers; this device remembers the rest) and at most one per app launch.
class PromoService {
  PromoService._();

  static const _kSeen = 'promo_seen_ids';
  static bool _triedThisLaunch = false;

  /// Call once the home screen is up. [stillOnHome] guards against showing it
  /// after the reader has already moved on to another screen.
  static Future<void> maybeShow({required bool Function() stillOnHome}) async {
    if (_triedThisLaunch) return;
    _triedThisLaunch = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_kSeen) ?? <String>[];
      final res = await ApiService.getNextPromo(seen).timeout(const Duration(seconds: 8));
      final data = res['success'] == true ? res['data'] : null;
      final raw = data is Map ? data['promo'] : null;
      if (raw is! Map) return;
      final promo = Map<String, dynamic>.from(raw);
      final story = Map<String, dynamic>.from(promo['story'] as Map);
      final isSplash = promo['kind'] == 'splash';
      final image = promo['image'] as String?;
      final cover = story['cover'] as String?;
      if (isSplash && (image == null || image.isEmpty)) return;

      // Load the pictures first so the promotion never appears half-drawn
      final ctx = Get.context;
      if (ctx == null) return;
      await Future.wait([
        for (final url in {image, cover})
          if (url != null && url.isNotEmpty)
            precacheImage(CachedNetworkImageProvider(url), ctx),
      ]).timeout(const Duration(seconds: 8));

      // One thing at a time: not over an update prompt or another screen
      if (!stillOnHome() || Get.isDialogOpen == true || Get.isBottomSheetOpen == true) return;

      final id = (promo['id'] as num).toInt();
      await prefs.setStringList(_kSeen, [...seen, '$id'].take(200).toList());
      unawaited(ApiService.promoEvent(id, 'seen'));

      if (isSplash) {
        await Get.to(() => PromoSplash(promo: promo, story: story),
            transition: Transition.fadeIn, opaque: true, fullscreenDialog: true);
      } else {
        await Get.dialog(PromoPopup(promo: promo, story: story),
            barrierColor: Colors.black.withValues(alpha: 0.6), barrierDismissible: true);
      }
    } catch (e) {
      debugPrint('[Promo] not shown: $e');
    }
  }

  /// "View more": close the promotion and open the book.
  static void open(Map<String, dynamic> promo, Map<String, dynamic> story) {
    unawaited(ApiService.promoEvent((promo['id'] as num).toInt(), 'click'));
    Get.back();
    final slug = story['slug'] as String?;
    if (slug != null && slug.isNotEmpty) Get.to(() => StoryDetailScreen(slug: slug));
  }
}

// ── Full screen ───────────────────────────────────────────────────────────────

class PromoSplash extends StatefulWidget {
  const PromoSplash({super.key, required this.promo, required this.story});
  final Map<String, dynamic> promo;
  final Map<String, dynamic> story;

  @override
  State<PromoSplash> createState() => _PromoSplashState();
}

class _PromoSplashState extends State<PromoSplash> {
  late int _left;
  Timer? _timer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _left = ((widget.promo['skip_seconds'] as num?)?.toInt() ?? 3).clamp(1, 15);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        _close();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _close() {
    _timer?.cancel();
    if (_closed) return;
    _closed = true;
    Get.back();
  }

  void _viewMore() {
    _timer?.cancel();
    if (_closed) return;
    _closed = true;
    PromoService.open(widget.promo, widget.story);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = (widget.promo['button_text'] as String? ?? 'View more').toUpperCase();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: _viewMore,
              child: CachedNetworkImage(
                imageUrl: widget.promo['image'] as String,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 14,
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Skip $_left',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 56,
              child: Center(child: _GradientPill(label: label, onTap: _viewMore)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientPill extends StatelessWidget {
  const _GradientPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Color(0xFFE84393), Color(0xFFF39C12)]),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14)],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.black.withValues(alpha: 0.45),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFF39C12), size: 22),
          ]),
        ),
      ),
    );
  }
}

// ── Pop-up card ───────────────────────────────────────────────────────────────

class PromoPopup extends StatelessWidget {
  const PromoPopup({super.key, required this.promo, required this.story});
  final Map<String, dynamic> promo;
  final Map<String, dynamic> story;

  @override
  Widget build(BuildContext context) {
    // Fit any phone: 82% of the width, but never taller than ~68% of the screen
    final size = MediaQuery.of(context).size;
    final w = (size.width * 0.82).clamp(0.0, size.height * 0.68 / 1.22).toDouble();
    final bg = promo['image'] as String?;
    final cover = story['cover'] as String?;
    final tagline = (promo['tagline'] as String?)?.trim();
    final label = promo['button_text'] as String? ?? 'View more';

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () => PromoService.open(promo, story),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: w,
                height: w * 1.22,
                child: Stack(fit: StackFit.expand, children: [
                  // Background: the uploaded artwork, or the cover blurred
                  if (bg != null && bg.isNotEmpty)
                    CachedNetworkImage(imageUrl: bg, fit: BoxFit.cover)
                  else if (cover != null)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover),
                    )
                  else
                    const ColoredBox(color: Color(0xFF4A2C1E)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.65)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                    child: Column(children: [
                      if (cover != null)
                        Container(
                          width: w * 0.42,
                          height: w * 0.42 * 4 / 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 8))],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover),
                        ),
                      const Spacer(),
                      Text(
                        (tagline == null || tagline.isEmpty) ? (story['title'] as String? ?? '') : tagline,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFD4A017), width: 2),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFA11D1D), Color(0xFF5C0E0E)],
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(label,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    );
  }
}
