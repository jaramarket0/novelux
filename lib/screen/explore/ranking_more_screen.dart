import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

/// Full paginated "More" list for a Ranking sub-section (Daily Releases /
/// Rising  or  Must Read / Popularity).
class RankingMoreScreen extends StatefulWidget {
  const RankingMoreScreen({
    super.key,
    required this.section,      // 'new-releases' | 'most-read'
    required this.filters,      // e.g. ['daily', 'rising']
    required this.filterLabels, // e.g. ['Daily Releases', 'Rising']
    required this.initialFilter,
  });

  final String section;
  final List<String> filters;
  final List<String> filterLabels;
  final String initialFilter;

  @override
  State<RankingMoreScreen> createState() => _RankingMoreScreenState();
}

class _RankingMoreScreenState extends State<RankingMoreScreen> {
  late String _activeFilter;
  final List<Map> _stories = [];
  bool _loading = false;
  bool _hasNext = true;
  int _page = 1;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _fetch();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _fetch();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_loading || !_hasNext) return;
    setState(() => _loading = true);
    final res = await ApiService.getRankingSection(
      section: widget.section,
      filter: _activeFilter,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map;
        final results = (data['results'] as List? ?? []).cast<Map>();
        _stories.addAll(results);
        _hasNext = data['has_next'] == true;
        _page++;
      } else {
        _hasNext = false;
      }
    });
  }

  void _switchFilter(String filter) {
    if (filter == _activeFilter) return;
    setState(() {
      _activeFilter = filter;
      _stories.clear();
      _hasNext = true;
      _page = 1;
    });
    _fetch();
  }

  String _formatViews(dynamic v) {
    final n = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Get.find<ThemeController>();
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
    final cardBg  = isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
    final txt     = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub     = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: txt, size: 20),
          ),
          titleSpacing: 0,
          title: Row(
            children: List.generate(widget.filters.length, (i) {
              final f   = widget.filters[i];
              final lbl = widget.filterLabels[i];
              final sel = f == _activeFilter;
              return GestureDetector(
                onTap: () => _switchFilter(f),
                child: Container(
                  padding: const EdgeInsets.only(right: 20, bottom: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: sel ? depperBlue : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    lbl,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: sel ? FontWeight.bold : FontWeight.w400,
                      color: sel ? txt : sub,
                      fontFamily: kFontFamily,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        body: RefreshIndicator(
          color: depperBlue,
          onRefresh: () async {
            setState(() { _stories.clear(); _hasNext = true; _page = 1; });
            await _fetch();
          },
          child: _stories.isEmpty && _loading
              ? _buildShimmer(isDark)
              : _stories.isEmpty
                  ? const Center(child: Text('Nothing here yet'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: _stories.length + (_loading ? 3 : 0),
                      itemBuilder: (_, idx) {
                        if (idx >= _stories.length) {
                          return _shimmerTile(isDark);
                        }
                        final story = _stories[idx];
                        return _storyTile(story, cardBg, txt, sub);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _storyTile(Map story, Color cardBg, Color txt, Color sub) {
    final coverUrl = story['cover_image']?.toString() ?? '';
    final tags     = (story['tags'] as List? ?? []);
    final firstTag = tags.isNotEmpty
        ? (tags.first is Map ? tags.first['name'] : tags.first.toString())
        : '';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => StoryDetailScreen(slug: story['slug'], heroTag: 'hero-rankingmore-${story['slug']}')),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Hero(
                tag: 'hero-rankingmore-${story['slug']}',
                child: CustomImageView(
                  imagePath: coverUrl.startsWith('http') ? coverUrl
                      : coverUrl.isNotEmpty ? 'http://10.0.2.2:8000$coverUrl' : '',
                  width: 90,
                  height: 126,
                  fit: BoxFit.cover,
                  placeHolder: 'assets/images/novelux_placeholder_transcpr.jpg',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: txt,
                      fontFamily: kFontFamily,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story['description'] ?? story['synopsis'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: sub, fontFamily: kFontFamily),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${_formatViews(story['total_views'] ?? 0)} Views',
                        style: TextStyle(
                          fontSize: 12,
                          color: depperBlue,
                          fontWeight: FontWeight.w600,
                          fontFamily: kFontFamily,
                        ),
                      ),
                      if (firstTag.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sub.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            firstTag,
                            style: TextStyle(fontSize: 11, color: sub, fontFamily: kFontFamily),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 8,
      itemBuilder: (_, __) => _shimmerTile(isDark),
    );
  }

  Widget _shimmerTile(bool isDark) {
    final base = isDark ? const Color(0xFF2a2a2a) : Colors.grey[300]!;
    final hi   = isDark ? const Color(0xFF3a3a3a) : Colors.grey[100]!;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: hi,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 110,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
