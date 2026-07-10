// ══════════════════════════════════════════════════════════════════════════════
//  NoveluX IAP Service — RevenueCat (Google Play + App Store)
//  File: lib/config/iap_service.dart
//
//  pubspec.yaml:
//    purchases_flutter: ^10.0.1
//
//  RevenueCat dashboard setup (app.revenuecat.com):
//  ┌──────────────────────────────────────────────────────────────────────────┐
//  │  1. Create a Project, then add two Apps:                                 │
//  │       • Play Store  → package  com.daniel.novelux.novelux                │
//  │       • App Store   → your iOS bundle id                                 │
//  │     Copy each app's PUBLIC API key into the constants below              │
//  │     (goog_… and appl_…).                                                 │
//  │                                                                          │
//  │  2. Products → import/add every store product ID listed below            │
//  │     (they must already exist in Play Console / App Store Connect).       │
//  │                                                                          │
//  │  3. Entitlements → identifier "access_all_novels", with the four         │
//  │     subscription products attached to it.                                │
//  │                                                                          │
//  │  4. Offerings → in the "default" (current) offering create a package     │
//  │     per product and attach the store products. Coin packs go in as       │
//  │     custom packages.                                                     │
//  │                                                                          │
//  │  5. Backend: point a RevenueCat Webhook at your server, or have          │
//  │     /coins/verify-purchases/ look up the purchase with RevenueCat's      │
//  │     REST API (GET /v1/subscribers/{app_user_id}). The app now sends      │
//  │     the RevenueCat app-user-id in the "receipt" field.                   │
//  └──────────────────────────────────────────────────────────────────────────┘
//
//  How it works:
//  1. IAPService registers as a GetxService singleton at app start
//  2. It immediately shows fallback ₦ prices so UI is never empty
//  3. It loads real store prices from the RevenueCat Offering in background
//  4. When user buys: RevenueCat launches the native Play/StoreKit dialog
//     and verifies the receipt on its servers
//  5. VIP is granted from the "access_all_novels" entitlement; coins are
//     granted by your backend (webhook / verify call)
//  6. Purchases.logIn(userId) ties purchases to the signed-in account so
//     VIP restores across devices
//
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'package:novelux/config/api_service.dart';
import 'dart:developer' as myLog;

// ══════════════════════════════════════════════════════════════════════════════
//  REVENUECAT KEYS — paste your PUBLIC SDK keys from
//  RevenueCat → Project settings → API keys
// ══════════════════════════════════════════════════════════════════════════════

const _kRevenueCatGoogleApiKey = 'goog_dnINXRYLciWwzRXMHFlXoMRfaKT';
const _kRevenueCatAppleApiKey = 'appl_yTpmYATACUHKTgfIHqBFnionjnT';

/// Entitlement identifier configured in the RevenueCat dashboard.
const _kVipEntitlement = 'access_all_novels';

// ══════════════════════════════════════════════════════════════════════════════
//  PRODUCT IDs — must match Play Console / App Store Connect exactly
// ══════════════════════════════════════════════════════════════════════════════

const kSubWeekly     = 'novelux_vip_weekly';
const kSubMonthly    = 'novelux_vip_monthly';
const kSubQuarterly  = 'novelux_vip_quarterly';
const kSubYearly     = 'novelux_vip_yearly';

const kCoins100  = 'novelux_coins_100';
const kCoins500  = 'novelux_coins_500';
const kCoins1000 = 'novelux_coins_1000';
const kCoins2500 = 'novelux_coins_2500';
const kCoins5000 = 'novelux_coins_5000';

const _kSubIds  = {kSubWeekly, kSubMonthly, kSubQuarterly, kSubYearly};
const _kCoinIds = {kCoins100, kCoins500, kCoins1000, kCoins2500, kCoins5000};
const _kAllIds  = {..._kSubIds, ..._kCoinIds};

/// RevenueCat reports Google subscriptions as "productId:basePlanId" —
/// normalize back to the plain product id used everywhere in the app.
String _baseId(String storeIdentifier) => storeIdentifier.split(':').first;

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

enum PurchaseStatus2 { success, cancelled, error, pending }

class PurchaseResult {
  final PurchaseStatus2 status;
  final String? message;
  final int? coinsGranted;
  final bool isVip;

  const PurchaseResult._({
    required this.status,
    this.message,
    this.coinsGranted,
    this.isVip = false,
  });

  factory PurchaseResult.success({int? coins, bool vip = false, String? msg}) =>
      PurchaseResult._(
        status: PurchaseStatus2.success,
        coinsGranted: coins,
        isVip: vip,
        message: msg,
      );

  factory PurchaseResult.cancelled() =>
      const PurchaseResult._(status: PurchaseStatus2.cancelled);

  factory PurchaseResult.error(String msg) =>
      PurchaseResult._(status: PurchaseStatus2.error, message: msg);

  factory PurchaseResult.pending() =>
      const PurchaseResult._(status: PurchaseStatus2.pending);

  bool get ok => status == PurchaseStatus2.success;
  bool get wasCancelled => status == PurchaseStatus2.cancelled;
  bool get failed => status == PurchaseStatus2.error;
}

// ── VIP plan ─────────────────────────────────────────────────────────────────

class VipPlan {
  final String id;
  final String name;
  final String price; // from store, or fallback
  final String period;
  final String? badge;
  final bool isPrimary;
  final rc.Package? rcPackage; // preferred purchase path (from Offerings)
  final rc.StoreProduct? product; // null until store responds

  const VipPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    this.badge,
    this.isPrimary = false,
    this.rcPackage,
    this.product,
  });

  VipPlan copyWith({
    String? price,
    rc.Package? rcPackage,
    rc.StoreProduct? product,
  }) => VipPlan(
    id: id,
    name: name,
    period: period,
    badge: badge,
    isPrimary: isPrimary,
    price: price ?? this.price,
    rcPackage: rcPackage ?? this.rcPackage,
    product: product ?? this.product,
  );
}

// ── Coin pack ─────────────────────────────────────────────────────────────────

class CoinPack {
  final String id;
  final int coins;
  final String label;
  final String price;
  final String? bonus;
  final bool isPopular;
  final rc.Package? rcPackage;
  final rc.StoreProduct? product;

  const CoinPack({
    required this.id,
    required this.coins,
    required this.label,
    required this.price,
    this.bonus,
    this.isPopular = false,
    this.rcPackage,
    this.product,
  });

  CoinPack copyWith({
    String? price,
    rc.Package? rcPackage,
    rc.StoreProduct? product,
  }) => CoinPack(
    id: id,
    coins: coins,
    label: label,
    bonus: bonus,
    isPopular: isPopular,
    price: price ?? this.price,
    rcPackage: rcPackage ?? this.rcPackage,
    product: product ?? this.product,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  IAP SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class IAPService extends GetxService {
  static IAPService get to => Get.find<IAPService>();

  // ── Observable state ────────────────────────────────────────────────────────
  final RxBool storeAvailable = false.obs;
  final RxBool isLoadingPrices = false.obs; // background price fetch
  final RxBool isPurchasing = false.obs;
  final RxBool isVip = false.obs;
  final RxString activeSubId = ''.obs;
  final RxString errorMsg = ''.obs;

  final RxList<VipPlan> vipPlans = <VipPlan>[].obs;
  final RxList<CoinPack> coinPacks = <CoinPack>[].obs;

  // ── Fallback prices shown immediately before store responds ─────────────────
  static const _defaultPlans = [
    VipPlan(id: kSubWeekly,    name: 'Weekly',    price: '₦3,900',  period: '/wk'),
    VipPlan(
      id: kSubMonthly,
      name: 'Monthly',
      price: '₦59,900',
      period: '/mo',
      badge: 'Most Popular',
      isPrimary: true,
    ),
    VipPlan(
      id: kSubQuarterly,
      name: 'Quarterly',
      price: '₦179,900',
      period: '/3 mo',
      badge: 'Save 13%',
    ),
    VipPlan(
      id: kSubYearly,
      name: 'Yearly',
      price: '₦499,900',
      period: '/yr',
      badge: 'Best Value',
    ),
  ];

  static const _defaultPacks = [
    CoinPack(id: kCoins100,  coins: 100,  label: '100 Coins',   price: '₦1500'),
    CoinPack(
      id: kCoins500,
      coins: 500,
      label: '500 Coins',
      price: '₦7,900',
      isPopular: true,
    ),
    CoinPack(id: kCoins1000, coins: 1000, label: '1,000 Coins', price: '₦14,900'),
    CoinPack(id: kCoins2500, coins: 2500, label: '2,500 Coins', price: '₦39,900'),
    CoinPack(id: kCoins5000, coins: 5000, label: '5,000 Coins', price: '₦79,900'),
  ];

  // ── Internal ────────────────────────────────────────────────────────────────
  bool _initialized = false; // main.dart awaits onInit() before Get registers us

  bool get _platformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ══════════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> onInit() async {
    super.onInit();
    if (_initialized) return;
    _initialized = true;

    // Populate with fallback prices immediately — no blank state
    vipPlans.value = List.from(_defaultPlans);
    coinPacks.value = List.from(_defaultPacks);

    if (!_platformSupported) {
      debugPrint('[IAP] RevenueCat not supported on this platform');
      return;
    }

    try {
      await rc.Purchases.setLogLevel(
        kDebugMode ? rc.LogLevel.debug : rc.LogLevel.info,
      );
      final apiKey = Platform.isAndroid
          ? _kRevenueCatGoogleApiKey
          : _kRevenueCatAppleApiKey;
      await rc.Purchases.configure(rc.PurchasesConfiguration(apiKey));
      storeAvailable.value = true;
    } catch (e) {
      debugPrint('[IAP] RevenueCat configure failed: $e');
      return;
    }

    // VIP entitlement updates for the entire app lifetime
    rc.Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);

    // Fetch real prices in background — UI already showing fallback
    _fetchPrices();

    // Load current entitlements (cache-first, so this is fast)
    refreshVipStatus();
  }

  @override
  void onClose() {
    if (storeAvailable.value) {
      rc.Purchases.removeCustomerInfoUpdateListener(_applyCustomerInfo);
    }
    super.onClose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACCOUNT LINKING — call after login / logout so purchases follow the user
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> logIn(String appUserId) async {
    if (!storeAvailable.value || appUserId.isEmpty) return;
    try {
      final result = await rc.Purchases.logIn(appUserId);
      _applyCustomerInfo(result.customerInfo);
    } catch (e) {
      debugPrint('[IAP] logIn failed: $e');
    }
  }

  Future<void> logOut() async {
    if (!storeAvailable.value) return;
    try {
      final info = await rc.Purchases.logOut();
      _applyCustomerInfo(info);
    } catch (e) {
      debugPrint('[IAP] logOut failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FETCH REAL PRICES FROM REVENUECAT OFFERINGS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchPrices() async {
    if (!storeAvailable.value) return;
    isLoadingPrices.value = true;
    try {
      // Preferred source: packages from the RevenueCat Offerings
      final Map<String, rc.Package> packagesById = {};
      try {
        final offerings = await rc.Purchases.getOfferings();
        final packages = [
          ...?offerings.current?.availablePackages,
          for (final o in offerings.all.values) ...o.availablePackages,
        ];
        for (final pkg in packages) {
          packagesById.putIfAbsent(
            _baseId(pkg.storeProduct.identifier),
            () => pkg,
          );
        }
      } catch (e) {
        debugPrint('[IAP] getOfferings failed: $e');
      }

      // Fallback: query the stores directly for anything not in an offering
      final Map<String, rc.StoreProduct> productsById = {};
      final missing =
          _kAllIds.where((id) => !packagesById.containsKey(id)).toList();
      if (missing.isNotEmpty) {
        final subs = await rc.Purchases.getProducts(
          missing,
          productCategory: rc.ProductCategory.subscription,
        );
        final inapps = await rc.Purchases.getProducts(
          missing,
          productCategory: rc.ProductCategory.nonSubscription,
        );
        for (final p in [...subs, ...inapps]) {
          productsById.putIfAbsent(_baseId(p.identifier), () => p);
        }
      }

      if (packagesById.isEmpty && productsById.isEmpty) {
        debugPrint(
          '[IAP] No products returned — using fallback prices. '
          'Check the RevenueCat dashboard (products imported, offering '
          'configured) and that the store products are ACTIVE.',
        );
        isLoadingPrices.value = false;
        return;
      }

      // Merge real prices into VipPlan list
      vipPlans.value = _defaultPlans.map((plan) {
        final pkg = packagesById[plan.id];
        final prod = pkg?.storeProduct ?? productsById[plan.id];
        return prod != null
            ? plan.copyWith(
                price: prod.priceString,
                rcPackage: pkg,
                product: prod,
              )
            : plan;
      }).toList();

      // Merge real prices into CoinPack list
      coinPacks.value = _defaultPacks.map((pack) {
        final pkg = packagesById[pack.id];
        final prod = pkg?.storeProduct ?? productsById[pack.id];
        return prod != null
            ? pack.copyWith(
                price: prod.priceString,
                rcPackage: pkg,
                product: prod,
              )
            : pack;
      }).toList();

      debugPrint(
        '[IAP] Loaded ${packagesById.length} packages + '
        '${productsById.length} direct products from RevenueCat',
      );
    } catch (e) {
      debugPrint('[IAP] _fetchPrices error: $e');
    }
    isLoadingPrices.value = false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUY SUBSCRIPTION
  // ══════════════════════════════════════════════════════════════════════════

  /// Purchase a VIP subscription.
  /// Always returns — never throws. Caller checks [PurchaseResult.ok].
  Future<PurchaseResult> buySubscription(String productId) async {
    if (isPurchasing.value) {
      return PurchaseResult.error('A purchase is already in progress.');
    }
    if (!storeAvailable.value) {
      return PurchaseResult.error('The store is not available on this device.');
    }

    errorMsg.value = '';

    var plan = vipPlans.firstWhereOrNull((p) => p.id == productId);
    if (plan?.rcPackage == null && plan?.product == null) {
      // Products not yet loaded from store (still showing fallback)
      if (!isLoadingPrices.value) await _fetchPrices();
      plan = vipPlans.firstWhereOrNull((p) => p.id == productId);
      if (plan?.rcPackage == null && plan?.product == null) {
        return PurchaseResult.error(
          'Product not available yet. Please wait a moment and try again.',
        );
      }
    }

    return _launchPurchase(
      productId: productId,
      package: plan!.rcPackage,
      product: plan.product,
      isSubscription: true,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUY COINS  (one-time consumable)
  // ══════════════════════════════════════════════════════════════════════════

  Future<PurchaseResult> buyCoins(String productId) async {
    myLog.log('Attempting to buy coins: $productId');
    if (isPurchasing.value) {
      return PurchaseResult.error('A purchase is already in progress.');
    }
    if (!storeAvailable.value) {
      return PurchaseResult.error('The store is not available on this device.');
    }

    errorMsg.value = '';

    var pack = coinPacks.firstWhereOrNull((p) => p.id == productId);
    if (pack?.rcPackage == null && pack?.product == null) {
      if (!isLoadingPrices.value) await _fetchPrices();
      pack = coinPacks.firstWhereOrNull((p) => p.id == productId);
      if (pack?.rcPackage == null && pack?.product == null) {
        return PurchaseResult.error(
          'Product not available yet. Please try again shortly.',
        );
      }
    }

    return _launchPurchase(
      productId: productId,
      package: pack!.rcPackage,
      product: pack.product,
      isSubscription: false,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INTERNAL: LAUNCH THE NATIVE PURCHASE DIALOG VIA REVENUECAT
  // ══════════════════════════════════════════════════════════════════════════

  Future<PurchaseResult> _launchPurchase({
    required String productId,
    required bool isSubscription,
    rc.Package? package,
    rc.StoreProduct? product,
  }) async {
    isPurchasing.value = true;
    try {
      // Google Play upgrade/downgrade: pass the currently active sub
      rc.StoreProductChangeInfo? changeInfo;
      if (isSubscription &&
          Platform.isAndroid &&
          activeSubId.value.isNotEmpty &&
          activeSubId.value != productId) {
        changeInfo = rc.StoreProductChangeInfo(
          activeSubId.value,
          replacementMode: rc.StoreReplacementMode.withTimeProration,
        );
      }

      final params = package != null
          ? rc.PurchaseParams.package(package, productChangeInfo: changeInfo)
          : rc.PurchaseParams.storeProduct(
              product!,
              productChangeInfo: changeInfo,
            );

      final result = await rc.Purchases.purchase(params);
      _applyCustomerInfo(result.customerInfo);

      if (isSubscription) {
        // RevenueCat already verified the receipt; the entitlement is the
        // source of truth. Backend is notified in the background (webhooks
        // are the reliable channel).
        isPurchasing.value = false;
        _notifyBackend(productId, result.storeTransaction).then((res) {
          debugPrint('[IAP] backend sub sync: ${res['success']}');
        }).catchError((Object e) {
          debugPrint('[IAP] backend sub sync failed: $e');
        });
        return PurchaseResult.success(vip: true);
      }

      // Coins: the backend grants the balance
      final res = await _notifyBackend(productId, result.storeTransaction);
      isPurchasing.value = false;

      if (res['success'] == true) {
        final coinsGranted =
            (res['data']?['coins_granted'] as num?)?.toInt() ?? 0;
        return PurchaseResult.success(coins: coinsGranted);
      }
      final errMsg = res['error']?.toString() ??
          'Backend could not verify purchase. Contact support.';
      errorMsg.value = errMsg;
      return PurchaseResult.error(errMsg);
    } on PlatformException catch (e) {
      isPurchasing.value = false;
      final code = rc.PurchasesErrorHelper.getErrorCode(e);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled();
      }
      if (code == rc.PurchasesErrorCode.paymentPendingError) {
        return PurchaseResult.pending();
      }
      final msg = e.message ?? 'Purchase failed.';
      errorMsg.value = msg;
      return PurchaseResult.error(msg);
    } catch (e) {
      isPurchasing.value = false;
      return PurchaseResult.error(e.toString());
    }
  }

  /// Tell the backend about a purchase. The "receipt" field carries the
  /// RevenueCat app-user-id so the server can confirm the purchase via
  /// RevenueCat's REST API (or rely on webhooks) before granting coins/VIP.
  Future<Map<String, dynamic>> _notifyBackend(
    String productId,
    rc.StoreTransaction transaction,
  ) async {
    final appUserId = await rc.Purchases.appUserID;
    return ApiService.verifyPurchase(
      productId: productId,
      purchaseId: transaction.transactionIdentifier,
      receipt: appUserId,
      platform: Platform.isAndroid ? 'android' : 'ios',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RESTORE PURCHASES
  // ══════════════════════════════════════════════════════════════════════════

  /// Re-syncs purchases from the store account.
  /// Call when user taps "Restore purchases".
  Future<PurchaseResult> restorePurchases() async {
    if (!storeAvailable.value) {
      return PurchaseResult.error('Store not available.');
    }

    isPurchasing.value = true;
    try {
      final info = await rc.Purchases.restorePurchases();
      _applyCustomerInfo(info);
      isPurchasing.value = false;

      if (isVip.value) {
        return PurchaseResult.success(vip: true, msg: 'VIP restored!');
      }
      return PurchaseResult.error(
        'No active subscription found on this account.',
      );
    } on PlatformException catch (e) {
      isPurchasing.value = false;
      return PurchaseResult.error('Restore failed: ${e.message ?? e.code}');
    } catch (e) {
      isPurchasing.value = false;
      return PurchaseResult.error('Restore failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  VIP STATUS (from RevenueCat entitlements)
  // ══════════════════════════════════════════════════════════════════════════

  void _applyCustomerInfo(rc.CustomerInfo info) {
    final entitlement = info.entitlements.active[_kVipEntitlement];
    var vip = entitlement != null;
    var subId =
        entitlement != null ? _baseId(entitlement.productIdentifier) : '';

    if (!vip) {
      // Fallback if the entitlement isn't configured in the dashboard yet
      for (final active in info.activeSubscriptions) {
        final id = _baseId(active);
        if (_kSubIds.contains(id)) {
          vip = true;
          subId = id;
          break;
        }
      }
    }

    isVip.value = vip;
    activeSubId.value = subId;
    debugPrint('[IAP] VIP: $vip (sub: $subId)');
  }

  // Refresh on demand (call after login)
  Future<void> refreshVipStatus() async {
    if (!storeAvailable.value) return;
    try {
      final info = await rc.Purchases.getCustomerInfo();
      _applyCustomerInfo(info);
    } catch (e) {
      debugPrint('[IAP] VIP status check failed: $e');
    }
  }
}
