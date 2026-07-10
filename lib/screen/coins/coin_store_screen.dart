// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:novelux/config/api_service.dart';
// import 'package:novelux/config/app_style.dart';
// import 'package:novelux/screen/auth/auth_controller.dart';
// import 'package:url_launcher/url_launcher.dart';

// class CoinStoreController extends GetxController {
//   final RxBool isLoading      = false.obs;
//   final RxBool isLoadingPlans = false.obs;
//   final RxList coinPackages   = [].obs;
//   final RxList subPlans       = [].obs;
//   final RxInt  coinBalance    = 0.obs;
//   final RxBool isVip          = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchAll();
//   }

//   Future<void> fetchAll() async {
//     isLoading.value = true;
//     final results = await Future.wait([
//       ApiService.getCoinPackages(),
//       ApiService.getSubscriptionPlans(),
//       ApiService.getCoinBalance(),
//     ]);
//     isLoading.value = false;

//     if (results[0]['success']) {
//       final d = results[0]['data'];
//       coinPackages.value = d is List ? d : [];
//     }
//     if (results[1]['success']) {
//       final d = results[1]['data'];
//       subPlans.value = d is List ? d : [];
//     }
//     if (results[2]['success']) {
//       coinBalance.value = results[2]['data']['coin_balance'] ?? 0;
//       isVip.value       = results[2]['data']['is_vip'] ?? false;
//     }
//   }

//   Future<void> purchaseCoinPack(String packageId) async {
//     final res = await ApiService.createCheckout('coin_pack', packageId: packageId);
//     if (res['success']) {
//       final url = res['data']['checkout_url'];
//       if (url != null) await launchUrl(Uri.parse(url));
//     } else {
//       Get.snackbar('Error', res['error'] ?? 'Purchase failed',
//           backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }

//   Future<void> purchaseSubscription(String planId) async {
//     final res = await ApiService.createCheckout('subscription', planId: planId);
//     if (res['success']) {
//       final url = res['data']['checkout_url'];
//       if (url != null) await launchUrl(Uri.parse(url));
//     } else {
//       Get.snackbar('Error', res['error'] ?? 'Purchase failed',
//           backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }
// }

// class CoinStoreScreen extends StatelessWidget {
//   const CoinStoreScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.put(CoinStoreController());
//     final auth = Get.find<AuthController>();

//     return Scaffold(
//       backgroundColor: const Color(0xFF1a1a1a),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1a1a1a),
//         leading: IconButton(
//           icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
//           onPressed: () => Get.back(),
//         ),
//         title: const Text('Coin Store',
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: Obx(() {
//         if (ctrl.isLoading.value) {
//           return const Center(child: CircularProgressIndicator(color: Colors.blue));
//         }
//         return SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             // ── Balance Card ────────────────────────────────────────────────
//             Container(
//               width: double.infinity,
//               margin: const EdgeInsets.symmetric(vertical: 16),
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [depperBlue, const Color(0xFF0050a0)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Row(children: [
//                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                   const Text('My Balance',
//                       style: TextStyle(color: Colors.white70, fontSize: 13)),
//                   const SizedBox(height: 4),
//                   Obx(() => Row(children: [
//                     const Icon(Icons.monetization_on, color: Colors.orange, size: 22),
//                     const SizedBox(width: 6),
//                     Text('${ctrl.coinBalance.value}',
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold)),
//                     const SizedBox(width: 6),
//                     const Text('coins',
//                         style: TextStyle(color: Colors.white70, fontSize: 14)),
//                   ])),
//                 ]),
//                 const Spacer(),
//                 Obx(() => ctrl.isVip.value
//                     ? Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: Colors.amber,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Row(mainAxisSize: MainAxisSize.min, children: [
//                           Icon(Icons.diamond, color: Colors.white, size: 14),
//                           SizedBox(width: 4),
//                           Text('VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                         ]),
//                       )
//                     : const SizedBox.shrink()),
//               ]),
//             ),

//             // ── VIP Plans ───────────────────────────────────────────────────
//             const Text('VIP Subscription',
//                 style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 4),
//             const Text('Get daily coins + exclusive perks',
//                 style: TextStyle(color: Colors.grey, fontSize: 12)),
//             const SizedBox(height: 12),
//             ...ctrl.subPlans.map((plan) => _VipPlanCard(
//                   plan: plan,
//                   onTap: () => ctrl.purchaseSubscription(plan['plan_id']),
//                 )),
//             const SizedBox(height: 24),

//             // ── Coin Packages ───────────────────────────────────────────────
//             const Text('Buy Coins',
//                 style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 4),
//             const Text('Use coins to unlock chapters',
//                 style: TextStyle(color: Colors.grey, fontSize: 12)),
//             const SizedBox(height: 12),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//                 childAspectRatio: 1.4,
//               ),
//               itemCount: ctrl.coinPackages.length,
//               itemBuilder: (_, i) => _CoinPackCard(
//                 package: ctrl.coinPackages[i],
//                 onTap: () => ctrl.purchaseCoinPack(ctrl.coinPackages[i]['package_id']),
//               ),
//             ),
//             const SizedBox(height: 32),

//             // ── How coins work ──────────────────────────────────────────────
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF2a2a2a),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 const Text('How coins work',
//                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
//                 const SizedBox(height: 12),
//                 _coinRule(Icons.lock_open, 'Unlock premium chapters', 'Spend coins to read locked chapters'),
//                 _coinRule(Icons.monetization_on, 'Tip authors', 'Show your appreciation with coin tips'),
//                 _coinRule(Icons.diamond, 'VIP subscription', 'Get daily coins & exclusive content'),
//                 _coinRule(Icons.refresh, 'Free daily chapter', '1 free chapter per story per day'),
//               ]),
//             ),
//             const SizedBox(height: 80),
//           ]),
//         );
//       }),
//     );
//   }

//   Widget _coinRule(IconData icon, String title, String subtitle) => Padding(
//     padding: const EdgeInsets.only(bottom: 10),
//     child: Row(children: [
//       Container(
//         width: 36, height: 36,
//         decoration: BoxDecoration(
//           color: depperBlue.withOpacity(0.15),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(icon, color: depperBlue, size: 18),
//       ),
//       const SizedBox(width: 12),
//       Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
//         Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
//       ])),
//     ]),
//   );
// }

// class _CoinPackCard extends StatelessWidget {
//   final Map package;
//   final VoidCallback onTap;
//   const _CoinPackCard({required this.package, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final bonus = package['bonus_coins'] ?? 0;
//     final total = package['total_coins'] ?? package['coins'];
//     final price = package['price_usd'];
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: const Color(0xFF2a2a2a),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFF3a3a3a)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(children: [
//               const Icon(Icons.monetization_on, color: Colors.orange, size: 20),
//               const SizedBox(width: 6),
//               Text('$total',
//                   style: const TextStyle(
//                       color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
//             ]),
//             if (bonus > 0)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text('+$bonus bonus!',
//                     style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
//               ),
//             Text('\$$price',
//                 style: const TextStyle(
//                     color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _VipPlanCard extends StatelessWidget {
//   final Map plan;
//   final VoidCallback onTap;
//   const _VipPlanCard({required this.plan, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final isYearly   = plan['plan_id']?.contains('yearly') ?? false;
//     final discount   = plan['discount_pct'] ?? 0;
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           gradient: isYearly
//               ? const LinearGradient(colors: [Color(0xFF6B21A8), Color(0xFF3B0764)])
//               : null,
//           color: isYearly ? null : const Color(0xFF2a2a2a),
//           borderRadius: BorderRadius.circular(12),
//           border: isYearly
//               ? null
//               : Border.all(color: const Color(0xFF3a3a3a)),
//         ),
//         child: Row(children: [
//           Icon(Icons.diamond,
//               color: isYearly ? Colors.amber : Colors.grey, size: 28),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text(plan['label'] ?? '',
//                   style: const TextStyle(
//                       color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
//               Text('${plan['coins_per_month']} coins/month',
//                   style: const TextStyle(color: Colors.white70, fontSize: 12)),
//               if (discount > 0)
//                 Text('Save $discount%!',
//                     style: const TextStyle(color: Colors.green, fontSize: 11)),
//             ]),
//           ),
//           Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//             Text('\$${plan['price_usd']}',
//                 style: const TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
//             Text(isYearly ? '/year' : '/month',
//                 style: const TextStyle(color: Colors.white70, fontSize: 11)),
//           ]),
//         ]),
//       ),
//     );
//   }
// }


// File: lib/screen/coins/coin_store_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/iap_service.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/me/vip_screen.dart';

class CoinStoreScreen extends StatelessWidget {
  const CoinStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc  = IAPService.to;
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0d10),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text('Coin Store',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Live coin balance in app bar
          Obx(() => Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Colors.orange, size: 15),
                const SizedBox(width: 5),
                Text('${auth.coins}',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
            ),
          )),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          // Header banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2d1a00),
                  Colors.orange.withOpacity(0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Text('🪙', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buy Coins',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Use coins to unlock chapters and send gifts.',
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 12)),
                ],
              )),
            ]),
          ),

          // Coin packs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => Column(
              children: svc.coinPacks.map((pack) => Obx(() => _CoinPackCard(
                pack:         pack,
                isPurchasing: svc.isPurchasing.value,
                onBuy: () => _buy(context, pack.id),
              ))).toList(),
            )),
          ),

          const SizedBox(height: 24),

          // VIP upsell
          _VipUpsellBanner(),

          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Future<void> _buy(BuildContext ctx, String productId) async {
    final svc    = IAPService.to;
    final result = await svc.buyCoins(productId);

    if (!ctx.mounted) return;

    if (result.status == PurchaseStatus2.success) {
      AppAlert.success('🎉 Coins added! — +${result.coinsGranted} coins deposited to your wallet.');
      Get.find<AuthController>().refreshCoins();
    } else if (result.status == PurchaseStatus2.error) {
      AppAlert.error('Purchase failed — ${result.message ?? 'Please try again.'}');
    }
    // isCancelled — silent
  }
}

// ── Coin pack card ────────────────────────────────────────────────────────────
class _CoinPackCard extends StatelessWidget {
  final CoinPack     pack;
  final bool         isPurchasing;
  final VoidCallback onBuy;

  const _CoinPackCard({
    required this.pack,
    required this.isPurchasing,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: pack.isPopular
            ? depperBlue.withOpacity(0.08)
            : const Color(0xFF18181c),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pack.isPopular
              ? depperBlue.withOpacity(0.4)
              : Colors.grey.withOpacity(0.15),
          width: pack.isPopular ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('🪙', style: TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 14),

        // Labels
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(pack.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              if (pack.isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: depperBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Popular',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
            if (pack.bonus != null)
              Text(pack.bonus!,
                  style: const TextStyle(
                      color: Colors.orange, fontSize: 12)),
          ],
        )),

        // Price + buy button
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(pack.price,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isPurchasing ? null : onBuy,
              child: isPurchasing
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Buy',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── VIP upsell banner ─────────────────────────────────────────────────────────
class _VipUpsellBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (IAPService.to.isVip.value) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () => Get.to(() => const VipScreen()),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF1a0800),
              Color(0xFF3d1200),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: depperBlue.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Text('👑', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Go VIP — Unlimited Reading',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Stop buying coins for locked chapters.',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 12)),
              ],
            )),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20),
          ]),
        ),
      );
    });
  }
}

// Avoid import error — VipScreen is defined in vip_screen_iap.dart
// Add this import at the top of your file:
// import 'package:novelux/screen/me/vip_screen.dart';