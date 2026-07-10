import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/iap_service.dart';
import 'package:novelux/screen/about/about_screen.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/auth/auth_screens.dart';
import 'package:novelux/screen/me/atomic_webview_screen.dart';
// import 'package:novelux/screen/auth/preferences_screen.dart';
import 'package:novelux/screen/reward_screen/reward_screen.dart';
import 'package:novelux/screen/author/author_dashboard_screen.dart';
import 'package:novelux/screen/author/preferences_screen.dart';
import 'package:novelux/screen/coins/coin_store_screen.dart';
import 'package:novelux/screen/download_screen/download_screen.dart';
import 'package:novelux/screen/library/library_screen.dart';
import 'package:novelux/screen/me/controller/me_controller.dart';
import 'package:novelux/screen/me/vip_screen.dart';
import 'package:novelux/screen/notification_screen/controller/notifcation_controller.dart';
import 'package:novelux/screen/notification_screen/notification_screen.dart';
import 'package:novelux/screen/me/ReadingScheduleScreen.dart';
import 'package:novelux/screen/editorial/ce_books_screen.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  String _planDisplayName(String? subId) {
    switch (subId) {
      case kSubWeekly:
        return 'Weekly';
      case kSubMonthly:
        return 'Monthly';
      case kSubQuarterly:
        return 'Quarterly';
      case kSubYearly:
        return 'Yearly';
      default:
        return 'VIP';
    }
  }

  int _planDurationDays(String? subId) {
    switch (subId) {
      case kSubWeekly:
        return 7;
      case kSubMonthly:
        return 30;
      case kSubQuarterly:
        return 90;
      case kSubYearly:
        return 365;
      default:
        return 30;
    }
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _vipPlanChip(String label, String subId) {
    final active = subId == IAPService.to.activeSubId.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            active
                ? Colors.orange.withOpacity(0.18)
                : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              active
                  ? Colors.orange.withOpacity(0.35)
                  : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.orangeAccent : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _vipPlanStat(String label, String value, IconData icon, Color tint) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: tint.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tint.withOpacity(0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tint, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: tint,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final ctrl = Get.put(MeController());
    final iap = Get.find<IAPService>();
    final theme = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
        final cardBg =
            isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
        final surfaceAlt =
            isDark ? const Color(0xFF17191D) : const Color(0xFFF7F8FC);
        final borderClr =
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06);
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;
        final accent = depperBlue;
        final vipAccent = const Color(0xFFB67C2A);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            bottom: false,
            child: Obx(() {
              final isLoggedIn = auth.isLoggedIn.value;
              final avatar = auth.avatar;

              return Column(
                children: [
                  // ── Profile header ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF17191D) : Colors.white,
                      border: Border(
                        bottom: BorderSide(color: borderClr, width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Gold laurel wreath behind avatar for VIP users
                            if (auth.isVip)
                              CustomPaint(
                                size: const Size(84, 84),
                                painter: _LaurelWreathPainter(),
                              ),
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: depperBlue,
                              child:
                                  (avatar != null && avatar.isNotEmpty)
                                      ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: _resolveAvatarUrl(avatar),
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorWidget:
                                              (_, __, ___) => Text(
                                                auth.username.isNotEmpty
                                                    ? auth.username[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                        ),
                                      )
                                      : Text(
                                        isLoggedIn && auth.username.isNotEmpty
                                            ? auth.username[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                            if (auth.isVip)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.diamond,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLoggedIn ? auth.username : 'Guest User',
                                style: TextStyle(
                                  color: txt,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isLoggedIn) ...[
                                const SizedBox(height: 2),
                                Text(
                                  auth.email,
                                  style: TextStyle(color: sub, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.monetization_on,
                                      color: Colors.orange,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${auth.coins} coins',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: depperBlue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Lv.${auth.readingLevel}',
                                        style: TextStyle(
                                          color: depperBlue,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!isLoggedIn)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: depperBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => Get.to(() => const LoginScreen()),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // the banner is too far up, it should be next up on the button nav bar,

                  // and as well the banner vertical height should not be the same as the image, the image should be stacked on top, while the banner should have height that's only sufficent to wrap the content,

                  // note the arrangement as it is is ok, just make that minor modifications.
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 90),
                      children: [
                        const SizedBox(height: 12),

                        // ── VIP Banner ──────────────────────────────────────────
                        if (auth.isVip)
                          GestureDetector(
                            onTap: () => Get.to(() => const VipScreen()),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    isDark
                                        ? const Color(0xFF1B2740)
                                        : const Color(0xFFEEF4FF),
                                    isDark
                                        ? const Color(0xFF131B2C)
                                        : const Color(0xFFF7F9FD),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderClr),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: vipAccent.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.diamond_outlined,
                                          color: vipAccent,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'VIP Active',
                                              style: TextStyle(
                                                color: txt,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              'You are enjoying ${_planDisplayName(iap.activeSubId.value)} access',
                                              style: TextStyle(
                                                color: sub,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.16),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(
                                              0.25,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.greenAccent,
                                              size: 13,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Active',
                                              style: TextStyle(
                                                color: Colors.greenAccent,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _vipPlanChip('Weekly', kSubWeekly),
                                      _vipPlanChip('Monthly', kSubMonthly),
                                      _vipPlanChip('Quarterly', kSubQuarterly),
                                      _vipPlanChip('Yearly', kSubYearly),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _vipPlanStat(
                                        'Plan',
                                        _planDisplayName(iap.activeSubId.value),
                                        Icons.card_membership,
                                        Colors.orangeAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      _vipPlanStat(
                                        'Starts',
                                        _formatDate(
                                          DateTime.now().subtract(
                                            Duration(
                                              days: _planDurationDays(
                                                iap.activeSubId.value,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Icons.calendar_today,
                                        Colors.amberAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      _vipPlanStat(
                                        'Ends',
                                        _formatDate(
                                          DateTime.now().add(
                                            Duration(
                                              days: _planDurationDays(
                                                iap.activeSubId.value,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Icons.event_available,
                                        Colors.lightBlueAccent,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Subscription automatically renews until cancelled.',
                                          style: TextStyle(
                                            color: sub,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: sub,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => Get.to(() => const VipScreen()),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    isDark
                                        ? const Color(0xFF1B2740)
                                        : const Color(0xFFEEF4FF),
                                    isDark
                                        ? const Color(0xFF131B2C)
                                        : const Color(0xFFF7F9FD),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                                border: Border.all(color: borderClr),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.diamond_outlined,
                                      color: accent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'VIP',
                                    style: TextStyle(
                                      color: txt,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3d2800),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Subscribe',
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          color: accent,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // VIP perks
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceAlt,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14),
                            ),
                            border: Border.all(color: borderClr),
                          ),
                          child: Row(
                            children: [
                              _vipPerk(
                                Icons.menu_book_outlined,
                                'Ad-Free',
                                accent,
                              ),
                              const SizedBox(width: 20),
                              _vipPerk(
                                Icons.download_outlined,
                                'Offline',
                                accent,
                              ),
                              const SizedBox(width: 20),
                              _vipPerk(
                                Icons.headphones_outlined,
                                'Audio',
                                accent,
                              ),
                            ],
                          ),
                        ),

                        // ── Rewards Center ────────────────────────────────────────
                        GestureDetector(
                          onTap: () => Get.to(() => const RewardsScreen()),
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderClr),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: Colors.orange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rewards Center',
                                        style: TextStyle(
                                          color: txt,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Earn coins daily • Unlock chapters free',
                                        style: TextStyle(
                                          color: sub,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Obx(
                                  () => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3d2800),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${auth.coins} 🪙',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: sub, size: 18),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderClr),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _item(
                            txt,
                            sub,
                            LucideIcons.coins500,
                            'Coin Store',
                            Colors.orange,
                            () {
                              Get.to(() => CoinStoreScreen());
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: divClr,
                        ),
                        const SizedBox(height: 12),

                        // ── Reading Preferences ───────────────────────────────────
                        if (isLoggedIn) ...[
                          _PreferencesCard(
                            cardBg: cardBg,
                            txt: txt,
                            sub: sub,
                            divClr: divClr,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Main menu ─────────────────────────────────────────────
                        _section(cardBg, [
                          _item(
                            txt,
                            sub,
                            Icons.timelapse_rounded,
                            'History',
                            Colors.lightBlueAccent,
                            () => Get.to(
                              () => const LibraryScreen(),
                              arguments: {'value': 1, 'isProfile': true},
                            ),
                          ),
                          _divider(divClr),
                          _item(
                            txt,
                            sub,
                            Icons.download_outlined,
                            'Downloads',
                            Colors.blue,
                            () => Get.to(() => const DownloadScreen()),
                          ),
                          _divider(divClr),
                          _item(
                            txt,
                            sub,
                            Icons.schedule_rounded,
                            'Reading Schedule',
                            Colors.teal,
                            () => Get.to(() => const ReadingScheduleScreen()),
                          ),
                        ]),
                        const SizedBox(height: 12),

                        // ── Display Mode ─────────────────────────────────────────
                        _section(cardBg, [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.dark_mode,
                                color: Colors.purple,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              'Display Mode',
                              style: TextStyle(color: txt, fontSize: 13),
                            ),
                            trailing: Obx(
                              () => DropdownButton<ThemeMode>(
                                value: theme.themeMode,
                                underline: const SizedBox.shrink(),
                                dropdownColor:
                                    isDark
                                        ? const Color(0xFF2a2a2a)
                                        : Colors.white,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: sub,
                                  size: 18,
                                ),
                                items: [
                                  _themeItem(
                                    ThemeMode.system,
                                    'System',
                                    Icons.settings_suggest,
                                    txt,
                                  ),
                                  _themeItem(
                                    ThemeMode.dark,
                                    'Dark',
                                    Icons.dark_mode,
                                    txt,
                                  ),
                                  _themeItem(
                                    ThemeMode.light,
                                    'Light',
                                    Icons.light_mode,
                                    txt,
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) theme.setThemeMode(v);
                                },
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),

                        // ── Notifications ─────────────────────────────────────────
                        _section(cardBg, [
                          Obx(
                            () => _item(
                              txt,
                              sub,
                              Icons.notifications_outlined,
                              'Notifications',
                              Colors.orange,
                              () {
                                Get.put(NotificationController());
                                Get.to(() => const NotificationScreen());
                              },
                              badge:
                                  ctrl.unreadCount.value > 0
                                      ? '${ctrl.unreadCount.value}'
                                      : null,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),

                        // ── Author / CE / About ───────────────────────────────────
                        _section(cardBg, [
                          if (isLoggedIn && auth.role == 'ce')
                            _item(
                              txt,
                              sub,
                              Icons.menu_book_outlined,
                              'Manage Stories',
                              Colors.indigo,
                              () => Get.to(() => const CeBooksScreen()),
                            ),
                          if (isLoggedIn && auth.isAuthor)
                            _item(
                              txt,
                              sub,
                              Icons.dashboard_outlined,
                              'Author Dashboard',
                              Colors.teal,
                              () => Get.to(() => const AuthorDashboardScreen()),
                            )
                          else if (isLoggedIn &&
                              auth.role != 'ce' &&
                              !auth.isAuthor)
                            _item(
                              txt,
                              sub,
                              Icons.edit_outlined,
                              'Become an Author',
                              Colors.lightBlue,
                              () => _becomeAuthorDialog(ctrl),
                            )
                          else if (!isLoggedIn)
                            _item(
                              txt,
                              sub,
                              Icons.login,
                              'Sign In to Write',
                              Colors.lightBlue,
                              () => Get.to(() => const LoginScreen()),
                            ),
                          _divider(divClr),
                          _item(
                            txt,
                            sub,
                            Icons.info_outline,
                            'About NoveluX',
                            Colors.amber,
                            () => Get.to(() => AboutScreen()),
                          ),
                          _divider(divClr),
                          _item(
                            txt,
                            sub,
                            Icons.help_outline,
                            'Help & Feedback',
                            Colors.orange,
                            () {
                              Get.to(
                                () => AtomicWebViewScreen(
                                  url: 'https://novelux.onrender.com/faq/',
                                ),
                              );
                            },
                          ),
                          if (isLoggedIn) ...[
                            _divider(divClr),
                            _item(
                              txt,
                              sub,
                              Icons.logout,
                              'Sign Out',
                              Colors.red,
                              () => _signOutDialog(auth),
                            ),
                          ],
                          if (!isLoggedIn) ...[
                            _divider(divClr),
                            _item(
                              txt,
                              sub,
                              Icons.person_add_outlined,
                              'Create Account',
                              Colors.green,
                              () => Get.to(() => const RegisterScreen()),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  DropdownMenuItem<ThemeMode> _themeItem(
    ThemeMode mode,
    String label,
    IconData icon,
    Color txt,
  ) => DropdownMenuItem(
    value: mode,
    child: Row(
      children: [
        Icon(icon, size: 14, color: txt),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: txt, fontSize: 12)),
      ],
    ),
  );

  Widget _vipPerk(IconData icon, String label, Color tint) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: tint, size: 14),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _section(Color bg, List<Widget> items) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.black.withOpacity(0.04)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(children: items),
  );

  Widget _divider(Color color) =>
      Divider(height: 1, indent: 54, endIndent: 16, color: color);

  Widget _item(
    Color txt,
    Color sub,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    String? badge,
  }) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
    title: Text(label, style: TextStyle(color: txt, fontSize: 13)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        const SizedBox(width: 4),
        Icon(Icons.arrow_forward_ios, color: sub, size: 12),
      ],
    ),
    onTap: onTap,
  );

  void _becomeAuthorDialog(MeController ctrl) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Become an Author',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Start publishing stories and earn coins!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: depperBlue),
            onPressed: () {
              // Get.back();
              Navigator.pop(Get.context!);
              //ctrl.becomeAuthor();
              Get.to(
                () => AtomicWebViewScreen(
                  url: 'https://novelux.onrender.com/become-author/',
                ),
              );
            },
            child: const Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _signOutDialog(AuthController auth) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              auth.logout();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveAvatarUrl(String url) {
    if (!url.startsWith('http')) return 'http://10.0.2.2:8000$url';
    // Google photo URLs: swap any =sXX-c suffix for a reliable size
    if (url.contains('googleusercontent.com')) {
      return url.replaceAll(RegExp(r'=s\d+-c$'), '=s200-c');
    }
    return url;
  }
}

// ── Reading Preferences card ──────────────────────────────────────────────────
class _PreferencesCard extends StatefulWidget {
  final Color cardBg, txt, sub, divClr;
  const _PreferencesCard({
    required this.cardBg,
    required this.txt,
    required this.sub,
    required this.divClr,
  });

  @override
  State<_PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<_PreferencesCard> {
  List<String> _genres = [];
  String _gender = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getUserPreferences();
    if (res['success']) {
      final data = res['data'];
      setState(() {
        _genres = List<String>.from(data['preferred_genres'] ?? []);
        _gender = data['gender']?.toString() ?? '';
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  String _slugToLabel(String slug) {
    final found = kAllCategories.where((c) => c['slug'] == slug).firstOrNull;
    if (found != null) return '${found['emoji']} ${found['label']}';
    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite_outline,
                    color: Colors.pink,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reading Preferences',
                  style: TextStyle(
                    color: widget.txt,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap:
                      () => Get.to(
                        () => const PreferencesScreen(isOnboarding: false),
                      )?.then((_) => _load()),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: depperBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange,
                  ),
                ),
              ),
            )
          else if (_genres.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No preferences set yet. Tap Edit to add some.',
                style: TextStyle(color: widget.sub, fontSize: 12),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children:
                        _genres
                            .map(
                              (slug) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: depperBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: depperBlue.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _slugToLabel(slug),
                                  style: TextStyle(
                                    color: depperBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  if (_gender.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Gender: ${_gender.replaceAll('_', ' ')}',
                      style: TextStyle(color: widget.sub, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LaurelWreathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFD4A017)
          ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;

    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * math.pi;
      final lx = cx + r * math.cos(angle);
      final ly = cy + r * math.sin(angle);
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(angle + math.pi / 2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 10, height: 5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
