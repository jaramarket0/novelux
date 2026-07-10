import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';

class AuthorProfileScreen extends StatefulWidget {
  final String username;
  const AuthorProfileScreen({super.key, required this.username});

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final resp = await ApiService.getPublicProfile(widget.username);
      if (resp['success'] == true) {
        final data = resp['data'] as Map<String, dynamic>;
        if (mounted) setState(() { _profile = data; _loading = false; });
      } else {
        if (mounted) setState(() { _error = resp['error']?.toString() ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg   = isDark ? const Color(0xFF12121a) : const Color(0xFFF5F5F7);
        final card = isDark ? const Color(0xFF1e1e28) : Colors.white;
        final txt  = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub  = isDark ? Colors.grey[400]! : Colors.grey[600]!;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: txt),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator(color: depperBlue))
              : _error != null
                  ? Center(child: Text('Failed to load profile', style: TextStyle(color: sub)))
                  : _buildBody(context, isDark, bg, card, txt, sub),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Color bg,
    Color card,
    Color txt,
    Color sub,
  ) {
    final profile = _profile!;
    final stats   = profile['stats'] as Map? ?? {};
    final stories = (profile['stories'] as List?) ?? [];
    final authorProfile = profile['author_profile'] as Map? ?? {};

    final avatarUrl   = profile['avatar']?.toString() ?? '';
    final username    = profile['username']?.toString() ?? '';
    final bio         = profile['bio']?.toString() ?? '';
    final role        = profile['role']?.toString() ?? '';
    final worksCount  = (stats['works_count'] as num?)?.toInt() ?? 0;
    final wordCount   = (stats['total_word_count'] as num?)?.toInt() ?? 0;
    final penName     = authorProfile['pen_name']?.toString() ?? '';
    final displayName = penName.isNotEmpty ? penName : username;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name
                Row(
                  children: [
                    _Avatar(url: avatarUrl, name: displayName, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              color: txt,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (role.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: depperBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  color: depperBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(bio, style: TextStyle(color: sub, fontSize: 13, height: 1.5)),
                ],

                const SizedBox(height: 20),

                // Stats card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCell(
                            value: _fmtCount(wordCount),
                            label: 'Word Count',
                            txt: txt,
                            sub: sub,
                          ),
                        ),
                        VerticalDivider(
                          color: sub.withOpacity(0.2),
                          thickness: 1,
                          indent: 8,
                          endIndent: 8,
                        ),
                        Expanded(
                          child: _StatCell(
                            value: worksCount.toString(),
                            label: 'Works',
                            txt: txt,
                            sub: sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Novel Collection header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Novel Collection',
              style: TextStyle(
                color: txt,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        if (stories.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No published stories yet.',
                style: TextStyle(color: sub, fontSize: 13),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final s = stories[i] as Map;
                return _StoryTile(story: s, card: card, txt: txt, sub: sub);
              },
              childCount: stories.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final double size;
  const _Avatar({required this.url, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    if (url.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size * 2,
          height: size * 2,
          child: CustomImageView(imagePath: url, fit: BoxFit.cover),
        ),
      );
    }
    return CircleAvatar(
      radius: size,
      backgroundColor: depperBlue.withOpacity(0.18),
      child: Text(
        initial,
        style: TextStyle(
          color: depperBlue,
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color txt;
  final Color sub;
  const _StatCell({
    required this.value,
    required this.label,
    required this.txt,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: txt,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: sub, fontSize: 12)),
      ],
    );
  }
}

class _StoryTile extends StatelessWidget {
  final Map story;
  final Color card;
  final Color txt;
  final Color sub;
  const _StoryTile({
    required this.story,
    required this.card,
    required this.txt,
    required this.sub,
  });

  String _fmtViews(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M Views';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K Views';
    return '$n Views';
  }

  @override
  Widget build(BuildContext context) {
    final slug       = story['slug']?.toString() ?? '';
    final title      = story['title']?.toString() ?? '';
    final synopsis   = story['synopsis']?.toString() ?? '';
    final cover      = story['cover_image']?.toString() ?? '';
    final views      = (story['total_views'] as num?)?.toInt() ?? 0;
    final tags       = (story['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];
    final genre      = story['genre']?.toString() ?? '';
    final firstTag   = tags.isNotEmpty ? tags.first : genre;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoryDetailScreen(slug: slug)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 100,
                child: cover.isNotEmpty
                    ? CustomImageView(imagePath: cover, fit: BoxFit.cover)
                    : Container(color: depperBlue.withOpacity(0.15)),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: txt,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (synopsis.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      synopsis,
                      style: TextStyle(color: sub, fontSize: 12, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _fmtViews(views),
                        style: TextStyle(
                          color: depperBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (firstTag.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: sub.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            firstTag,
                            style: TextStyle(color: sub, fontSize: 11),
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
}
