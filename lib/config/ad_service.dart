import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:novelux/screen/auth/auth_controller.dart';

// ── Ad unit IDs ───────────────────────────────────────────────────────────────
// TODO: replace these test IDs with your real AdMob unit IDs before release.
class _AdIds {
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get rewarded => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
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
  int _chaptersRead = 0;

  // Show an interstitial every N chapter navigations.
  static const int _interstitialFrequency = 3;

  Future<void> initialize() async {
    // Register your physical test device so ads don't count as real impressions.
    // The device ID is printed in logcat: "Use RequestConfiguration.Builder().setTestDeviceIds(...)"
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ['D765BCFDB63B9A189BAFFE520F7AB908']),
    );
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
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
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Call this every time the user navigates to a new chapter.
  void onChapterRead() {
    if (_isVip) return;
    _chaptersRead++;
    if (_chaptersRead % _interstitialFrequency == 0) {
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
        onAdFailedToLoad: (_) => _rewarded = null,
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
        onAdFailedToLoad: (ad, _) {
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

  static String get _unitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/3986624511';

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
        onAdFailedToLoad: (ad, _) {
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
