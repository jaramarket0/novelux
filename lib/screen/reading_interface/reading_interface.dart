import 'dart:math' as math;
import 'dart:developer' as myLog;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/book_preview/book_preview.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/screen/library/controller/library_controller.dart';
//import 'package:novelux/screen/audio/audio_player_screen.dart';
import 'package:novelux/screen/me/ReadingScheduleScreen.dart';
import 'package:novelux/screen/reading_interface/audio_player_screen.dart';
//import 'package:novelux/screen/reading_schedule/reading_schedule_screen.dart';
import 'package:novelux/screen/reading_interface/controller/reading_interface_controller.dart';
import 'package:novelux/screen/reading_interface/controller/continue_reading_controller.dart';
import 'package:novelux/screen/download_screen/controller/download_controller.dart';
import 'package:novelux/widgets/custom_image_view.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:novelux/config/ad_service.dart';
import 'package:novelux/config/iap_service.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_route_observer.dart';

class _GiftRankingSheet extends StatefulWidget {
  final String storySlug;
  const _GiftRankingSheet({required this.storySlug});

  static Future<void> show(BuildContext context, {required String storySlug}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _GiftRankingSheet(storySlug: storySlug),
      );

  @override
  State<_GiftRankingSheet> createState() => _GiftRankingSheetState();
}

class _GiftRankingSheetState extends State<_GiftRankingSheet> {
  // 0 = Gratuity (paid gifts), 1 = Flowers (free)
  int _tab = 0;
  List<Map<String, dynamic>> _tippers = [];
  List<Map<String, dynamic>> _flowers = [];
  bool _loading = true;

  // Gift points mapping — matches _gifts list
  static const _giftPoints = {
    'Like': 10,
    'Ice pop': 20,
    'Coffee': 60,
    'Champagne': 100,
    'Luxury Car': 400,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    myLog.log('loading tippers');
    if (widget.storySlug.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final res = await ApiService.getTopTippers(widget.storySlug);
    print(res);
    myLog.log(res.toString());
    if (res['success']) {
      final all = List<Map<String, dynamic>>.from(
        res['data'] is List ? res['data'] : (res['data']['results'] ?? []),
      );

      // Split into paid (Gratuity) vs free flowers
      setState(() {
        _tippers =
            all
                .where(
                  (t) =>
                      (t['total_coins'] ?? t['coins'] ?? t['total'] ?? 0) > 0,
                )
                .toList();
        _flowers =
            all
                .where(
                  (t) =>
                      (t['total_coins'] ?? t['coins'] ?? t['total'] ?? 0) == 0,
                )
                .toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  // Convert coin total to gift points for display
  int _giftPts(Map t) {
    // Backend may return the gift label or we estimate from coins
    final label = t['gift_label']?.toString() ?? '';
    if (_giftPoints.containsKey(label)) {
      final count = t['count'] ?? 1;
      return (_giftPoints[label]! * count) as int;
    }
    // Fallback: use coins as approximate points
    return (t['total_coins'] ?? t['coins'] ?? t['total'] ?? 0) as int;
  }

  String _flowerCount(Map t) {
    final c = t['count'] ?? t['total_coins'] ?? t['total'] ?? 0;
    return '$c flower${c == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final list = _tab == 0 ? _tippers : _flowers;

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a1e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Tab row: [↓] [Gratuity] [Flowers ●] [?] ────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Collapse button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2a2a30),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Gratuity tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            _tab == 0
                                ? const Color(0xFF2a2a30)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Gratuity',
                          style: TextStyle(
                            color: _tab == 0 ? Colors.white : Colors.grey[500],
                            fontSize: 14,
                            fontWeight:
                                _tab == 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Flowers tab (yellow active style)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            _tab == 1
                                ? const Color(0xFFFFD600)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Flowers',
                          style: TextStyle(
                            color: _tab == 1 ? Colors.black : Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // About ranking button
                GestureDetector(
                  onTap: () => _AboutRankingSheet.show(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ────────────────────────────────────────────────────────
          const Text(
            'Novel gifts ranking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (_tab == 0)
            Builder(
              builder: (_) {
                final total = _tippers.fold<int>(
                  0,
                  (s, t) => s + ((t['count'] ?? 1) as int),
                );
                return RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Received  ',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      TextSpan(
                        text: '$total',
                        style: const TextStyle(
                          color: depperBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: '  gifts',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Builder(
              builder: (_) {
                final total = _flowers.fold<int>(
                  0,
                  (s, t) => s + ((t['count'] ?? 1) as int),
                );
                return RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Received  ',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      TextSpan(
                        text: '$total',
                        style: const TextStyle(
                          color: depperBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: '  flowers',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 28),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child:
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: depperBlue,
                        strokeWidth: 2,
                      ),
                    )
                    : list.isEmpty
                    ? _emptyState()
                    : Column(
                      children: [
                        // Podium (top 3)
                        if (list.length >= 2) _Podium(list: list, tab: _tab),
                        const SizedBox(height: 20),
                        // Rest of list (#4 onwards)
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: (list.length - 3).clamp(0, list.length),
                            itemBuilder: (_, i) {
                              final tipper = list[i + 3];
                              return _RankRow(
                                rank: i + 4,
                                tipper: tipper,
                                tab: _tab,
                                giftPts: _giftPts(tipper),
                                flowerCount: _flowerCount(tipper),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),

          // ── Bottom "Your rank" bar ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF2a2a30))),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5b21b6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Text(
                      'D',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Not ranked yet',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Ad',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          'Send flower',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_tab == 0 ? '🎁' : '🌸', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 14),
        Text(
          'No ${_tab == 0 ? 'gifts' : 'flowers'} yet',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Be the first to support the author!',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    ),
  );
}

// ── Podium widget ─────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List list;
  final int tab;
  const _Podium({required this.list, required this.tab});

  String _avatarLetter(Map t) {
    final u = t['user'] is Map ? t['user'] as Map : {};
    final name = u['username']?.toString() ?? 'A';
    return name.isNotEmpty ? name[0].toUpperCase() : 'A';
  }

  String _displayName(Map t) {
    final u = t['user'] is Map ? t['user'] as Map : {};
    return u['username']?.toString() ?? 'Anonymous';
  }

  String _subtitle(Map t) {
    if (tab == 0) {
      final pts = t['total_coins'] ?? t['coins'] ?? 0;
      return '$pts gift pts';
    }
    final c = t['count'] ?? 1;
    return '$c flower${c == 1 ? '' : 's'}';
  }

  Color _podiumBg(int rank) => switch (rank) {
    1 => const Color(0xFF3d1e00),
    2 => const Color(0xFF1e1e1e),
    _ => const Color(0xFF1a1a10),
  };

  Color _badgeColor(int rank) => switch (rank) {
    1 => const Color(0xFFFF4500),
    2 => const Color(0xFF555555),
    _ => const Color(0xFF7a6010),
  };

  @override
  Widget build(BuildContext context) {
    // Layout: [2nd] [1st — taller] [3rd]
    final items = <Widget>[];

    Widget _podiumCard(int rank) {
      if (list.length < rank) return const Expanded(child: SizedBox());
      final t = list[rank - 1] as Map;
      final avatar =
          t['user'] is Map
              ? (t['user'] as Map)['avatar']?.toString() ?? ''
              : '';
      final isFirst = rank == 1;
      final colors = [
        const Color(0xFF4a2800), // 1st
        const Color(0xFF2a2a2a), // 2nd
        const Color(0xFF2a2810), // 3rd
      ];

      return Expanded(
        child: Container(
          margin: EdgeInsets.only(top: isFirst ? 0 : 20, left: 6, right: 6),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: colors[rank - 1],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: isFirst ? 70 : 58,
                    height: isFirst ? 70 : 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _badgeColor(rank), width: 2.5),
                    ),
                    child: ClipOval(
                      child:
                          avatar.isNotEmpty
                              ? Image.network(
                                avatar.startsWith('http')
                                    ? avatar
                                    : 'http://10.0.2.2:8000$avatar',
                                fit: BoxFit.cover,
                              )
                              : Container(
                                color: _badgeColor(rank).withOpacity(0.3),
                                child: Center(
                                  child: Text(
                                    _avatarLetter(t),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isFirst ? 26 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                  ),
                  // Rank badge
                  Positioned(
                    bottom: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _badgeColor(rank),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1a1a1e),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _displayName(t),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(t as Map<String, dynamic>),
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [_podiumCard(2), _podiumCard(1), _podiumCard(3)],
      ),
    );
  }
}

// ── Rank list row ─────────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final int rank;
  final Map tipper;
  final int tab;
  final int giftPts;
  final String flowerCount;
  const _RankRow({
    required this.rank,
    required this.tipper,
    required this.tab,
    required this.giftPts,
    required this.flowerCount,
  });

  @override
  Widget build(BuildContext context) {
    final user = tipper['user'] is Map ? tipper['user'] as Map : {};
    final uname = user['username']?.toString() ?? 'Anonymous user';
    final avatar = user['avatar']?.toString() ?? '';
    final initial = uname.isNotEmpty ? uname[0].toUpperCase() : 'A';
    final rankColors = {
      4: depperBlue,
      5: Colors.orange[300]!,
      6: Colors.orange[200]!,
    };
    final rankColor = rankColors[rank] ?? Colors.grey[500]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rankColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundImage:
                avatar.isNotEmpty
                    ? NetworkImage(
                          avatar.startsWith('http')
                              ? avatar
                              : 'http://10.0.2.2:8000$avatar',
                        )
                        as ImageProvider
                    : null,
            backgroundColor: Colors.grey[800],
            child:
                avatar.isEmpty
                    ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              uname,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            tab == 0 ? '$giftPts pts' : flowerCount,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── About Ranking info sheet ───────────────────────────────────────────────────
class _AboutRankingSheet extends StatelessWidget {
  const _AboutRankingSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AboutRankingSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF111114),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + header
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'About Ranking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The NoveluX Gratuity is ranked based on the cumulative rewards from all readers for this book.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'The Gift points are calculated as follows:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Points table
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2a2a30)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _ptRow('❤️', 'Like', '10 Gift points', true),
                        _ptRow('🍦', 'Ice pop', '20 Gift points', false),
                        _ptRow('☕', 'Coffee', '60 Gift points', true),
                        _ptRow('🍾', 'Champagne', '100 Gift points', false),
                        _ptRow(
                          '🚗',
                          'Luxury car',
                          '400 Gift points',
                          true,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'The more support you show to the author, the higher your Gift points and ranking will be.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Of course, we also have a free gift option: Flowers. Flowers are also a way to show your support for the author. The more flowers you send, the higher your ranking will be.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ptRow(
    String emoji,
    String name,
    String pts,
    bool shade, {
    bool isLast = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: shade ? const Color(0xFF1a1a1e) : const Color(0xFF111114),
      borderRadius:
          isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(12))
              : BorderRadius.zero,
    ),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 16),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '1 $name = ',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                TextSpan(
                  text: pts,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Light Ray Painter (gift animation) ──────────────────────────────────────

class _LightRayPainter extends CustomPainter {
  final double opacity;
  const _LightRayPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    const pi = 3.14159265358979;
    final center = Offset(size.width / 2, size.height / 2);
    const rayCount = 14;

    for (int i = 0; i < rayCount; i++) {
      final angle = i * (2 * pi) / rayCount;
      const innerR = 50.0;
      final outerR = 110.0 + (i % 2 == 0 ? 20.0 : 0.0);

      final paint =
          Paint()
            ..shader = RadialGradient(
              colors: [
                depperBlue.withOpacity(0.5 * opacity),
                Colors.transparent,
              ],
            ).createShader(Rect.fromCircle(center: center, radius: outerR))
            ..strokeWidth = i % 2 == 0 ? 4 : 2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          center.dx + innerR * _cosFn(angle),
          center.dy + innerR * _sinFn(angle),
        ),
        Offset(
          center.dx + outerR * _cosFn(angle),
          center.dy + outerR * _sinFn(angle),
        ),
        paint,
      );
    }
  }

  static double _cosFn(double x) {
    // use series since we can't guarantee import here
    double r = 0, term = 1, sign = 1;
    for (int i = 1; i <= 12; i++) {
      r += sign * term;
      term *= x * x / ((2 * i - 1) * (2 * i));
      sign *= -1;
    }
    return r;
  }

  static double _sinFn(double x) {
    double r = 0, term = x, sign = 1;
    for (int i = 1; i <= 12; i++) {
      r += sign * term;
      term *= x * x / ((2 * i) * (2 * i + 1));
      sign *= -1;
    }
    return r;
  }

  @override
  bool shouldRepaint(_LightRayPainter old) => old.opacity != opacity;
}

class NovelUpReadingInterface extends StatefulWidget {
  final String? storySlug;
  final String? storyTitle;
  final int? chapterNumber;
  final String? chapterTitle;
  final String? coverUrl;
  final String? author;
  final String? status;
  final int? totalChapter;
  final Map<int, String>? offlineContent;
  final String? genreSlug;

  const NovelUpReadingInterface({
    super.key,
    this.storySlug,
    this.storyTitle,
    this.chapterNumber,
    this.chapterTitle,
    this.coverUrl,
    this.totalChapter,
    this.author,
    this.status,
    this.offlineContent,
    this.genreSlug,
  });

  @override
  State<NovelUpReadingInterface> createState() =>
      _NovelUpReadingInterfaceState();
}

class _NovelUpReadingInterfaceState extends State<NovelUpReadingInterface>
    with TickerProviderStateMixin, RouteAware {
  late final ReadingInterfaceController ctrl;
  late final LibraryController libCtrl;
  late final DownloadController downloadCtrl;

  // Flip animation
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  String _prevContent = '';
  String _nextContent = '';
  bool _isAnimating = false;
  bool _flipForward = true;

  // Horizontal swipe state (Scroll ↔ mode)
  double _dragOffset = 0;
  bool _isDragging = false;

  // Suggested stories on exit
  List _suggestedStories = [];
  bool _suggestionShown = false;

  // Resets to 0 every time the app process is killed — no persistence needed
  static int _suggestionShowCount = 0;
  static const int _suggestionMaxShows = 3;

  // Screenshot lock, scoped strictly to the reading interface.
  //
  // A static ref-count guards against overlapping reader lifecycles: when one
  // reader replaces another via Get.off, the new reader's initState runs
  // BEFORE the old reader's dispose, and a naive on/off pair would leave the
  // new reader unprotected.
  static int _screenshotBlocks = 0;
  bool _blockingScreenshots = false;

  void _blockScreenshots() {
    if (_blockingScreenshots) return;
    _blockingScreenshots = true;
    _screenshotBlocks++;
    NoScreenshot.instance.screenshotOff();
  }

  void _unblockScreenshots() {
    if (!_blockingScreenshots) return;
    _blockingScreenshots = false;
    _screenshotBlocks--;
    if (_screenshotBlocks <= 0) {
      _screenshotBlocks = 0;
      NoScreenshot.instance.screenshotOn();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  // Another page was pushed on top (e.g. the audio player) — allow
  // screenshots outside the reader.
  @override
  void didPushNext() => _unblockScreenshots();

  // The covering page was popped and the reader is visible again.
  @override
  void didPopNext() => _blockScreenshots();

  @override
  void initState() {
    super.initState();
    _blockScreenshots();
    ctrl = Get.put(ReadingInterfaceController());
    ctrl.resetUiState();
    if (widget.offlineContent != null) {
      ctrl.setOfflineContent(widget.offlineContent!);
    }
    libCtrl = Get.put(LibraryController());
    downloadCtrl = Get.put(DownloadController());
    if (widget.storySlug != null && widget.chapterNumber != null) {
      if (!Get.isRegistered<ContinueReadingController>()) {
        Get.put(ContinueReadingController());
      }
      // Defer saving last-read until after the first frame to avoid
      // updating Rx observables during widget build (causes setState errors).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ContinueReadingController.to.saveLastRead(
          title: widget.storyTitle ?? widget.storySlug ?? '',
          slug: widget.storySlug!,
          cover: widget.coverUrl ?? '',
          chapter: widget.chapterNumber!,
          chapterTitle: widget.chapterTitle ?? '',
        );
      });
    }
    myLog.log(
      'ReadingInterface initialized with storySlug=${widget.storySlug} chapterNumber=${widget.chapterNumber} image: Path=${widget.coverUrl}, author: ${widget.author}',
    );
    print(
      'ReadingInterface initialized with storySlug=${widget.storySlug} chapterNumber=${widget.chapterNumber} image: Path=${widget.coverUrl}',
    );
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut);

    if (widget.storySlug != null && widget.chapterNumber != null) {
      ctrl
          .loadChapter(
            widget.storySlug!,
            widget.chapterNumber!,
            widget.chapterTitle,
          )
          .then((_) {
            if (mounted && ctrl.isCurrentChapterLocked.value) {
              _showCurrentChapterLockedModal();
            }
          });
    }
    // Start reading time tracker
    if (!Get.isRegistered<ReadingScheduleController>()) {
      Get.put(ReadingScheduleController());
    }
    ctrl.startReadingTimer();

    if (widget.genreSlug != null) {
      _fetchSuggested(widget.genreSlug!);
    }

    if (widget.storySlug != null && widget.chapterNumber != null) {
      libCtrl.logView(
        slug: widget.storySlug!,
        title:
            widget.storySlug?.replaceAll('-', ' ').toUpperCase() ??
            'UNKNOWN TITLE',
        coverUrl: widget.coverUrl ?? 'assets/images/1024.png',
        totalChapters: widget.totalChapter ?? 0,
        chapterNumber: widget.chapterNumber!,
        chapterTitle: widget.chapterTitle ?? '',
      );
    }
    ;
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _unblockScreenshots();
    ctrl.stopReadingTimer();
    _flipCtrl.dispose();
    super.dispose();
  }

  // Maps the user-visible font name to a concrete TextStyle via google_fonts.
  // 'System' → device default; others → the matching Google Font.
  TextStyle _readingTextStyle({
    required double size,
    required Color color,
    required double height,
    FontWeight weight = FontWeight.normal,
  }) {
    switch (ctrl.selectedFont) {
      case 'Lora':
        return GoogleFonts.lora(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: weight,
        );
      case 'Assistant':
        return GoogleFonts.assistant(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: weight,
        );
      case 'Modern':
        return GoogleFonts.openSans(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: weight,
        );
      case 'System':
      default:
        return TextStyle(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: weight,
        );
    }
  }

  // ── Trigger flip then load chapter ───────────────────────────────────────
  Future<void> _navigateWithFlip(bool forward) async {
    if (_isAnimating) {
      return;
    }
    final useFlip =
        ctrl.pageFlipEffect == 'Flip' || ctrl.pageFlipEffect == 'Animate';

    if (useFlip) {
      setState(() {
        _isAnimating = true;
        _flipForward = forward;
        _prevContent = ctrl.chapterContent.value;
      });
      // Phase 1: fold out current page
      await _flipCtrl.forward();
      // Load the new chapter while page is "flipped away"
      if (forward) {
        await ctrl.goNextChapter();
        // Check if the next chapter was locked — abort flip and show modal
        if (ctrl.isNextChapterLocked.value) {
          await _flipCtrl.reverse();
          setState(() => _isAnimating = false);
          if (mounted) _showLockedChapterModal();
          return;
        }
      } else {
        await ctrl.goPrevChapter();
      }
      setState(() => _nextContent = ctrl.chapterContent.value);
      // Phase 2: unfold new page
      await _flipCtrl.reverse();
      setState(() => _isAnimating = false);
    } else {
      if (forward) {
        await ctrl.goNextChapter();
        if (ctrl.isNextChapterLocked.value) {
          if (mounted) _showLockedChapterModal();
          return;
        }
      } else {
        await ctrl.goPrevChapter();
      }
      ctrl.scrollController.jumpTo(0);
    }
    // Trigger interstitial every N chapters
    AdService.instance.onChapterRead();
  }

  Future<void> _fetchSuggested(String genreSlug) async {
    final res = await ApiService.getStories(genre: genreSlug, pageSize: 10);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'];
      final list = data is List ? data : ((data as Map?)?['results'] ?? []);
      final filtered =
          (list as List).where((s) => s['slug'] != widget.storySlug).toList();
      setState(() => _suggestedStories = filtered);
    }
  }

  void _showSuggestedModal() {
    if (_suggestedStories.isEmpty ||
        _suggestionShowCount >= _suggestionMaxShows) {
      setState(() => _suggestionShown = true);
      Navigator.of(context).pop();
      return;
    }
    _suggestionShowCount++;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder:
          (_) => _SuggestedForYouSheet(
            stories: _suggestedStories,
            onClose: () {
              Navigator.of(context).pop(); // close sheet only — stay in reader
            },
            onReadStory: (story) {
              final rawCover = story['cover_image']?.toString() ?? '';
              final cover =
                  rawCover.startsWith('http')
                      ? rawCover
                      : (rawCover.isNotEmpty
                          ? 'http://10.0.2.2:8000$rawCover'
                          : '');
              final authorObj = story['author'];
              final author =
                  authorObj is Map
                      ? authorObj['username']?.toString() ?? ''
                      : authorObj?.toString() ?? '';
              final genre = story['genre'];
              final nextGenreSlug =
                  genre is Map ? genre['slug']?.toString() : null;

              setState(() => _suggestionShown = true);
              Navigator.of(context).pop(); // close sheet
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                // Get.off replaces the reading interface in one step (no flash)
                Get.off(
                  () => NovelUpReadingInterface(
                    storySlug: story['slug']?.toString(),
                    chapterNumber: 1,
                    chapterTitle: '',
                    coverUrl: cover,
                    author: author,
                    genreSlug: nextGenreSlug,
                  ),
                  transition: Transition.fadeIn,
                  duration: const Duration(milliseconds: 300),
                );
              });
            },
          ),
    ).then((_) {
      if (mounted) setState(() => _suggestionShown = true);
    });
  }

  void _showLockedChapterModal() {
    _showPurchaseSheet(
      cost: ctrl.lockedChapterCoinCost.value,
      isDismissible: true,
      onCoinUnlock: () async {
        final ok = await ctrl.unlockAndLoadNextChapter();
        if (ok && mounted) {
          Get.back();
          ctrl.scrollController.jumpTo(0);
        }
        return ok;
      },
    );
  }

  void _showCurrentChapterLockedModal() {
    _showPurchaseSheet(
      cost: ctrl.lockedChapterCoinCost.value,
      isDismissible: false,
      onCoinUnlock: () async {
        final ok = await ctrl.unlockCurrentChapter();
        if (ok && mounted) {
          Get.back();
          ctrl.scrollController.jumpTo(0);
        }
        return ok;
      },
    );
  }

  void _showPurchaseSheet({
    required int cost,
    required bool isDismissible,
    required Future<bool> Function() onCoinUnlock,
  }) {
    final svc = IAPService.to;
    final auth = Get.find<AuthController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        var selectedIdx = 0;
        return StatefulBuilder(
          builder: (ctx, setS) {
            // Order: Weekly → Monthly → Annual/Yearly
            final plans = [
              ...svc.vipPlans.where((p) => p.name == 'Weekly'),
              ...svc.vipPlans.where((p) => p.name == 'Monthly'),
              ...svc.vipPlans.where(
                (p) => p.name != 'Weekly' && p.name != 'Monthly',
              ),
            ];
            final selectedPlan = plans.isNotEmpty ? plans[selectedIdx] : null;

            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.88,
              child: Column(
                children: [
                  // ── Drag handle ──────────────────────────────────────────
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ── Price / balance row + Watch Ad ───────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'price:   $cost Coins',
                                style: const TextStyle(
                                  color: Color(0xFF555555),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Obx(() {
                                final coins = auth.coins;
                                return Text(
                                  'balance:   $coins Coins  |  0 Bonus',
                                  style: const TextStyle(
                                    color: Color(0xFF555555),
                                    fontSize: 13,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        // Watch Ad button
                        GestureDetector(
                          onTap: () {
                            AppAlert.info('Ads coming soon — Rewarded ads will be available shortly.');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: depperBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Watch Ad',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Subscription plan cards (horizontal scroll) ──────────
                  Obx(() {
                    final planList = [
                      ...svc.vipPlans.where((p) => p.name == 'Weekly'),
                      ...svc.vipPlans.where((p) => p.name == 'Monthly'),
                      ...svc.vipPlans.where(
                        (p) => p.name != 'Weekly' && p.name != 'Monthly',
                      ),
                    ];
                    if (planList.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      height: 158,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: planList.length,
                        itemBuilder: (_, i) {
                          final plan = planList[i];
                          final isSelected = i == selectedIdx;
                          return GestureDetector(
                            onTap: () => setS(() => selectedIdx = i),
                            child: Container(
                              width: 148,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(0xFF111111)
                                        : const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        '👑',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        plan.name,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF1a1a1a),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    plan.price,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : const Color(0xFF1a1a1a),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (plan.badge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: depperBlue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        plan.badge!.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      plan.period,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.grey[400]
                                                : Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child:
                                          isSelected
                                              ? const Center(
                                                child: Icon(
                                                  Icons.circle,
                                                  size: 10,
                                                  color: Colors.white,
                                                ),
                                              )
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 6),

                  // ── Scrollable body: coin packs + agreement ──────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Obx(() {
                        final packs = svc.coinPacks;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Coin package grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 2.1,
                                  ),
                              itemCount: packs.length,
                              itemBuilder: (_, i) {
                                final pack = packs[i];
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await svc.buyCoins(pack.id);
                                    if (!ctx.mounted) return;
                                    if (result.status ==
                                        PurchaseStatus2.success) {
                                      AppAlert.success('🎉 Coins added! — +${result.coinsGranted} coins deposited.');
                                      auth.refreshCoins();
                                    } else if (result.status ==
                                        PurchaseStatus2.error) {
                                      AppAlert.error('Purchase failed — ${result.message ?? 'Please try again.'}');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F2F2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '🪙',
                                          style: TextStyle(fontSize: 22),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${pack.coins}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF1a1a1a),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (pack.bonus != null) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    pack.bonus!,
                                                    style: const TextStyle(
                                                      color: depperBlue,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              pack.price,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 14),

                            // Recharge agreement
                            Center(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Recharge means agree to the ',
                                    ),
                                    TextSpan(
                                      text: 'Recharge Agreement',
                                      style: TextStyle(
                                        color: Color(0xFF3366CC),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ),
                  ),

                  // ── Fixed CTA: subscribe with selected plan ──────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF111111),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          onPressed:
                              svc.isPurchasing.value || selectedPlan == null
                                  ? null
                                  : () async {
                                    final result = await svc.buySubscription(
                                      selectedPlan.id,
                                    );
                                    if (!ctx.mounted) return;
                                    if (result.status ==
                                        PurchaseStatus2.success) {
                                      Get.back();
                                      AppAlert.success('👑 VIP Activated! — Enjoy unlimited reading.');
                                      // Refresh profile so is_vip / chapter
                                      // locks reflect the new subscription
                                      Future.delayed(
                                        const Duration(seconds: 2),
                                        auth.fetchMe,
                                      );
                                      Future.delayed(
                                        const Duration(seconds: 10),
                                        auth.fetchMe,
                                      );
                                    } else if (result.status ==
                                        PurchaseStatus2.error) {
                                      AppAlert.error('Purchase failed — ${result.message ?? 'Please try again.'}');
                                    }
                                  },
                          child:
                              svc.isPurchasing.value
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    selectedPlan != null
                                        ? '${selectedPlan.price}${selectedPlan.period}'
                                        : 'Subscribe',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _suggestionShown,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showSuggestedModal();
      },
      child: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: ctrl.handleVolumeKey,
        child: Scaffold(
          body: Obx(
            () => Container(
              color: ctrl.currentBackgroundColor,
              child: Stack(
                children: [
                  _buildContent(),
                  if (ctrl.showTopBar) _buildTopBar(context),
                  if (ctrl.showBottomBar) _buildBottomBar(),
                  if (!ctrl.showSettings && !ctrl.showContents)
                    _buildRightFabs(),
                  // Banner ad — hidden while controls / settings are open
                  if (!ctrl.showBottomBar && !ctrl.showSettings && !ctrl.showContents)
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(child: AdBannerWidget()),
                    ),
                  if (ctrl.showSettings)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildSettingsPanel(),
                    ),
                  if (ctrl.showContents) _buildContentsPanel(),
                  if (ctrl.isLoadingChapter.value)
                    Container(
                      color: Colors.black38,
                      child: Center(
                        child: Container(
                          height: 130,
                          width: 130,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(31, 100, 100, 100),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SpinKitWanderingCubes(
                            size: 30,
                            //color: depperBlue,
                            itemBuilder: (context, index) {
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color:
                                      index.isEven ? depperBlue : Colors.white,
                                  shape: BoxShape.rectangle,
                                ),
                              );
                            },
                            //size: 50,
                            duration: const Duration(milliseconds: 1200),
                          ),
                        ),
                        // CircularProgressIndicator(
                        //   color: Colors.blue,
                        // ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ), // RawKeyboardListener
    ); // PopScope
  }

  // ── Page content with flip animation ─────────────────────────────────────
  Widget _buildContent() {
    final isHSwipe = ctrl.pageFlipEffect == 'Scroll ↔';

    return GestureDetector(
      onTap: ctrl.onScreenTap,
      // ── Horizontal swipe navigation (Scroll ↔) ──────────────────────────
      onHorizontalDragUpdate:
          isHSwipe && !_isAnimating
              ? (d) => setState(() {
                _isDragging = true;
                _dragOffset = (_dragOffset + d.delta.dx).clamp(-150.0, 150.0);
              })
              : null,
      onHorizontalDragEnd:
          isHSwipe
              ? (d) {
                final vel = d.primaryVelocity ?? 0;
                final dist = _dragOffset;
                setState(() {
                  _isDragging = false;
                  _dragOffset = 0;
                });
                // Swipe left (negative) → next chapter
                if ((dist < -60 || vel < -400) && ctrl.hasNextChapter) {
                  _navigateWithFlip(true);
                  // Swipe right (positive) → previous chapter
                } else if ((dist > 60 || vel > 400) && ctrl.hasPrevChapter) {
                  _navigateWithFlip(false);
                }
              }
              : null,
      onHorizontalDragCancel:
          isHSwipe
              ? () => setState(() {
                _isDragging = false;
                _dragOffset = 0;
              })
              : null,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, __) {
          final useFlip =
              (ctrl.pageFlipEffect == 'Flip' ||
                  ctrl.pageFlipEffect == 'Animate') &&
              _isAnimating;

          // During horizontal drag, translate page to give visual feedback.
          Widget page;
          if (!useFlip) {
            page = Obx(() => _scrollPage(ctrl.chapterContent.value));
          } else {
            // 3-D page flip using Matrix4
            final angle = _flipAnim.value * math.pi;
            final isBack = angle > math.pi / 2;
            final displayContent = isBack ? _nextContent : _prevContent;
            page = Transform(
              alignment:
                  _flipForward ? Alignment.centerRight : Alignment.centerLeft,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_flipForward ? -angle : angle),
              child: _scrollPage(displayContent),
            );
          }

          if (isHSwipe && _isDragging && _dragOffset != 0) {
            page = Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Opacity(
                opacity: (1.0 - (_dragOffset.abs() / 200)).clamp(0.6, 1.0),
                child: page,
              ),
            );
          }

          return page;
        },
      ),
    );
  }

  Widget _scrollPage(String content) => SingleChildScrollView(
    controller: ctrl.scrollController,
    padding: const EdgeInsets.fromLTRB(24, 80, 24, 160),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter title
        Text(
          ctrl.currentChapter,
          style: _readingTextStyle(
            size: ctrl.fontSize + 4,
            color: ctrl.currentTextColor,
            height: 1.3,
            weight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        // Body
        HtmlWidget(
          content.isNotEmpty ? content : 'Loading...',
          textStyle: _readingTextStyle(
            size: ctrl.fontSize,
            color: ctrl.currentTextColor,
            height: ctrl.currentLineHeight,
          ),
          customStylesBuilder: (element) {
            if (element.localName == 'p') {
              return {'text-align': 'justify'};
            }
            return null;
          },
          // textAlign: TextAlign.justify,
        ),
        // Native ad at end of chapter
        if (!ctrl.isLoadingChapter.value && content.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: NativeAdWidget(height: 200),
          ),
        // End of chapter actions
        if (!ctrl.isLoadingChapter.value && content.isNotEmpty)
          Builder(
            builder:
                (ctx) => _EndOfChapterSection(
                  storySlug: widget.storySlug,
                  chapterNumber: widget.chapterNumber,
                  controller: ctrl,
                  onCommentTap: () => _showComments(ctx),
                  onNext:
                      ctrl.hasNextChapter
                          ? () => _navigateWithFlip(true)
                          : null,
                  onPrev:
                      ctrl.hasPrevChapter
                          ? () => _navigateWithFlip(false)
                          : null,
                ),
          ),
        const SizedBox(height: 80),
      ],
    ),
  );

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Container(
      color: ctrl.currentBackgroundColor.withOpacity(0.97),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: ctrl.currentTextColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => Text(
                    ctrl.currentChapter,
                    style: TextStyle(
                      color: ctrl.currentTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: depperBlue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 14,
                    ),
                    Obx(
                      () => Text(
                        ' +${ctrl.coins}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: ctrl.currentTextColor,
                  size: 20,
                ),
                color: const Color(0xFF2a2a2a),
                onSelected: (v) {
                  if (v == 'vip') {
                    AppAlert.info('VIP — VIP Ad-Free coming soon!');
                  }
                },
                itemBuilder:
                    (_) => [
                      const PopupMenuItem(
                        value: 'vip',
                        child: Row(
                          children: [
                            Icon(Icons.star, color: depperBlue, size: 16),
                            SizedBox(width: 10),
                            Text(
                              'VIP Ad-Free',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // ── Bottom bar with progress ──────────────────────────────────────────────
  Widget _buildBottomBar() => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: SafeArea(
      child: Container(
        color: ctrl.currentBackgroundColor.withOpacity(0.97),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress slider + prev/next chapter chevrons
            Obx(
              () => Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color:
                            ctrl.hasPrevChapter
                                ? ctrl.currentTextColor
                                : Colors.grey,
                        size: 26,
                      ),
                      onPressed:
                          ctrl.hasPrevChapter
                              ? () => _navigateWithFlip(false)
                              : null,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: depperBlue,
                          inactiveTrackColor: Colors.grey[700],
                          thumbColor: depperBlue,
                        ),
                        child: Slider(
                          value: ctrl.readingProgress.clamp(0.0, 1.0),
                          min: 0,
                          max: 1,
                          onChanged: (v) {
                            if (ctrl.scrollController.hasClients) {
                              final max =
                                  ctrl
                                      .scrollController
                                      .position
                                      .maxScrollExtent;
                              ctrl.scrollController.jumpTo(v * max);
                            }
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color:
                            ctrl.hasNextChapter
                                ? ctrl.currentTextColor
                                : Colors.grey,
                        size: 26,
                      ),
                      onPressed:
                          ctrl.hasNextChapter
                              ? () => _navigateWithFlip(true)
                              : null,
                    ),
                  ],
                ),
              ),
            ),
            // Action buttons row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navBtn(
                    LucideIcons.libraryBig500,
                    'Contents',
                    ctrl.toggleContents,
                  ),
                  _navBtn(
                    LucideIcons.moon500,
                    'Dark mode',
                    () => ctrl.setBackground(
                      ctrl.selectedBackground == 4 ? 1 : 4,
                    ),
                  ),
                  _navBtn(LucideIcons.bolt500, 'Settings', ctrl.toggleSettings),
                  Obx(() {
                    final status = downloadCtrl.statusOf(widget.storySlug!);
                    final prog =
                        downloadCtrl.progress[widget.storySlug!] ?? 0.0;
                    final isDone = status == 'done';
                    final isDownloading = status == 'downloading';
                    final label =
                        isDownloading
                            ? '${(prog * 100).round()}%'
                            : isDone
                            ? 'Saved'
                            : 'Download';
                    final color = isDone ? Colors.green : ctrl.currentTextColor;
                    return GestureDetector(
                      onTap:
                          isDone || isDownloading
                              ? null
                              : () => downloadCtrl.requestDownload(
                                slug: widget.storySlug!,
                                title:
                                    widget.storySlug!
                                        .replaceAll('-', ' ')
                                        .capitalize!,
                                author: widget.author!,
                                coverUrl: widget.coverUrl ?? '',
                              ),
                      child: Opacity(
                        opacity: isDownloading ? 0.6 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : LucideIcons.bookDown500,
                              color: color,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _navBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ctrl.currentTextColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: ctrl.currentTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );

  // ── Right-side floating buttons: bookmark (top) + listen (bottom) ──────────
  Widget _buildRightFabs() {
    final detailCtrl = widget.storySlug != null &&
            Get.isRegistered<StoryDetailController>(tag: widget.storySlug)
        ? Get.find<StoryDetailController>(tag: widget.storySlug)
        : null;

    return Positioned(
      bottom: 140,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bookmark icon
          if (detailCtrl != null)
            Obx(() {
              final saved = detailCtrl.isBookmarked.value;
              return GestureDetector(
                onTap: () => detailCtrl.toggleBookmark(widget.storySlug!),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2a1a),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: depperBlue.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: saved ? depperBlue : depperBlue.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
              );
            }),
          // Listen FAB (only when listen is enabled)
          if (ctrl.showListenButton) _buildListenFab(),
        ],
      ),
    );
  }

  // ── Listen FAB ────────────────────────────────────────────────────────────
  Widget _buildListenFab() => GestureDetector(
    onTap: () {
      // Init AudioPlayerController if not already
      if (!Get.isRegistered<AudioPlayerController>()) {
        Get.put(AudioPlayerController(), permanent: true);
      }
      final audioCtrl = Get.find<AudioPlayerController>();
      audioCtrl.loadChapter(
        content: ctrl.chapterContent.value,
        chapter: ctrl.currentChapter,
        story: ctrl.bookTitle,
        cover: widget.coverUrl ?? '',
        author: widget.author!,
      );
      myLog.log(
        'navigating to audio screen with storySlug=${widget.storySlug} image: Path=${widget.coverUrl}, author: ${widget.author}',
      );
      Get.to(
        () => AudioPlayerScreen(
          widget.coverUrl ?? '',
          widget.author ?? 'Unkown Author',
          widget.storySlug!.replaceAll('-', ' ').capitalize!,
        ),
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 300),
      );
    },
    child: Container(
      width: 80,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: depperBlue.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.headphones300, color: depperBlue, size: 14),
          SizedBox(width: 4),
          Text(
            'Listen',
            style: TextStyle(
              color: depperBlue,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Settings panel — pixel-perfect match to screenshot ───────────────────
  Widget _buildSettingsPanel() {
    final bg = ctrl.currentBackgroundColor;
    final labelColor = Colors.grey[500]!;

    return Container(
      constraints: const BoxConstraints(maxHeight: 560),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Brightness ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Brightness',
                  style: TextStyle(fontSize: 11, color: labelColor),
                ),
                Obx(
                  () => Text(
                    '${(ctrl.brightness * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.brightness_low, color: Colors.grey[500], size: 20),
                Expanded(
                  child: Obx(
                    () => Slider(
                      value: ctrl.brightness,
                      min: 0.01, // Prevent total black
                      max: 1.0,
                      onChanged: ctrl.setBrightness,
                      activeColor: depperBlue,
                      inactiveColor: Colors.grey[700],
                    ),
                  ),
                ),
                Icon(Icons.brightness_high, color: Colors.grey[500], size: 20),
              ],
            ),

            // ── Font size ─────────────────────────────────────────────────
            Text(
              'Font size',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            Row(
              children: [
                Text(
                  'A-',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                Expanded(
                  child: Obx(
                    () => Slider(
                      value: ctrl.fontSize,
                      min: 12,
                      max: 28,
                      onChanged: ctrl.setFontSize,
                      activeColor: depperBlue,
                      inactiveColor: Colors.grey[700],
                    ),
                  ),
                ),
                Text(
                  'A+',
                  style: TextStyle(fontSize: 17, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Fonts ─────────────────────────────────────────────────────
            Text('Fonts', style: TextStyle(fontSize: 11, color: labelColor)),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children:
                    ctrl.fonts.map((f) {
                      final sel = ctrl.selectedFont == f;
                      return GestureDetector(
                        onTap: () => ctrl.setFont(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: sel ? depperBlue : Colors.grey[600]!,
                              width: sel ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: f == 'System' ? null : f,
                              color: sel ? depperBlue : Colors.grey[500],
                              fontWeight:
                                  sel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Line spacing — horizontal line icons like screenshot ──────
            Text(
              'Line spacing',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                children: List.generate(4, (i) {
                  final sel = ctrl.selectedLineSpacing == i;
                  // Draw i+2 horizontal lines to represent spacing visually
                  return GestureDetector(
                    onTap: () => ctrl.setLineSpacing(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: sel ? depperBlue : Colors.grey[600]!,
                          width: sel ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          i + 2,
                          (j) => Container(
                            width: 22,
                            height: 2.5,
                            margin: EdgeInsets.only(
                              bottom: j < i + 1 ? (2.5 + i * 1.0) : 0,
                            ),
                            color: sel ? depperBlue : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),

            // ── Background color — pill shapes like screenshot ────────────
            Text(
              'Background color',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const SizedBox(height: 10),
            Obx(
              () => Row(
                spacing: 1.0,
                children: List.generate(ctrl.backgroundColors.length, (i) {
                  final sel = ctrl.selectedBackground == i;
                  return GestureDetector(
                    onTap: () => ctrl.setBackground(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 4),
                      width: 43,
                      height: 25,
                      decoration: BoxDecoration(
                        color: ctrl.backgroundColors[i],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: sel ? depperBlue : Colors.grey[600]!,
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // ── Page flip effect ──────────────────────────────────────────
            Text(
              'Page flip effect',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                children:
                    ctrl.pageFlipEffects.map((e) {
                      final sel = ctrl.pageFlipEffect == e;
                      return GestureDetector(
                        onTap: () => ctrl.setPageFlipEffect(e),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: sel ? depperBlue : Colors.grey[600]!,
                              width: sel ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            e,
                            style: TextStyle(
                              fontSize: 10,
                              color: sel ? depperBlue : Colors.grey[500],
                              fontWeight:
                                  sel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            //  const SizedBox(height: 10),

            // ── Volume key toggle ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page turning by volume keys',
                  style: TextStyle(fontSize: 11, color: labelColor),
                ),
                Obx(
                  () => Switch(
                    value: ctrl.volumeKeyTurning,
                    onChanged: (_) => ctrl.toggleVolumeKeyTurning(),
                    activeColor: depperBlue,
                    inactiveThumbColor: Colors.grey,
                    trackOutlineColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Contents panel ────────────────────────────────────────────────────────
  Widget _buildContentsPanel() => Positioned.fill(
    child: Container(
      color: const Color(0xFF1a1a1a),
      child: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: ctrl.hideAllControls,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            Row(
              // spacing: 50,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImageView(
                  imagePath: widget.coverUrl,
                  width: 80,
                  height: 120,
                  //radius: 4,
                  margin: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  placeHolder: 'assets/images/novelux_placeholder_transcpr.jpg',
                ),

                Column(
                  spacing: 6,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SizedBox(
                        width: Get.width - 140,
                        child: Text(
                          textAlign: TextAlign.left,
                          //ctrl.bookTitle ??
                          widget.storySlug
                                  ?.replaceAll('-', ' ')
                                  .toUpperCase() ??
                              'UNKNOWN TITLE',
                          //'Unknown Title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          //  textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Text(
                      'By ${widget.author ?? 'Unknown Author'}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Serif',
                      ),
                    ),
                    Text(
                      '${ctrl.chapters.length ?? 'Unknown Chapters'} Chapters',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),

                    Wrap(
                      spacing: 6,
                      children: [
                        (widget.status != null &&
                                !widget.status!.contains('Ongoing'))
                            ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: depperBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.status ?? 'Ongoing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            :
                            // (widget.status != null &&
                            //     !widget.status ?? 'Ongoing'.contains('Completed'))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.status ?? 'Ongoing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Obx(
            //   () =>

            // ),
            const SizedBox(height: 4),
            const Divider(color: Color(0xFF2a2a2a)),
            Expanded(
              child: Obx(
                () =>
                    ctrl.chapters.isEmpty
                        ? const Center(
                          child: Text(
                            'No chapters loaded',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: ctrl.chapters.length,
                          itemBuilder: (_, i) {
                            final ch = ctrl.chapters[i];
                            final isCurrent = ctrl.currentChapter == ch.title;
                            return ListTile(
                              leading: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color:
                                      isCurrent ? depperBlue : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              title: Text(
                                ch.title,
                                style: TextStyle(
                                  color: isCurrent ? depperBlue : Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              trailing:
                                  ch.isRead
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      )
                                      : null,
                              onTap: () {
                                ctrl.hideAllControls();
                                if (widget.storySlug != null) {
                                  ctrl.loadChapter(
                                    widget.storySlug!,
                                    i + 1,
                                    ch.title,
                                  );
                                }
                              },
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Comment sheet ─────────────────────────────────────────────────────────
  void _showComments(BuildContext ctx) {
    if (widget.storySlug == null || widget.chapterNumber == null) {
      return;
    }

    final commentCtrl = TextEditingController();
    final comments = <Map>[].obs;
    final loading = true.obs;
    final isSending = false.obs;
    final replyingTo = Rx<Map?>(null);
    final authCtrl = Get.find<AuthController>();

    ApiService.getComments(widget.storySlug!, widget.chapterNumber!).then((
      res,
    ) {
      loading.value = false;
      if (res['success']) {
        final d = res['data'];
        comments.value = List<Map>.from(d is List ? d : (d['results'] ?? []));
        comments.refresh();
      }
    });

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            builder:
                (__, sc) => Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Text(
                        'Comments${comments.isNotEmpty ? "  (${comments.length})" : ""}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Divider(color: Color(0xFF2a2a2a)),
                    Expanded(
                      child: Obx(() {
                        if (loading.value) {
                          return const Center(
                            child: CircularProgressIndicator(color: depperBlue),
                          );
                        }
                        if (comments.isEmpty) {
                          return const Center(
                            child: Text(
                              'Be the first to comment!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: sc,
                          itemCount: comments.length,
                          itemBuilder: (_, i) {
                            final c = comments[i];
                            final user =
                                c['user'] is Map
                                    ? c['user'] as Map
                                    : <String, dynamic>{};
                            final username =
                                user['username']?.toString().isNotEmpty == true
                                    ? user['username'].toString()
                                    : authCtrl.username;
                            final avatar = user['avatar']?.toString() ?? '';
                            final initial =
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : '?';
                            final replies = (c['replies'] as List? ?? []);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    12,
                                    0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: depperBlue,
                                        radius: 18,
                                        backgroundImage:
                                            avatar.isNotEmpty
                                                ? NetworkImage(
                                                  avatar.startsWith('http')
                                                      ? avatar
                                                      : 'http://10.0.2.2:8000$avatar',
                                                )
                                                : null,
                                        child:
                                            avatar.isEmpty
                                                ? Text(
                                                  initial,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                                : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              username,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              c['content']?.toString() ?? '',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                _LikeButton(
                                                  comment: c,
                                                  onLikeChanged: (
                                                    liked,
                                                    count,
                                                  ) {
                                                    final u = Map<
                                                      String,
                                                      dynamic
                                                    >.from(c);
                                                    u['likes_count'] = count;
                                                    u['is_liked'] = liked;
                                                    comments[i] = u;
                                                    comments.refresh();
                                                  },
                                                ),
                                                const SizedBox(width: 16),
                                                GestureDetector(
                                                  onTap: () {
                                                    replyingTo.value = c;
                                                    commentCtrl.clear();
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.reply,
                                                        size: 15,
                                                        color: Colors.grey[500],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Reply',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[500],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (replies.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 46),
                                    child: Column(
                                      children:
                                          replies.map((r) {
                                            final ru =
                                                r['user'] is Map
                                                    ? r['user'] as Map
                                                    : <String, dynamic>{};
                                            final rn =
                                                ru['username']
                                                            ?.toString()
                                                            .isNotEmpty ==
                                                        true
                                                    ? ru['username'].toString()
                                                    : '?';
                                            final ra =
                                                ru['avatar']?.toString() ?? '';
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    12,
                                                    6,
                                                    12,
                                                    0,
                                                  ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 2,
                                                    height: 40,
                                                    color: Colors.grey[800],
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                        ),
                                                  ),
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        Colors.grey[700],
                                                    radius: 14,
                                                    backgroundImage:
                                                        ra.isNotEmpty
                                                            ? NetworkImage(
                                                              ra.startsWith(
                                                                    'https',
                                                                  )
                                                                  ? ra
                                                                  : 'http://10.0.2.2:8000$ra',
                                                            )
                                                            : null,
                                                    child:
                                                        ra.isEmpty
                                                            ? Text(
                                                              rn.isNotEmpty
                                                                  ? rn[0]
                                                                      .toUpperCase()
                                                                  : '?',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 10,
                                                              ),
                                                            )
                                                            : null,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          rn,
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          r['content']
                                                                  ?.toString() ??
                                                              '',
                                                          style: const TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                const Divider(
                                  color: Color(0xFF2a2a2a),
                                  height: 16,
                                  indent: 12,
                                  endIndent: 12,
                                ),
                              ],
                            );
                          },
                        );
                      }),
                    ),

                    // Reply banner
                    Obx(
                      () =>
                          replyingTo.value != null
                              ? Container(
                                color: const Color(0xFF2a2a2a),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.reply,
                                      color: depperBlue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Replying to ${replyingTo.value!['user'] is Map ? replyingTo.value!['user']['username'] ?? 'comment' : 'comment'}',
                                        style: const TextStyle(
                                          color: depperBlue,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        replyingTo.value = null;
                                        commentCtrl.clear();
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),

                    // Input
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 8,
                        left: 16,
                        right: 16,
                        top: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => TextField(
                                controller: commentCtrl,
                                style: const TextStyle(color: Colors.white),
                                textInputAction: TextInputAction.send,
                                onSubmitted:
                                    (_) => _submitComment(
                                      commentCtrl,
                                      comments,
                                      isSending,
                                      authCtrl,
                                      replyingTo,
                                    ),
                                decoration: InputDecoration(
                                  hintText:
                                      replyingTo.value != null
                                          ? 'Write a reply...'
                                          : 'Write a comment...',
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2a2a2a),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(
                            () => GestureDetector(
                              onTap:
                                  isSending.value
                                      ? null
                                      : () => _submitComment(
                                        commentCtrl,
                                        comments,
                                        isSending,
                                        authCtrl,
                                        replyingTo,
                                      ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      isSending.value
                                          ? Colors.grey[700]
                                          : depperBlue,
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    isSending.value
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                              ),
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

  Future<void> _submitComment(
    TextEditingController commentCtrl,
    RxList<Map> comments,
    RxBool isSending,
    AuthController authCtrl,
    Rx<Map?> replyingTo,
  ) async {
    final text = commentCtrl.text.trim();
    if (text.isEmpty || isSending.value) {
      return;
    }

    isSending.value = true;
    final parentId = replyingTo.value?['id'] as int?;
    final res = await ApiService.postComment(
      widget.storySlug!,
      widget.chapterNumber!,
      text,
      parentId: parentId,
    );
    isSending.value = false;

    if (res['success']) {
      commentCtrl.clear();
      final raw = Map<String, dynamic>.from(res['data'] as Map);
      final userRes = raw['user'];
      if (userRes is! Map ||
          userRes['username']?.toString().isNotEmpty != true) {
        raw['user'] = {
          'id': authCtrl.currentUser.value?['id'],
          'username': authCtrl.username,
          'avatar': authCtrl.avatar ?? '',
        };
      }
      raw['likes_count'] ??= 0;
      raw['content'] ??= text;
      raw['replies'] ??= [];

      if (parentId != null) {
        final idx = comments.indexWhere((c) => c['id'] == parentId);
        if (idx != -1) {
          final updated = Map<String, dynamic>.from(comments[idx]);
          final reps = List<Map>.from(updated['replies'] ?? []);
          reps.add(raw);
          updated['replies'] = reps;
          comments[idx] = updated;
          comments.refresh();
        }
        replyingTo.value = null;
      } else {
        comments.insert(0, raw);
        comments.refresh();
      }
    } else {
      AppAlert.error(res['error'] ?? 'Could not post comment');
    }
  }
}

// ── End of Chapter Section ────────────────────────────────────────────────────
class _Gift {
  final String emoji;
  final String label;
  final int coins;
  const _Gift(this.emoji, this.label, this.coins);
}

const _gifts = [
  _Gift('🌸', 'Flower', 0),
  _Gift('❤️', 'Like', 10),
  _Gift('🍦', 'Ice pop', 50),
  _Gift('☕', 'Coffee', 100),
  _Gift('🍾', 'Champagne', 500),
  _Gift('🚗', 'Luxury Car', 1000),
];

class _EndOfChapterSection extends StatefulWidget {
  final String? storySlug;
  final int? chapterNumber;
  final VoidCallback onCommentTap;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final ReadingInterfaceController controller;

  const _EndOfChapterSection({
    required this.storySlug,
    required this.chapterNumber,
    required this.onCommentTap,
    required this.controller,
    this.onNext,
    this.onPrev,
  });

  @override
  State<_EndOfChapterSection> createState() => _EndOfChapterSectionState();
}

class _EndOfChapterSectionState extends State<_EndOfChapterSection>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  int? _selectedGiftIndex;
  bool _isSending = false;
  bool _showAnimation = false;
  String _animEmoji = '🌸';

  // ── Confetti ──────────────────────────────────────────────────────────────
  late ConfettiController _confettiLeft;
  late ConfettiController _confettiRight;

  // ── Gift pop-in (elastic scale) ───────────────────────────────────────────
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  // ── Float up-down ─────────────────────────────────────────────────────────
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  // ── Glow pulse ────────────────────────────────────────────────────────────
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // ── "Thank you!" fade ─────────────────────────────────────────────────────
  late AnimationController _thankCtrl;
  late Animation<double> _thankAnim;

  @override
  void initState() {
    super.initState();

    _confettiLeft = ConfettiController(duration: const Duration(seconds: 3));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 3));

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _thankCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _thankAnim = CurvedAnimation(parent: _thankCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _scaleCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _thankCtrl.dispose();
    super.dispose();
  }

  // ── Trigger gift animation + API call ─────────────────────────────────────
  Future<void> _sendGift(_Gift gift) async {
    if (_isSending) return;

    // Free gift → watch ad (AdMob stub)
    if (gift.coins == 0) {
      _playAnimation(gift.emoji);
      AppAlert.info('📺 Free Gift — Watching an ad to send ${gift.label}…');
      return;
    }

    setState(() => _isSending = true);
    final res = await ApiService.sendTip(
      widget.storySlug!,
      gift.coins,
      message: 'Sent a ${gift.label} gift!',
    );
    setState(() => _isSending = false);

    if (res['success']) {
      _playAnimation(gift.emoji);
      Get.find<AuthController>().refreshCoins();
    } else {
      setState(() => _selectedGiftIndex = null);
      AppAlert.error(res['error'] ?? 'Could not send gift');
    }
  }

  void _playAnimation(String emoji) {
    setState(() {
      _animEmoji = emoji;
      _showAnimation = true;
    });
    _confettiLeft.play();
    _confettiRight.play();
    _scaleCtrl.forward(from: 0);
    _thankCtrl.forward(from: 0);

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showAnimation = false);
        _thankCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Main content ────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prev / Next navigation buttons
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onPrev,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        margin: const EdgeInsets.only(bottom: 12, right: 5),
                        decoration: BoxDecoration(
                          color:
                              ctrl.hasPrevChapter
                                  ? const Color(0xFF2a2a2a)
                                  : const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                ctrl.hasPrevChapter
                                    ? Colors.grey[600]!
                                    : Colors.grey[800]!,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              color:
                                  ctrl.hasPrevChapter
                                      ? Colors.white
                                      : Colors.grey[700],
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Previous',
                              style: TextStyle(
                                color:
                                    ctrl.hasPrevChapter
                                        ? Colors.white
                                        : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (ctrl.hasPrevChapter)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 2,
                                  left: 8,
                                  right: 8,
                                ),
                                child: Text(
                                  ctrl.prevChapterTitle,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onNext,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        margin: const EdgeInsets.only(bottom: 12, left: 5),
                        decoration: BoxDecoration(
                          color:
                              ctrl.hasNextChapter
                                  ? depperBlue
                                  : const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                ctrl.hasNextChapter
                                    ? depperBlue
                                    : Colors.grey[800]!,
                          ),
                        ),
                        child:
                            ctrl.isLoadingChapter.value
                                ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                                : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color:
                                          ctrl.hasNextChapter
                                              ? Colors.white
                                              : Colors.grey[700],
                                      size: 18,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ctrl.hasNextChapter
                                          ? 'Next Chapter'
                                          : 'Last Chapter',
                                      style: TextStyle(
                                        color:
                                            ctrl.hasNextChapter
                                                ? Colors.white
                                                : Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (ctrl.hasNextChapter)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2,
                                          left: 8,
                                          right: 8,
                                        ),
                                        child: Text(
                                          ctrl.nextChapterTitle,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Leave a comment bar
            GestureDetector(
              onTap: widget.onCommentTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.messageCirclePlus300,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Leave a comment',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),

            // ── Gift section ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1e1810),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3a2d1a)),
              ),
              child: Column(
                children: [
                  // Author header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: depperBlue.withOpacity(0.2),
                          child: Text(
                            ctrl.currentStorySlug!.isNotEmpty
                                ? ctrl.currentStorySlug![0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: depperBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      ctrl.currentStorySlug!
                                          .replaceAll('-', ' ')
                                          .capitalize
                                          .toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: depperBlue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Author',
                                      style: TextStyle(
                                        color: depperBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Thanks for your support, it motivates me to keep writing. 💛',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFF3a2d1a), height: 1),

                  // Send a gift label
                   Padding(
                    padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Column(
                      children: [
                        Text('🎁', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Text(
                          'Send a gift',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Show your appreciation to the author',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontFamily: kFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gift grid — 3 columns × 2 rows
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.95,
                          ),
                      itemCount: _gifts.length,
                      itemBuilder: (_, i) {
                        final gift = _gifts[i];
                        final isSelected = _selectedGiftIndex == i;
                        final isFree = gift.coins == 0;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedGiftIndex = i);
                            if (isFree) _sendGift(gift);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFF3a2010)
                                      : const Color(0xFF2a1e0c),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? depperBlue
                                        : const Color(0xFF3a2d1a),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: depperBlue.withOpacity(0.3),
                                          blurRadius: 14,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                      : [],
                            ),
                            child: Stack(
                              children: [
                                // Free / Ad badge
                                if (isFree)
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[700],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Ad',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Gift content
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        gift.emoji,
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        gift.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isFree ? 'Free' : '🪙 ${gift.coins}',
                                        style: TextStyle(
                                          color:
                                              isFree
                                                  ? Colors.greenAccent[400]
                                                  : Colors.orange[300],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Send button — visible when a paid gift is selected
                  if (_selectedGiftIndex != null &&
                      !_gifts[_selectedGiftIndex!].coins.isNaN &&
                      _gifts[_selectedGiftIndex!].coins > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: depperBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              _isSending
                                  ? null
                                  : () =>
                                      _sendGift(_gifts[_selectedGiftIndex!]),
                          child:
                              _isSending
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _gifts[_selectedGiftIndex!].emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Send ${_gifts[_selectedGiftIndex!].label}  ·  🪙 ${_gifts[_selectedGiftIndex!].coins}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),

                  // User gifts ranking row
                  GestureDetector(
                    onTap:
                        () => _GiftRankingSheet.show(
                          context,
                          storySlug: widget.storySlug ?? '',
                        ),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a1e0c),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3a2d1a)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('🏆', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 8),
                              Text(
                                'User gifts ranking',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Confetti — left ─────────────────────────────────────────────────
        Positioned(
          top: -200,
          left: 0,
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiLeft,
              blastDirection: -3.14159 / 4,
              emissionFrequency: 0.06,
              numberOfParticles: 20,
              gravity: 0.25,
              colors: const [
                Colors.pink,
                Colors.yellow,
                Colors.cyan,
                Colors.purple,
                depperBlue,
                Colors.red,
              ],
            ),
          ),
        ),

        // ── Confetti — right ────────────────────────────────────────────────
        Positioned(
          top: -200,
          right: 0,
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiRight,
              blastDirection: 3.14159 + 3.14159 / 4,
              emissionFrequency: 0.06,
              numberOfParticles: 20,
              gravity: 0.25,
              colors: const [
                Colors.pink,
                Colors.yellow,
                Colors.cyan,
                Colors.purple,
                depperBlue,
                Colors.red,
              ],
            ),
          ),
        ),

        // ── Gift emoji animation overlay ────────────────────────────────────
        if (_showAnimation)
          Positioned(
            bottom: 320,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow blob
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder:
                        (_, __) => Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                depperBlue.withOpacity(0.45 * _glowAnim.value),
                                Colors.deepOrange.withOpacity(
                                  0.2 * _glowAnim.value,
                                ),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                  ),
                  // Light rays
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder:
                        (_, __) => CustomPaint(
                          size: const Size(260, 260),
                          painter: _LightRayPainter(opacity: _glowAnim.value),
                        ),
                  ),
                  // Floating emoji
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: AnimatedBuilder(
                      animation: _floatAnim,
                      builder:
                          (_, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: child,
                          ),
                      child: Text(
                        _animEmoji,
                        style: const TextStyle(fontSize: 100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── "Thank you!" label ──────────────────────────────────────────────
        if (_showAnimation)
          Positioned(
            bottom: 280,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _thankAnim,
                child: const Text(
                  'Thank you! 💛',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: depperBlue, blurRadius: 20)],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Like Button ───────────────────────────────────────────────────────────────
class _LikeButton extends StatefulWidget {
  final Map comment;
  final Function(bool liked, int newCount) onLikeChanged;
  const _LikeButton({required this.comment, required this.onLikeChanged});
  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late int _count;
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _liked = widget.comment['is_liked'] == true;
    _count = (widget.comment['likes_count'] ?? 0) as int;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) {
      return;
    }
    final wasLiked = _liked;
    setState(() {
      _loading = true;
      if (wasLiked) {
        _liked = false;
        _count = (_count - 1).clamp(0, 99999);
      } else {
        _liked = true;
        _count++;
        _animCtrl.forward().then((_) => _animCtrl.reverse());
      }
    });
    widget.onLikeChanged(_liked, _count);
    final id = widget.comment['id'] as int;
    final res =
        wasLiked
            ? await ApiService.unlikeComment(id)
            : await ApiService.likeComment(id);
    setState(() => _loading = false);
    if (!res['success']) {
      setState(() {
        _liked = wasLiked;
        _count = wasLiked ? _count + 1 : (_count - 1).clamp(0, 99999);
      });
      widget.onLikeChanged(_liked, _count);
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _toggle,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: Icon(
              _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
              color: _liked ? depperBlue : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder:
                (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '$_count',
              key: ValueKey(_count),
              style: TextStyle(
                color: _liked ? depperBlue : Colors.grey[600],
                fontSize: 12,
                fontWeight: _liked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Suggested For You Sheet ───────────────────────────────────────────────────
class _SuggestedForYouSheet extends StatefulWidget {
  final List stories;
  final VoidCallback onClose;
  final void Function(Map story) onReadStory;

  const _SuggestedForYouSheet({
    required this.stories,
    required this.onClose,
    required this.onReadStory,
  });

  @override
  State<_SuggestedForYouSheet> createState() => _SuggestedForYouSheetState();
}

class _SuggestedForYouSheetState extends State<_SuggestedForYouSheet> {
  late final PageController _pageCtrl;
  int _idx = 0;

  String? _chapterContent;
  bool _chapterLoading = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.55);
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _idx) {
        setState(() {
          _idx = p;
          _chapterContent = null;
        });
        _loadChapter(p);
      }
    });
    _loadChapter(0);
  }

  Future<void> _loadChapter(int storyIndex) async {
    if (storyIndex >= widget.stories.length) return;
    final slug = widget.stories[storyIndex]['slug']?.toString();
    if (slug == null || slug.isEmpty) return;
    if (!mounted) return;
    setState(() => _chapterLoading = true);
    final res = await ApiService.getChapter(slug, 1);
    if (!mounted) return;
    setState(() {
      _chapterLoading = false;
      if (res['success'] == true) {
        final data = res['data'] as Map?;
        _chapterContent = data?['content']?.toString();
      } else {
        _chapterContent = null;
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg =
            isDark ? const Color.fromARGB(255, 22, 22, 26) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;
        final chipBg = isDark ? const Color(0xFF2a2a2a) : Colors.grey[100]!;
        final chipBorder = isDark ? const Color(0xFF3a3a3a) : Colors.grey[300]!;
        final quoteBg =
            isDark ? const Color(0xFF2D1520) : const Color(0xFFFFF0F5);

        final h = MediaQuery.of(context).size.height;
        final story =
            widget.stories.isNotEmpty ? widget.stories[_idx] as Map : null;

        return Container(
          height: h * 0.94,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: divClr,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Icon(Icons.close, size: 22, color: txt),
                    ),
                    Expanded(
                      child: Text(
                        'Suggested for you',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: txt,
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Cover carousel ───────────────────────────────────────────
              SizedBox(
                height: 210,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: widget.stories.length,
                  onPageChanged: (i) => setState(() => _idx = i),
                  itemBuilder: (_, i) {
                    final s = widget.stories[i] as Map;
                    final focused = i == _idx;
                    final cover = _coverUrl(s['cover_image']);
                    final status = s['status']?.toString() ?? '';
                    final rating =
                        double.tryParse(
                          s['average_rating']?.toString() ?? '0',
                        ) ??
                        0.0;
                    final views = s['total_views'] ?? 0;

                    return GestureDetector(
                      onTap:
                          () => _pageCtrl.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                      child: AnimatedScale(
                        scale: focused ? 1.0 : 0.82,
                        duration: const Duration(milliseconds: 250),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child:
                                    cover.isNotEmpty
                                        ? Image.network(
                                          cover,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  _coverPlaceholder(),
                                        )
                                        : _coverPlaceholder(),
                              ),
                              // Bottom gradient
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(14),
                                  ),
                                  child: Container(
                                    height: 60,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black54,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (status.isNotEmpty)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: _statusBadge(status),
                                ),
                              Positioned(
                                bottom: 8,
                                left: 10,
                                right: 10,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Color(0xFFFFD700),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      rating > 0
                                          ? rating.toStringAsFixed(1)
                                          : '0.0',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.visibility_outlined,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _fmt(views),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),

              // ── Story details ────────────────────────────────────────────
              if (story != null)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          story['title']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: txt,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        _buildTags(story, txt, chipBg, chipBorder),
                        const SizedBox(height: 12),
                        _buildQuoteBox(story, quoteBg),
                        const SizedBox(height: 14),
                        _buildChapterPreview(txt, sub),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

              // ── Free Reading button ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: GestureDetector(
                  onTap: story != null ? () => widget.onReadStory(story) : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4B8B), Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Center(
                      child: Text(
                        'Free Reading',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    final done = status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: done ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        done ? 'Completed' : 'Ongoing',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTags(Map story, Color txt, Color chipBg, Color chipBorder) {
    final tags = story['tags'] as List? ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children:
          tags.take(4).map<Widget>((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: chipBorder),
              ),
              child: Text(
                tag['name']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: txt),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildQuoteBox(Map story, Color quoteBg) {
    final desc = story['description']?.toString() ?? '';
    if (desc.isEmpty) return const SizedBox.shrink();
    final snippet = desc.length > 120 ? '${desc.substring(0, 120)}…' : desc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: quoteBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '❝',
            style: TextStyle(color: Color(0xFFFF4B8B), fontSize: 20, height: 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              snippet,
              style: const TextStyle(
                color: Color(0xFFFF4B8B),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.55,
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '❞',
              style: TextStyle(color: Color(0xFFFF4B8B), fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterPreview(Color txt, Color sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chapter 1',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: txt,
          ),
        ),
        const SizedBox(height: 8),
        if (_chapterLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(
                color: depperBlue,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_chapterContent != null && _chapterContent!.isNotEmpty)
          HtmlWidget(
            _chapterContent!,
            textStyle: TextStyle(color: sub, fontSize: 14, height: 1.75),
            customStylesBuilder: (element) {
              if (element.localName == 'p') {
                return {'text-align': 'justify'};
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _coverPlaceholder() => Container(
    color: const Color(0xFF2a2a2a),
    child: const Center(child: Icon(Icons.book, color: Colors.grey, size: 36)),
  );

  String _coverUrl(dynamic c) {
    if (c == null || c.toString().isEmpty) return '';
    if (c.toString().startsWith('http')) return c.toString();
    return 'http://10.0.2.2:8000$c';
  }

  String _fmt(dynamic n) {
    final v = int.tryParse(n?.toString() ?? '0') ?? 0;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}
