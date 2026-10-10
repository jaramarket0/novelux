import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
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
import 'package:novelux/widgets/plan_badge.dart';
import 'package:novelux/core/constants/app_constants.dart';
import 'package:novelux/widgets/app_glass.dart';

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

  String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${_formatDate(date)}, $hour:$minute $period';
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
        final p = _MePalette.of(context);

        return Scaffold(
          backgroundColor: p.bg,
          body: SafeArea(
            bottom: false,
            child: Obx(() {
              final isLoggedIn = auth.isLoggedIn.value;

              return ListView(
                // Clears the floating bottom nav bar
                padding: EdgeInsets.only(
                  bottom: 100 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  // ── Page header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Row(
                      children: [
                        // Brand mark: the "H" on Android, the rust "N" on iOS
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            AppConstants.logoAsset,
                            width: 36,
                            height: 36,
                            cacheWidth: 108,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: p.accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Profile, membership, coins ─────────────────────
                        _identity(auth, iap, p, isLoggedIn),
                        const SizedBox(height: 20),
                        _vipCard(auth, iap, p),
                        const SizedBox(height: 20),
                        _card(p, [
                          _rewardsRow(auth, p),
                          _row(
                            p,
                            LucideIcons.wallet,
                            'Coin Store',
                            () => Get.to(() => CoinStoreScreen()),
                            iconColor: p.accent,
                            iconBox: true,
                          ),
                        ]),

                        // ── Your reading ───────────────────────────────────
                        const SizedBox(height: 28),
                        _heading('Your reading', p),
                        if (isLoggedIn) ...[
                          _PreferencesCard(palette: p),
                          const SizedBox(height: 12),
                        ],
                        _card(p, [
                          _row(
                            p,
                            LucideIcons.history,
                            'History',
                            () => Get.to(
                              () => const LibraryScreen(),
                              arguments: {'value': 1, 'isProfile': true},
                            ),
                          ),
                          _row(
                            p,
                            LucideIcons.download,
                            'Downloads',
                            () => Get.to(() => const DownloadScreen()),
                          ),
                          _row(
                            p,
                            LucideIcons.clock3,
                            'Reading Schedule',
                            () => Get.to(() => const ReadingScheduleScreen()),
                          ),
                        ]),

                        // ── App settings ───────────────────────────────────
                        const SizedBox(height: 28),
                        _heading('App settings', p),
                        _card(p, [
                          _displayModeRow(theme, p),
                          Obx(
                            () => _row(
                              p,
                              LucideIcons.bell,
                              'Notifications',
                              () {
                                Get.put(NotificationController());
                                Get.to(() => const NotificationScreen());
                              },
                              count: ctrl.unreadCount.value,
                            ),
                          ),
                        ]),

                        // ── Community & support ────────────────────────────
                        const SizedBox(height: 24),
                        _heading('Community & support', p),
                        _card(p, [
                          if (isLoggedIn && auth.role == 'ce')
                            _row(
                              p,
                              LucideIcons.bookMarked,
                              'Manage Stories',
                              () => Get.to(() => const CeBooksScreen()),
                            ),
                          if (isLoggedIn && auth.isAuthor)
                            _row(
                              p,
                              LucideIcons.layoutDashboard,
                              'Author Dashboard',
                              () => Get.to(() => const AuthorDashboardScreen()),
                            )
                          else if (isLoggedIn && auth.role != 'ce')
                            _row(
                              p,
                              LucideIcons.penLine,
                              'Become an Author',
                              () => _becomeAuthorDialog(ctrl),
                            )
                          else if (!isLoggedIn)
                            _row(
                              p,
                              LucideIcons.penLine,
                              'Sign In to Write',
                              () => Get.to(() => const LoginScreen()),
                            ),
                          _row(
                            p,
                            LucideIcons.info,
                            'About ${AppConstants.appName}',
                            () => Get.to(() => AboutScreen()),
                          ),
                          _row(
                            p,
                            LucideIcons.circleHelp,
                            'Help & Feedback',
                            () => Get.to(
                              () => AtomicWebViewScreen(
                                url: 'https://novelux.onrender.com/faq/',
                              ),
                            ),
                          ),
                          if (isLoggedIn) ...[
                            Obx(
                              () => _row(
                                p,
                                LucideIcons.shieldCheck,
                                'Content & Parental Controls',
                                () => _parentalControlsDialog(auth),
                                tag:
                                    auth.currentUser.value?['restricted_mode_enabled'] ==
                                            true
                                        ? 'ON'
                                        : null,
                              ),
                            ),
                          ],
                        ]),

                        // ── Account ────────────────────────────────────────
                        const SizedBox(height: 24),
                        _heading('Account', p),
                        _card(p, [
                          if (isLoggedIn) ...[
                            _row(
                              p,
                              LucideIcons.logOut,
                              'Sign Out',
                              () => _signOutDialog(auth),
                            ),
                            _row(
                              p,
                              LucideIcons.trash2,
                              'Delete Account',
                              () => _deleteAccountDialog(auth),
                              destructive: true,
                            ),
                          ] else ...[
                            _row(
                              p,
                              LucideIcons.logIn,
                              'Sign In',
                              () => Get.to(() => const LoginScreen()),
                            ),
                            _row(
                              p,
                              LucideIcons.userPlus,
                              'Create Account',
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

  // ── Identity: avatar, name, email, coins, level ─────────────────────────────
  Widget _identity(
    AuthController auth,
    IAPService iap,
    _MePalette p,
    bool isLoggedIn,
  ) {
    final avatar = auth.avatar;
    final planSubId = iap.isVip.value ? iap.activeSubId.value : '';
    final initial =
        isLoggedIn && auth.username.isNotEmpty
            ? auth.username[0].toUpperCase()
            : '?';
    final initialText = Text(
      initial,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
    );

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Gold laurel wreath behind the avatar for VIP readers
            if (auth.isVip)
              CustomPaint(
                size: const Size(80, 80),
                painter: _LaurelWreathPainter(),
              ),
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.primary,
                shape: BoxShape.circle,
              ),
              child:
                  (avatar != null && avatar.isNotEmpty)
                      ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: _resolveAvatarUrl(avatar),
                          width: 60,
                          height: 60,
                          memCacheWidth: 180,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => initialText,
                        ),
                      )
                      : initialText,
            ),
            if (auth.isVip)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: planBadgeFor(planSubId).color,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.bg, width: 2),
                  ),
                  child: Icon(
                    planBadgeFor(planSubId).icon,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoggedIn ? auth.username : 'Guest User',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.title,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              if (isLoggedIn) ...[
                Text(
                  auth.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.secondary, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(LucideIcons.circleDollarSign, color: p.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${auth.coins} coins',
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: p.chip,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lv.${auth.readingLevel}',
                        style: TextStyle(
                          color: p.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'Sign in to sync your library and coins',
                  style: TextStyle(color: p.secondary, fontSize: 12),
                ),
            ],
          ),
        ),
        if (!isLoggedIn)
          _pillButton(p, 'Sign In', () => Get.to(() => const LoginScreen())),
      ],
    );
  }

  // ── VIP membership card ─────────────────────────────────────────────────────
  Widget _vipCard(AuthController auth, IAPService iap, _MePalette p) {
    // A plan only applies while the store reports that subscription active.
    // VIP redeemed with coins has no plan, so it shows as plain VIP with the
    // backend's real expiry.
    final planSubId = iap.isVip.value ? iap.activeSubId.value : '';
    final hasPlan = planSubId.isNotEmpty;
    final vipEnds = DateTime.tryParse(auth.vipExpires ?? '')?.toLocal();
    final isVip = auth.isVip;

    return GestureDetector(
      onTap: () => Get.to(() => const VipScreen()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.vipBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.vipBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.gem, color: p.gold, size: 20),
                          const SizedBox(width: 7),
                          Text(
                            isVip ? 'VIP Active' : 'VIP',
                            style: TextStyle(
                              color: p.title,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isVip
                            ? 'You are enjoying ${_planDisplayName(planSubId)} access'
                            : 'More stories. No interruptions.',
                        style: TextStyle(color: p.secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                if (isVip)
                  Icon(LucideIcons.chevronRight, color: p.secondary, size: 16)
                else
                  _pillButton(
                    p,
                    'Subscribe',
                    () => Get.to(() => const VipScreen()),
                    chevron: true,
                  ),
              ],
            ),
            if (isVip) ...[
              if (hasPlan) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _vipPlanChip(p, 'Weekly', kSubWeekly),
                    _vipPlanChip(p, 'Monthly', kSubMonthly),
                    _vipPlanChip(p, 'Quarterly', kSubQuarterly),
                    _vipPlanChip(p, 'Yearly', kSubYearly),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _vipPlanStat(
                    p,
                    'Plan',
                    hasPlan ? _planDisplayName(planSubId) : 'Coin VIP',
                  ),
                  if (hasPlan) ...[
                    const SizedBox(width: 8),
                    _vipPlanStat(
                      p,
                      'Starts',
                      _formatDate(
                        (vipEnds ?? DateTime.now()).subtract(
                          Duration(days: _planDurationDays(planSubId)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _vipPlanStat(
                    p,
                    'Ends',
                    vipEnds == null
                        ? '—'
                        : hasPlan
                        ? _formatDate(vipEnds)
                        : _formatDateTime(vipEnds),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hasPlan
                    ? 'Subscription automatically renews until cancelled.'
                    : 'Redeemed with coins. Does not renew.',
                style: TextStyle(color: p.muted, fontSize: 11),
              ),
            ] else ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _vipPerk(p, LucideIcons.bookOpen, 'Ad-Free'),
                  _vipPerk(p, LucideIcons.download, 'Offline'),
                  _vipPerk(p, LucideIcons.headphones, 'Audio'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vipPlanChip(_MePalette p, String label, String subId) {
    final active = subId == IAPService.to.activeSubId.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? p.primary : p.chip,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: active ? p.primary : p.chipBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : p.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _vipPlanStat(_MePalette p, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: p.title,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _vipPerk(_MePalette p, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: p.gold, size: 15),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: p.secondary, fontSize: 12)),
    ],
  );

  // ── Rewards Center row ──────────────────────────────────────────────────────
  Widget _rewardsRow(AuthController auth, _MePalette p) => InkWell(
    onTap: () => Get.to(() => const RewardsScreen()),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 42,
            decoration: BoxDecoration(
              color: p.emblem,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.gift, color: p.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rewards Center',
                  style: TextStyle(
                    color: p.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Earn coins daily · Unlock chapters free',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.secondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${auth.coins}',
            style: TextStyle(
              color: p.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(LucideIcons.circleDollarSign, color: p.accent, size: 14),
          const SizedBox(width: 12),
          Icon(LucideIcons.chevronRight, color: p.secondary, size: 16),
        ],
      ),
    ),
  );

  // ── Display mode (System / Dark / Light) ────────────────────────────────────
  Widget _displayModeRow(ThemeController theme, _MePalette p) {
    const labels = {
      ThemeMode.system: 'System',
      ThemeMode.dark: 'Dark',
      ThemeMode.light: 'Light',
    };
    return Obx(
      () => PopupMenuButton<ThemeMode>(
        initialValue: theme.themeMode,
        color: p.card,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: theme.setThemeMode,
        itemBuilder:
            (_) => [
              for (final e in labels.entries)
                PopupMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: p.title,
                      fontSize: 14,
                      fontWeight:
                          e.key == theme.themeMode
                              ? FontWeight.w600
                              : FontWeight.w400,
                    ),
                  ),
                ),
            ],
        child: _rowBody(
          p,
          LucideIcons.moon,
          'Display Mode',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels[theme.themeMode] ?? 'System',
                style: TextStyle(color: p.secondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Icon(LucideIcons.chevronDown, color: p.secondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Building blocks ─────────────────────────────────────────────────────────
  Widget _heading(String text, _MePalette p) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        color: p.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// A rounded group of rows, with inset dividers between them.
  Widget _card(_MePalette p, List<Widget> rows) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: p.card,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) _divider(p),
            row,
          ],
        ],
      ),
    ),
  );

  Widget _divider(_MePalette p) => Padding(
    padding: const EdgeInsets.only(left: 54, right: 16),
    child: Container(height: 1, color: p.divider),
  );

  Widget _pillButton(
    _MePalette p,
    String label,
    VoidCallback onTap, {
    bool chevron = false,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: p.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (chevron) ...[
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, color: Colors.white, size: 14),
          ],
        ],
      ),
    ),
  );

  /// A settings row: icon, label, optional count / tag, chevron.
  Widget _row(
    _MePalette p,
    IconData icon,
    String label,
    VoidCallback onTap, {
    int count = 0,
    String? tag,
    bool destructive = false,
    Color? iconColor,
    bool iconBox = false,
  }) => InkWell(
    onTap: onTap,
    child: _rowBody(
      p,
      icon,
      label,
      destructive: destructive,
      iconColor: iconColor,
      iconBox: iconBox,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 23),
              height: 23,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.emblem,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: p.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (count > 0 || tag != null) const SizedBox(width: 12),
          Icon(LucideIcons.chevronRight, color: p.secondary, size: 16),
        ],
      ),
    ),
  );

  Widget _rowBody(
    _MePalette p,
    IconData icon,
    String label, {
    required Widget trailing,
    bool destructive = false,
    Color? iconColor,
    bool iconBox = false,
  }) {
    final fg = destructive ? p.danger : p.title;
    final ic = destructive ? p.danger : (iconColor ?? p.secondary);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: iconBox ? 13 : 16),
      child: Row(
        children: [
          // Coin Store's icon sits in a 38px slot to line up with the
          // Rewards emblem above it; plain rows use a 20px icon.
          SizedBox(
            width: iconBox ? 38 : 20,
            height: iconBox ? 38 : 20,
            child: Icon(icon, color: ic, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  void _becomeAuthorDialog(MeController ctrl) {
    Get.dialog(
      GlassAlertDialog(
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
      GlassAlertDialog(
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

  void _deleteAccountDialog(AuthController auth) {
    final passwordCtrl = TextEditingController();
    // Social-login (Google) accounts have no password — they confirm by
    // typing DELETE instead, and the backend skips the password check.
    final needsPassword = auth.hasPassword;
    bool obscure = true;
    bool loading = false;
    String? error;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final input = passwordCtrl.text.trim();
            if (needsPassword && input.isEmpty) {
              setState(() => error = 'Please enter your password.');
              return;
            }
            if (!needsPassword && input != 'DELETE') {
              setState(() => error = 'Type DELETE in capitals to confirm.');
              return;
            }
            setState(() {
              loading = true;
              error = null;
            });
            final res = await ApiService.deleteAccount(
              needsPassword ? input : '',
            );
            if (res['success'] == true) {
              Get.back();
              AppAlert.success('Your account has been deleted.');
              await auth.logout();
            } else {
              setState(() {
                loading = false;
                error =
                    res['error']?.toString() ?? 'Could not delete account.';
              });
            }
          }

          return GlassAlertDialog(
            backgroundColor: const Color(0xFF2a2a2a),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This permanently deletes your account and personal data. '
                  'This cannot be undone. '
                  '${needsPassword ? 'Enter your password to confirm.' : 'Type DELETE to confirm.'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: needsPassword && obscure,
                  enabled: !loading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: needsPassword ? 'Password' : 'DELETE',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    suffixIcon:
                        needsPassword
                            ? IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed:
                                  () => setState(() => obscure = !obscure),
                            )
                            : null,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Get.back(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: loading ? null : submit,
                child:
                    loading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  void _parentalControlsDialog(AuthController auth) {
    final isEnabled = auth.currentUser.value?['restricted_mode_enabled'] == true;
    final pinCtrl = TextEditingController();
    final pinConfirmCtrl = TextEditingController();
    bool loading = false;
    String? error;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final pin = pinCtrl.text.trim();
            if (pin.length < 4 || pin.length > 6 || int.tryParse(pin) == null) {
              setState(() => error = 'PIN must be 4–6 digits.');
              return;
            }
            if (!isEnabled && pin != pinConfirmCtrl.text.trim()) {
              setState(() => error = 'PINs do not match.');
              return;
            }
            setState(() {
              loading = true;
              error = null;
            });
            final res = await ApiService.setRestrictedMode(
              enable: !isEnabled,
              pin: pin,
            );
            if (res['success'] == true) {
              final user = Map<String, dynamic>.from(
                auth.currentUser.value ?? {},
              );
              user['restricted_mode_enabled'] = !isEnabled;
              auth.currentUser.value = user;
              Get.back();
              AppAlert.success(
                !isEnabled
                    ? 'Restricted mode turned on — 18+ content is now hidden.'
                    : 'Restricted mode turned off.',
              );
            } else {
              setState(() {
                loading = false;
                error = res['error']?.toString() ?? 'Something went wrong.';
              });
            }
          }

          return GlassAlertDialog(
            backgroundColor: const Color(0xFF2a2a2a),
            title: Text(
              isEnabled ? 'Turn Off Restricted Mode' : 'Turn On Restricted Mode',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnabled
                      ? 'Enter your PIN to turn off content restrictions and see 18+ stories again.'
                      : 'Set a PIN to hide 18+/explicit stories on this account. '
                          'Anyone using this device will need the PIN to turn it back off.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !loading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: isEnabled ? 'Enter PIN' : 'Create a 4–6 digit PIN',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    counterStyle: TextStyle(color: Colors.grey[500]),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                  ),
                ),
                if (!isEnabled) ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: pinConfirmCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !loading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Confirm PIN',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      counterStyle: TextStyle(color: Colors.grey[500]),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Get.back(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: loading ? null : submit,
                child:
                    loading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          isEnabled ? 'Turn Off' : 'Turn On',
                          style: const TextStyle(color: Colors.white),
                        ),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
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
  final _MePalette palette;
  const _PreferencesCard({required this.palette});

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
    if (found != null) return '${found['label']}';
    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final gender =
        _gender.isEmpty
            ? ''
            : _gender
                .replaceAll('_', ' ')
                .replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.heart, color: p.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reading Preferences',
                  style: TextStyle(
                    color: p.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap:
                    () => Get.to(
                      () => const PreferencesScreen(isOnboarding: false),
                    )?.then((_) => _load()),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    color: p.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: p.accent,
                ),
              ),
            )
          else if (_genres.isEmpty)
            Text(
              'No preferences set yet. Tap Edit to add some.',
              style: TextStyle(color: p.secondary, fontSize: 12),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slug in _genres)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: p.chip,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: p.chipBorder),
                    ),
                    child: Text(
                      _slugToLabel(slug),
                      style: TextStyle(
                        color: p.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (gender.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Gender:',
                    style: TextStyle(color: p.muted, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gender,
                    style: TextStyle(
                      color: p.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
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

/// Me-screen colours. Dark values are the HuxNovel design's; light values are
/// the same warm palette lightened to match.
class _MePalette {
  final Color bg, card, title, secondary, muted, accent, primary, divider;
  final Color chip, chipBorder, emblem, vipBg, vipBorder, gold, danger;

  const _MePalette({
    required this.bg,
    required this.card,
    required this.title,
    required this.secondary,
    required this.muted,
    required this.accent,
    required this.primary,
    required this.divider,
    required this.chip,
    required this.chipBorder,
    required this.emblem,
    required this.vipBg,
    required this.vipBorder,
    required this.gold,
    required this.danger,
  });

  static const dark = _MePalette(
    bg: Color(0xFF171513),
    card: Color(0xFF24211E),
    title: Color(0xFFF7F1E9),
    secondary: Color(0xFFC5BAB0),
    muted: Color(0xFF9F9287),
    accent: Color(0xFFEF9B70),
    primary: Color(0xFFC65D32),
    divider: Color(0xFF3B332C),
    chip: Color(0xFF302A25),
    chipBorder: Color(0xFF3B332C),
    emblem: Color(0xFF3D281F),
    vipBg: Color(0xFF35241C),
    vipBorder: Color(0xFF71422D),
    gold: Color(0xFFD6B37C),
    danger: Color(0xFFDD8C7E),
  );

  static const light = _MePalette(
    bg: Color(0xFFF7F3EE),
    card: Color(0xFFFFFFFF),
    title: Color(0xFF221C17),
    secondary: Color(0xFF6E6359),
    muted: Color(0xFF8F8378),
    accent: Color(0xFFC65D32),
    primary: Color(0xFFC65D32),
    divider: Color(0xFFEFE7DF),
    chip: Color(0xFFF4EDE6),
    chipBorder: Color(0xFFE9DFD5),
    emblem: Color(0xFFFBE7DC),
    vipBg: Color(0xFFFBEDE4),
    vipBorder: Color(0xFFEFC9B3),
    gold: Color(0xFFB0823F),
    danger: Color(0xFFC24E3B),
  );

  static _MePalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
