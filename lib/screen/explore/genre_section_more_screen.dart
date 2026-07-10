import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';
import 'package:shimmer/shimmer.dart';

/// Full paginated list for any section inside a genre/gender explore tab.
/// e.g. "Picks for You" in For Her, "Fresh Reads" in Werewolf, etc.
class GenreSectionMoreScreen extends StatefulWidget {
  const GenreSectionMoreScreen({
    super.key,
    required this.tab,       // e.g. 'for-her', 'werewolf'
    required this.section,   // e.g. 'picks-for-you', 'fresh-reads'
    required this.title,     // Display title for the AppBar
    this.isClassics = false, // true → show "EXCERPT:" label style
  });

  final String tab;
  final String section;
  final String title;
  final bool isClassics;

  @override
  State<GenreSectionMoreScreen> createState() => _GenreSectionMoreScreenState();
}

class _GenreSectionMoreScreenState extends State<GenreSectionMoreScreen> {
  final List<Map> _stories = [];
  bool _loading = false;
  bool _hasNext = true;
  int _page = 1;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
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
    final res = await ApiService.getGenreSection(
      tab: widget.tab,
      section: widget.section,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map;
        _stories.addAll((data['results'] as List? ?? []).cast<Map>());
        _hasNext = data['has_next'] == true;
        _page++;
      } else {
        _hasNext = false;
      }
    });
  }

  String _coverUrl(Map story) {
    final c = story['cover_image']?.toString() ?? '';
    if (c.startsWith('http')) return c;
    if (c.isNotEmpty) return 'http://10.0.2.2:8000$c';
    return '';
  }

  String _formatViews(dynamic v) {
    final n = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
    final cardBg = isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
    final txt    = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub    = isDark ? Colors.grey[400]! : Colors.grey[600]!;

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
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: txt,
              fontFamily: kFontFamily,
            ),
          ),
        ),
        body: RefreshIndicator(
          color: depperBlue,
          onRefresh: () async {
            setState(() { _stories.clear(); _hasNext = true; _page = 1; });
            await _fetch();
          },
          child: _stories.isEmpty && _loading
              ? _shimmerList(isDark)
              : _stories.isEmpty
                  ? const Center(child: Text('Nothing here yet'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: _stories.length + (_loading ? 3 : 0),
                      itemBuilder: (_, idx) {
                        if (idx >= _stories.length) return _shimmerTile(isDark);
                        return widget.isClassics
                            ? _classicsTile(_stories[idx], cardBg, txt, sub)
                            : _storyTile(_stories[idx], cardBg, txt, sub);
                      },
                    ),
        ),
      ),
    );
  }

  // Standard tile: cover + title + desc + views + tag
  Widget _storyTile(Map story, Color cardBg, Color txt, Color sub) {
    final tags     = (story['tags'] as List? ?? []);
    final firstTag = tags.isNotEmpty
        ? (tags.first is Map ? tags.first['name'] : tags.first.toString())
        : '';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => StoryDetailScreen(slug: story['slug'], heroTag: 'hero-genremore-${story['slug']}')),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Hero(
                tag: 'hero-genremore-${story['slug']}',
                child: CustomImageView(
                  imagePath: _coverUrl(story),
                  width: 90, height: 126, fit: BoxFit.cover,
                  placeHolder: 'assets/images/novelux_placeholder_transcpr.jpg',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: txt, fontFamily: kFontFamily)),
                  const SizedBox(height: 6),
                  Text(story['description'] ?? story['synopsis'] ?? '',
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 8, color: sub, fontFamily: kFontFamily)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('${_formatViews(story['total_views'] ?? 0)} Views',
                      style: TextStyle(fontSize: 10, color: depperBlue, fontWeight: FontWeight.w600, fontFamily: kFontFamily)),
                    if (firstTag.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sub.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(firstTag, style: TextStyle(fontSize: 11, color: sub, fontFamily: kFontFamily)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Classics tile: cover + title + EXCERPT: + text + views + tag
  Widget _classicsTile(Map story, Color cardBg, Color txt, Color sub) {
    final tags     = (story['tags'] as List? ?? []);
    final firstTag = tags.isNotEmpty
        ? (tags.first is Map ? tags.first['name'] : tags.first.toString())
        : '';
    final desc = story['description'] ?? story['synopsis'] ?? '';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => StoryDetailScreen(slug: story['slug'], heroTag: 'hero-classicsmore-${story['slug']}')),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Hero(
                tag: 'hero-classicsmore-${story['slug']}',
                child: CustomImageView(
                  imagePath: _coverUrl(story),
                  width: 100, height: 140, fit: BoxFit.cover,
                  placeHolder: 'assets/images/novelux_placeholder_transcpr.jpg',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: txt, fontFamily: kFontFamily)),
                  const SizedBox(height: 8),
                  if (desc.isNotEmpty) ...[
                    Text('EXCERPT:', style: TextStyle(fontSize: 11, color: sub.withOpacity(0.7),
                      fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: kFontFamily)),
                    const SizedBox(height: 3),
                    Text(desc, maxLines: 4, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: sub, fontFamily: kFontFamily)),
                    const SizedBox(height: 8),
                  ],
                  Row(children: [
                    Text('${_formatViews(story['total_views'] ?? 0)} Views',
                      style: TextStyle(fontSize: 12, color: depperBlue, fontWeight: FontWeight.w600, fontFamily: kFontFamily)),
                    if (firstTag.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sub.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(firstTag, style: TextStyle(fontSize: 11, color: sub, fontFamily: kFontFamily)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerList(bool isDark) => ListView.builder(
    padding: const EdgeInsets.only(top: 8),
    itemCount: 8,
    itemBuilder: (_, __) => _shimmerTile(isDark),
  );

  Widget _shimmerTile(bool isDark) {
    final base = isDark ? const Color(0xFF2a2a2a) : Colors.grey[300]!;
    final hi   = isDark ? const Color(0xFF3a3a3a) : Colors.grey[100]!;
    return Shimmer.fromColors(
      baseColor: base, highlightColor: hi,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 110,
        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
