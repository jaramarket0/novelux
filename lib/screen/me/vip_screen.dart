import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/iap_service.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/me/atomic_webview_screen.dart';
import 'package:novelux/screen/me/subscription_celebration.dart';
import 'package:novelux/widgets/custom_image_view.dart';
import 'package:novelux/widgets/auth_prompt_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Storefront that actually handles the subscription, so the renewal notice
/// never names the wrong platform. App Review rejects iOS builds that
/// reference Google Play (guideline 2.3.10).
String get _storeName {
  if (kIsWeb) return 'your account settings';
  if (Platform.isIOS || Platform.isMacOS) return 'Settings › Apple Account';
  return 'Google Play';
}

// ── Controller ────────────────────────────────────────────────────────────────
class VipController extends GetxController {
  final RxString selectedPlanId = ''.obs;

  Future<void> subscribe(String planId) async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) {
      // Offer sign-in in place, then carry on with the purchase they asked
      // for — never dead-end a guest on an error.
      if (await promptSignIn(AuthPromptReason.subscribe) != true) return;
    }
    final svc = IAPService.to;
    final result = await svc.buySubscription(planId);
    if (result.ok) {
      Get.dialog(
        SubscriptionCelebrationDialog(planId: planId),
        barrierDismissible: false,
      );
      // Backend learns about the purchase via RevenueCat (verify + webhook);
      // refresh the profile so is_vip, ads and chapter locks update
      Future.delayed(const Duration(seconds: 2), auth.fetchMe);
      Future.delayed(const Duration(seconds: 10), auth.fetchMe);
    } else if (result.failed) {
      AppAlert.error(result.message ?? 'Purchase failed. Please try again.');
    }
    // cancelled — silent
  }

  /// Opens the store's own subscription manager. Cancelling and changing plans
  /// must happen there — neither store lets an app do it in-process.
  Future<void> manageSubscription() async {
    final uri = Uri.parse(
      (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppAlert.error('Could not open $_storeName.');
    }
  }

  /// Required by App Store guideline 3.1.1 — someone who reinstalls or
  /// switches device must be able to get their subscription back without
  /// paying twice.
  Future<void> restore() async {
    if (isRestoring.value) return;
    isRestoring.value = true;
    final result = await IAPService.to.restorePurchases();
    isRestoring.value = false;
    if (result.ok) {
      AppAlert.success(result.message ?? 'Subscription restored.');
      Get.find<AuthController>().fetchMe();
    } else if (result.failed) {
      AppAlert.error(result.message ?? 'Could not restore purchases.');
    } else {
      AppAlert.info('No previous subscription found for this account.');
    }
  }

  final RxBool isRestoring = false.obs;
}

// ── Screen ────────────────────────────────────────────────────────────────────
class VipScreen extends StatelessWidget {
  const VipScreen({super.key});

  static const _cream = Color(0xFFF5D9A8);
  static const _darkBg = Color(0xFF1a1a1a);
  static const _cardBg = Color(0xFF232220);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VipController());
    final svc  = IAPService.to;

    return Scaffold(
      backgroundColor: _darkBg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: _darkBg,
            leading: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Get.back(),
            ),
            pinned: false,
            floating: true,
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Hero section ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Logo + title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: CustomImageView(
                              imagePath: 'assets/images/1024.png',
                              width: 40,
                              height: 40,

                              placeHolder: 'assets/images/novelux_placeholder_transcpr.jpg',
                              radius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'NoveluX VIP',
                            style: TextStyle(
                              color: _cream,
                              fontSize: 22,
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Headline
                      const Text(
                        'All novels.\nNo interruptions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _cream,
                          fontFamily: 'Georgia',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sub
                      const Text(
                        'Enjoy Ad-Free reading, offline, and exclusive rewards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB8A080),
                          fontFamily: 'Georgia',
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Social proof — price comes from the store so it always
                      // matches what the purchase sheet will charge
                      Obx(() {
                        final monthly = svc.vipPlans.firstWhereOrNull(
                          (p) => p.id == kSubMonthly,
                        );
                        final price = monthly?.price ?? '';
                        return Text(
                          price.isEmpty
                              ? '80% of readers choose the monthly plan · Cancel anytime'
                              : '80% of readers choose the monthly plan · $price/month · Cancel anytime',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8a7560),
                            fontFamily: 'Georgia',
                            fontSize: 13,
                          ),
                        );
                      }),
                      const SizedBox(height: 28),

                      // CTA — becomes the manage route once they're subscribed
                      Obx(() {
                        final isVip = svc.isVip.value;
                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cream,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            onPressed:
                                isVip
                                    ? ctrl.manageSubscription
                                    : () => ctrl.subscribe(kSubMonthly),
                            child: Text(
                              isVip ? 'Manage subscription' : 'Pay now',
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                color: Color(0xFF2a1a00),
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),

                      // Yearly upsell — pointless once they already pay us
                      Obx(
                        () =>
                            svc.isVip.value
                                ? const SizedBox.shrink()
                                : GestureDetector(
                                  onTap: () => ctrl.subscribe(kSubYearly),
                                  child: const Text(
                                    'Or save money with a yearly plan >',
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      color: Color(0xFFB8935A),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Subscription automatically renews at the end of each '
                        'cycle until cancelled. Cancel anytime in $_storeName.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          color: Color(0xFF5a4a38),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),

                // ── Feature list ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _feature(
                        Icons.menu_book_outlined,
                        'Ad-Free',
                        'Ad-Free so you can immerse in your favorite novels without interruption',
                      ),
                      const SizedBox(height: 20),
                      _feature(
                        Icons.download_outlined,
                        'Offline',
                        'Download novels to read later when you\'re offline or on the go',
                      ),
                      const SizedBox(height: 20),
                      _feature(
                        Icons.headphones_outlined,
                        'Audiobooks',
                        'Stream all the novels you want to hear, Ad-Free on the NoveluX app',
                      ),
                      const SizedBox(height: 20),
                      _feature(
                        Icons.verified_outlined,
                        'Exclusive badge',
                        'A special symbol reserved for VIP members',
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),

                // ── Start VIP ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start your VIP experience',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Plan cards from Play Store
                      Obx(
                        () => Column(
                          children:
                              svc.vipPlans
                                  .map((plan) => _planCard(ctrl, plan))
                                  .toList(),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'Subscription automatically renews at the end of each '
                        'cycle until cancelled. Cancel anytime in $_storeName.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF5a4a38),
                          fontSize: 11,
                          height: 1.5,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),

                // ── Keep reading ────────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Keep reading what you\nlove-uninterrupted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Georgia',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Mock reading UI card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E8C8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _filterTab('All', true),
                          _filterTab('Reading', false),
                          _filterTab('Unread', false),
                          _filterTab('Finished', false),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _mockBook(
                            'THE SON OF THE RICHEST',
                            const Color(0xFF1a3a6a),
                          ),
                          const SizedBox(width: 8),
                          _mockBook(
                            'HER BILLIONAIRE HUSBAND',
                            const Color(0xFF2a2a2a),
                          ),
                          const SizedBox(width: 8),
                          _mockBook(
                            'MISTAKEN MARRIAGE',
                            const Color(0xFF6a1a1a),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Unlimited Ad-Free ───────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Unlimited Ad-Free novels',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Immerse in more of your favorite novels without waiting for ads. Discover new genres, explore unique worlds, or meet unforgettable characters - all without any interruptions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8a7a68),
                          fontSize: 14,
                          height: 1.6,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Enjoy offline ───────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Enjoy novels offline',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Read anytime, anywhere - download novels and read them whenever, wherever, without the need for cell data or WiFi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8a7a68),
                          fontSize: 14,
                          height: 1.6,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // ── NoveluX branding ────────────────────────────────────────────
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomImageView(
                          imagePath: 'assets/images/1024.png',
                          width: 30,
                          height: 30,
                          radius: BorderRadius.circular(6),
                          placeHolder: 'assets/images/novelux_placeholder_transcpr.jpg',
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'NoveluX',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'An app made just for novels',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'With NoveluX VIP, you get uninterrupted access to our entire library of novels. Read from our library, Ad-Free — enjoy personalized recommendations, expertly curated reading lists for every genre and more, all without ads.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8a7a68),
                          fontSize: 14,
                          height: 1.6,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),

                // ── Pick a membership ──────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pick a membership that fits you',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Obx(
                    () => Column(
                      children:
                          svc.vipPlans
                              .map((plan) => _planCard(ctrl, plan))
                              .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'Subscription automatically renews at the end of each cycle '
                  'until cancelled. Cancel anytime in $_storeName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5a4a38),
                    fontSize: 11,
                    height: 1.5,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 8),

                // Restore — required by App Store guideline 3.1.1 so someone
                // reinstalling or on a new device isn't asked to pay twice.
                Obx(
                  () => TextButton(
                    onPressed: ctrl.isRestoring.value ? null : ctrl.restore,
                    child: Text(
                      ctrl.isRestoring.value
                          ? 'Restoring…'
                          : 'Restore purchases',
                      style: const TextStyle(
                        color: Color(0xFFB8935A),
                        fontSize: 13,
                        fontFamily: 'Georgia',
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFB8935A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Terms row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => AtomicWebViewScreen(
                            url: 'https://novelux.onrender.com/terms/',
                          ),
                        );
                      },
                      child: const Text(
                        'Terms of service',
                        style: TextStyle(
                          color: Color(0xFF8a7060),
                          fontSize: 13,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '|',
                        style: TextStyle(
                          color: Color(0xFF5a4a38),
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => AtomicWebViewScreen(
                            url: 'https://novelux.onrender.com/privacy/',
                          ),
                        );
                      },
                      child: const Text(
                        'Privacy policy',
                        style: TextStyle(
                          color: Color(0xFF8a7060),
                          fontFamily: 'Georgia',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Plan card ──────────────────────────────────────────────────────────────
  Widget _planCard(VipController ctrl, VipPlan plan) {
    final badge  = plan.badge;
    final planId = plan.id;

    return Obx(() {
      final svc = IAPService.to;
      final hasSub = svc.isVip.value;
      final isCurrent = hasSub && svc.activeSubId.value == planId;
      final isSelected = !isCurrent && ctrl.selectedPlanId.value == planId;

      return GestureDetector(
        onTap: () => ctrl.selectedPlanId.value = planId,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isSelected ? _cream : const Color(0xFF2a2620),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        color:
                            isSelected
                                ? const Color(0xFF2a1a00)
                                : const Color(0xFFB8935A),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.price,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: isSelected ? const Color(0xFF2a1a00) : _cream,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'per ${plan.period}  •  Auto-renews. Cancel anytime.',
                      style: const TextStyle(
                        color: Color(0xFF8a7060),
                        fontSize: 12,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCurrent
                                  ? const Color(0xFF3B7A57)
                                  : (isSelected
                                      ? const Color(0xFF2a2a2a)
                                      : _cream),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        // On the plan they already own this becomes the way
                        // out to the store's manager, not a second purchase.
                        onPressed:
                            isCurrent
                                ? ctrl.manageSubscription
                                : () => ctrl.subscribe(planId),
                        child: Text(
                          isCurrent
                              ? 'Manage subscription'
                              : (hasSub ? 'Switch to this plan' : 'Pay now'),
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            color:
                                isCurrent
                                    ? Colors.white
                                    : (isSelected
                                        ? Colors.white
                                        : const Color(0xFF2a1a00)),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // "Current plan" supersedes the marketing badge — telling an
              // existing subscriber a plan is "Most Popular" is noise.
              if (isCurrent)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B7A57),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Current plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ),
                )
              else if (badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _feature(IconData icon, String title, String desc) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2a2520),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _cream, size: 20),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: Color(0xFF8a7060),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _filterTab(String label, bool active) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: active ? Colors.orange : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? Colors.black : const Color(0xFF8a7060),
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFamily: 'Georgia',
      ),
    ),
  );

  Widget _mockBook(String title, Color color) => Expanded(
    child: Container(
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
