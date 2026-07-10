import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
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
import 'package:novelux/screen/reward_screen/reward_screen.dart';
import 'package:novelux/screen/me/ReadingScheduleScreen.dart';
import 'package:novelux/screen/editorial/ce_books_screen.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final ctrl = Get.put(MeController());
    final theme = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
        final cardBg =
            isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;

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
                    color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
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
                              child: (avatar != null && avatar.isNotEmpty)
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: _resolveAvatarUrl(avatar),
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Text(
                                          auth.username.isNotEmpty
                                              ? auth.username[0].toUpperCase()
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
                        GestureDetector(
                          onTap: () => Get.to(() => const VipScreen()),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2a1a00), Color(0xFF1a1200)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
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
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.diamond_outlined,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'VIP',
                                  style: TextStyle(
                                    color: Colors.white,
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
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Subscribe',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.orange,
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
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF221500), Color(0xFF150d00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(14),
                            ),
                          ),
                          child: Row(
                            children: [
                              _vipPerk(Icons.menu_book_outlined, 'Ad-Free'),
                              const SizedBox(width: 20),
                              _vipPerk(Icons.download_outlined, 'Offline'),
                              const SizedBox(width: 20),
                              _vipPerk(Icons.headphones_outlined, 'Audio'),
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
                              borderRadius: BorderRadius.circular(12),
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
                            borderRadius: BorderRadius.circular(12),
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
                          else if (isLoggedIn && auth.role != 'ce' && !auth.isAuthor)
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

  Widget _vipPerk(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.orange.withOpacity(0.8), size: 14),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 11),
      ),
    ],
  );

  Widget _section(Color bg, List<Widget> items) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
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
    final paint = Paint()
      ..color = const Color(0xFFD4A017)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 2;

    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * math.pi;
      final lx = cx + r * math.cos(angle);
      final ly = cy + r * math.sin(angle);
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(angle + math.pi / 2);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 5),
          paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
