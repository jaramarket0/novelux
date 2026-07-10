import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/screen/auth/auth_controller.dart';

List<Map<String, dynamic>> parseRedeemPackages(dynamic payload) {
  if (payload is List) {
    return payload
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  if (payload is Map) {
    final data = payload['packages'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  return [];
}

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  List _packages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.getRedeemPackages();
    if (!mounted) return;

    if (res['success'] == true) {
      final payload = res['data'];
      setState(() {
        _packages = parseRedeemPackages(payload);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _onRedeem(Map pkg) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1e1e20) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Redeem ${pkg['label']}',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You are redeeming ${pkg['label']}.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cost: ${pkg['cost']} coins',
                  style: const TextStyle(
                    color: Color(0xFFE67E22),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      foregroundColor: const Color(0xFF1a1a1a),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Not now',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true) return;

    final res = await ApiService.redeemPackage(pkg['key'] as String);
    if (!mounted) return;

    if (res['success'] == true) {
      final auth = Get.find<AuthController>();
      // Refresh user profile to update coin balance and expiry fields
      await auth.fetchMe();

      final expiresAt = res['expires_at'] as String? ?? '';
      _showSuccessDialog(pkg['label'] as String, expiresAt);
    } else {
      AppAlert.error(res['error'] ?? 'Failed to redeem');
    }
  }

  void _showSuccessDialog(String label, String expiresAt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1e1e20) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Congratulations! $label unlocked',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Start enjoying your experience now.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (expiresAt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Expiration: $expiresAt',
                    style: const TextStyle(
                      color: Color(0xFFE67E22),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      foregroundColor: const Color(0xFF1a1a1a),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF5F0E8);
    final card = isDark ? const Color(0xFF1e1e20) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F0E8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: txt, size: 28),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Redeem',
          style: TextStyle(
            color: txt,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: txt),
            onPressed: () => Get.to(() => const _AboutRedeemScreen()),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE67E22)),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Coin balance header
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE67E22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'My coins',
                              style: TextStyle(
                                color: txt,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Text(
                            '${auth.coins}',
                            style: TextStyle(
                              color: txt,
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Package list
                  ..._packages.map(
                    (pkg) => _PackageRow(
                      pkg: pkg as Map,
                      card: card,
                      txt: txt,
                      sub: sub,
                      onRedeem: () => _onRedeem(pkg),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  final Map pkg;
  final Color card, txt, sub;
  final VoidCallback onRedeem;

  const _PackageRow({
    required this.pkg,
    required this.card,
    required this.txt,
    required this.sub,
    required this.onRedeem,
  });

  String get _durationLabel {
    final mins = (pkg['minutes'] as num).toInt();
    if (mins < 60) return '${mins}Mins';
    if (mins == 60) return '1\nHour';
    return '${mins ~/ 60}\nHours';
  }

  IconData get _icon {
    switch (pkg['benefit'] as String) {
      case 'vip':
        return Icons.favorite;
      case 'ad_free':
        return Icons.menu_book_outlined;
      case 'audiobook':
        return Icons.headphones_outlined;
      default:
        return Icons.star;
    }
  }

  String get _typeLabel {
    switch (pkg['benefit'] as String) {
      case 'vip':
        return 'VIP';
      case 'ad_free':
        return 'Ad-Free';
      case 'audiobook':
        return 'Audiobooks';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Duration tile
          Container(
            width: 80,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF5DEB3).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _durationLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8B6914),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, color: const Color(0xFF8B6914), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _typeLabel,
                      style: const TextStyle(
                        color: Color(0xFF8B6914),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg['label'] as String,
                  style: TextStyle(
                    color: txt,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pkg['desc'] as String,
                  style: TextStyle(color: sub, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE67E22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${pkg['cost']} coins',
                      style: const TextStyle(
                        color: Color(0xFFE67E22),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Redeem button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: const Color(0xFF1a1a1a),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: onRedeem,
            child: const Text(
              'Redeem',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRedeemScreen extends StatelessWidget {
  const _AboutRedeemScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0d0d0f) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);

    const body = '''When you redeem time using coins, please note the following:

If you redeem the same type of time (e.g., Ad-Free, VIP, or Audiobooks) multiple times, the time will accumulate and extend your current time.

If you redeem both VIP and Ad-Free, only the VIP benefits will be active, as VIP includes Ad-Free access. The Ad-Free time will not be added separately.

If you redeem both VIP and Audiobooks, only the VIP benefits will be active, as VIP includes Audiobooks access. The Audiobook time will not be added separately.

If you redeem both Ad-Free and Audiobooks, both benefits will be active simultaneously. However, the time for each benefit will not affect the other.

Please keep these guidelines in mind when redeeming your coins for benefits.''';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: txt, size: 28),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'About Redeem',
          style: TextStyle(
            color: txt,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          body,
          style: TextStyle(color: txt, fontSize: 15, height: 1.7),
        ),
      ),
    );
  }
}
