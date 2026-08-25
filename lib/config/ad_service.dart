import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/screen/auth/auth_controller.dart';

// ── Ad unit IDs ───────────────────────────────────────────────────────────────
class _AdIds {
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-8703660804731523/6317420894'
      : 'ca-app-pub-8703660804731523/4178342712';

  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-8703660804731523/8736690355'
      : 'ca-app-pub-8703660804731523/5742705826';

  static String get rewarded => Platform.isAndroid
      ? 'ca-app-pub-8703660804731523/8928211716'
      : 'ca-app-pub-8703660804731523/1364477114';

  static String get rewardedInterstitial => Platform.isAndroid
      ? 'ca-app-pub-8703660804731523/7998273427'
      : 'ca-app-pub-8703660804731523/2677558785';

  static String get native => Platform.isAndroid
      ? 'ca-app-pub-8703660804731523/5930408082'
      : 'ca-app-pub-8703660804731523/9490379140';
}

// ── Load failure logging ──────────────────────────────────────────────────────
/// AdMob's own error codes, surfaced because a silently-swallowed
/// `onAdFailedToLoad` makes "no ads are showing" impossible to diagnose.
///   0 internal · 1 invalid request · 2 network · 3 NO FILL · 8 missing app id
/// Code 3 on a brand-new unit usually means the AdMob app is not yet linked to
/// its store listing, not that the integration is broken.
void _logAdFailure(String slot, LoadAdError error) {
  debugPrint(
    '[Ads] $slot failed to load — code ${error.code} (${error.domain}): '
    '${error.message}',
  );
}

// ── VIP guard ─────────────────────────────────────────────────────────────────
bool get _isVip {
  try {
    return Get.find<AuthController>().isVip;
  } catch (_) {
    return false;
  }
}

// ── AdService singleton ───────────────────────────────────────────────────────
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  RewardedInterstitialAd? _rewardedInterstitial;
  int _chaptersRead = 0;

  // Show a plain interstitial every N chapter navigations...
  static const int _interstitialFrequency = 3;
  // ...but every M chapters, show a rewarded interstitial instead (takes
  // priority over the plain interstitial on chapters where both would fire).
  static const int _rewardedInterstitialFrequency = 10;

  /// Asks for tracking permission on iOS. Must run *before* MobileAds
  /// initialises: without it every iOS request goes out with no IDFA and is
  /// treated as non-personalised, which is a large part of why iOS fill is
  /// far worse than Android. Required by App Store guideline 5.1.2 whenever
  /// an app requests tracking data.
  ///
  /// Declining is fine — ads still serve, just non-personalised — so nothing
  /// in the app is gated on the answer.
  Future<void> _requestTrackingAuthorization() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      // Only 'notDetermined' may prompt; asking again once answered is a no-op
      // and iOS will not re-show the dialog.
      if (status == TrackingStatus.notDetermined) {
        // A short delay lets the first frame settle — requesting while the app
        // is still launching silently returns denied on some iOS versions.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('[Ads] ATT result: $result');
      } else {
        debugPrint('[Ads] ATT already decided: $status');
      }
    } catch (e) {
      // Never let a tracking prompt failure stop ads initialising.
      debugPrint('[Ads] ATT request failed: $e');
    }
  }

  Future<void> initialize() async {
    await _requestTrackingAuthorization();

    // Register your physical test device so ads don't count as real impressions.
    // The device ID is printed in logcat: "Use RequestConfiguration.Builder().setTestDeviceIds(...)"
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ['D765BCFDB63B9A189BAFFE520F7AB908']),
    );
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
    _loadRewardedInterstitial();
  }

  // ── Banner ──────────────────────────────────────────────────────────────────
  BannerAd buildBanner({BannerAdListener? listener}) => BannerAd(
        adUnitId: _AdIds.banner,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: listener ?? const BannerAdListener(),
      );

  // ── Interstitial ────────────────────────────────────────────────────────────
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (e) {
          _logAdFailure('interstitial', e);
          _interstitial = null;
        },
      ),
    );
  }

  /// Call this every time the user navigates to a new chapter.
  void onChapterRead() {
    if (_isVip) return;
    _chaptersRead++;
    if (_chaptersRead % _rewardedInterstitialFrequency == 0) {
      _showRewardedInterstitial();
    } else if (_chaptersRead % _interstitialFrequency == 0) {
      _showInterstitial();
    }
  }

  void _showInterstitial() {
    final ad = _interstitial;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );
    ad.show();
  }

  // ── Rewarded ────────────────────────────────────────────────────────────────
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (e) {
          _logAdFailure('rewarded', e);
          _rewarded = null;
        },
      ),
    );
  }

  bool get isRewardedReady => _rewarded != null;

  /// Shows the rewarded ad. Calls [onRewarded] with the coin amount when the
  /// user earns the reward. Returns false if no ad is loaded.
  Future<bool> showRewarded({
    required void Function(int coins) onRewarded,
  }) async {
    final ad = _rewarded;
    if (ad == null) return false;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (_, reward) => onRewarded(reward.amount.toInt()),
    );
    return completer.future;
  }

  // ── Rewarded interstitial ──────────────────────────────────────────────────
  // Auto-shown every _rewardedInterstitialFrequency chapters (see
  // onChapterRead) for non-VIP readers — unlike showRewarded(), this isn't
  // user-initiated, so it's fine if no ad happens to be loaded yet.
  static const int _rewardedInterstitialCoins = 2;

  void _loadRewardedInterstitial() {
    RewardedInterstitialAd.load(
      adUnitId: _AdIds.rewardedInterstitial,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => _rewardedInterstitial = ad,
        onAdFailedToLoad: (e) {
          _logAdFailure('rewardedInterstitial', e);
          _rewardedInterstitial = null;
        },
      ),
    );
  }

  void _showRewardedInterstitial() {
    final ad = _rewardedInterstitial;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewardedInterstitial = null;
        _loadRewardedInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewardedInterstitial = null;
        _loadRewardedInterstitial();
      },
    );
    ad.show(
      onUserEarnedReward: (_, __) async {
        final res = await ApiService.claimDailyReward(
          _rewardedInterstitialCoins,
          claimType: 'ad',
        );
        if (res['success'] == true) {
          try {
            await Get.find<AuthController>().refreshCoins();
          } catch (_) {}
          AppAlert.success('+$_rewardedInterstitialCoins Coins!');
        }
      },
    );
  }
}

// ── Reusable banner widget ────────────────────────────────────────────────────
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = AdService.instance.buildBanner(
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          _logAdFailure('banner', e);
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVip) return const SizedBox.shrink();
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      height: ad.size.height.toDouble(),
      width: ad.size.width.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

// ── Native Ad widget ──────────────────────────────────────────────────────────
// Shows a native ad styled to match story cards.
// width/height control the bounding box; pass null width for full-width (lists).
class NativeAdWidget extends StatefulWidget {
  final double? width;
  final double? height;
  const NativeAdWidget({super.key, this.width, this.height = 200});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _ad;
  bool _loaded = false;

  static String get _unitId => _AdIds.native;

  @override
  void initState() {
    super.initState();
    _ad = NativeAd(
      adUnitId: _unitId,
      factoryId: 'novelux_native_ad',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          _logAdFailure('native', e);
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVip) return const SizedBox.shrink();
    final ad = _ad;
    // When no explicit size given, expand to fill parent (e.g. inside a grid cell).
    final expand = widget.width == null && widget.height == null;
    if (!_loaded || ad == null) {
      return expand
          ? const SizedBox.expand()
          : SizedBox(width: widget.width, height: widget.height);
    }
    if (expand) return SizedBox.expand(child: AdWidget(ad: ad));
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AdWidget(ad: ad),
    );
  }
}
