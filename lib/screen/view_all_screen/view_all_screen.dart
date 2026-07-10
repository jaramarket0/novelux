// File: lib/screen/explore/view_all_screen.dart
//
// List layout (horizontal card) with lazy-loading via ScrollController.
// Controller unchanged — only the visual layer is swapped from grid → list.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/ad_service.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION TYPE
// ══════════════════════════════════════════════════════════════════════════════

enum SectionType {
  trending,
  featured,
  editorsPick,
  forYou,
  worldFamous,
  completed,
  freeDownload,
  africanFolktale,
  bestNovel,
  newArrivals,
  recommended,
  freeDiscount,
  shortStories,
  rankings,
}

extension SectionTypeX on SectionType {
  String get defaultTitle {
    switch (this) {
      case SectionType.trending:
        return 'Trending Now';
      case SectionType.featured:
        return 'Featured';
      case SectionType.editorsPick:
        return "Editor's Pick";
      case SectionType.forYou:
        return 'For You';
      case SectionType.worldFamous:
        return 'World Famous';
      case SectionType.completed:
        return 'Completed Stories';
      case SectionType.freeDownload:
        return 'Free to Download';
      case SectionType.africanFolktale:
        return 'African Folktales';
      case SectionType.bestNovel:
        return 'Best Novels';
      case SectionType.newArrivals:
        return 'New Arrivals';
      case SectionType.recommended:
        return 'Recommended For You';
      case SectionType.freeDiscount:
        return 'Free & Discount';
      case SectionType.shortStories:
        return 'Short Stories';
      case SectionType.rankings:
        return 'Rankings';
    }
  }

  Future<Map<String, dynamic>> fetch({
    required int page,
    required int pageSize,
    String? genre,
    String? gender,
    String? sortBy,
    List<String>? genres,
  }) {
    switch (this) {
      case SectionType.trending:
        return ApiService.getTrending(page: page, pageSize: pageSize);
      case SectionType.featured:
        return ApiService.getFeatured(page: page, pageSize: pageSize);
      case SectionType.editorsPick:
        return ApiService.getEditorsPick(page: page, pageSize: pageSize);
      case SectionType.forYou:
        if (genres != null && genres.isNotEmpty) {
          return ApiService.getPersonalisedFeed(
            genres: genres,
            gender: gender ?? '',
            tab: genre,
            page: page,
            pageSize: pageSize,
          );
        }
        return ApiService.getStories(
          genre: genre,
          page: page,
          pageSize: pageSize,
        );
      case SectionType.worldFamous:
        return ApiService.getWorldFamous(page: page, pageSize: pageSize);
      case SectionType.completed:
        return ApiService.getCompletedStories(page: page, pageSize: pageSize);
      case SectionType.freeDownload:
        return ApiService.getFreeDownLoad(page: page, pageSize: pageSize);
      case SectionType.africanFolktale:
        return ApiService.getAfricanFolkTale(page: page, pageSize: pageSize);
      case SectionType.bestNovel:
        return ApiService.getBestNovels(
          page: page,
          pageSize: pageSize,
          sortBy: sortBy ?? 'views',
        );
      case SectionType.newArrivals:
        return ApiService.getNewArrivals(page: page, pageSize: pageSize);
      case SectionType.recommended:
        return ApiService.getRecommended(page: page, pageSize: pageSize);
      case SectionType.freeDiscount:
        return ApiService.getFreeDiscount(page: page, pageSize: pageSize);
      case SectionType.shortStories:
        return ApiService.getShortStories(page: page, pageSize: pageSize);
      case SectionType.rankings:
        return ApiService.getRankings(period: sortBy ?? 'all-time', pageSize: pageSize);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CONTROLLER  (unchanged from your active code)
// ══════════════════════════════════════════════════════════════════════════════

class ViewAllController extends GetxController {
  final SectionType section;
  final String? genre;
  final String? gender;
  final List<String>? genres;
  String? sortBy;

  ViewAllController({
    required this.section,
    this.genre,
    this.gender,
    this.genres,
    this.sortBy,
  });

  Future<void> changeSortBy(String newSort) {
    sortBy = newSort;
    return _loadFirstPage();
  }

  static const _pageSize = 10;

  final RxList stories = [].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString error = ''.obs;
  final RxInt totalCount = 0.obs;

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    isLoading.value = true;
    error.value = '';
    _page = 1;
    hasMore.value = true;

    try {
      final res = await section.fetch(
        page: 1,
        pageSize: _pageSize,
        genre: genre,
        gender: gender,
        genres: genres,
        sortBy: sortBy,
      );
      isLoading.value = false;
      if (res['success'] == true) {
        final data = res['data'];
        stories.value = _extract(data);
        hasMore.value = _next(data);
        totalCount.value = _count(data);
        if (hasMore.value) _page = 2;
      } else {
        error.value = res['error']?.toString() ?? 'Could not load stories.';
      }
    } catch (e) {
      isLoading.value = false;
      error.value = 'Network error. Please try again.';
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final res = await section.fetch(
        page: _page,
        pageSize: _pageSize,
        genre: genre,
        gender: gender,
        genres: genres,
        sortBy: sortBy,
      );
      if (res['success'] == true) {
        final data = res['data'];
        stories.addAll(_extract(data));
        hasMore.value = _next(data);
        if (hasMore.value) _page++;
      }
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refresh() => _loadFirstPage();

  static List _extract(dynamic d) =>
      d is List ? d : ((d as Map?)?['results'] ?? []);

  // Supports both custom `has_next` (bool) and standard DRF `next` (URL string).
  static bool _next(dynamic d) {
    if (d is! Map) return false;
    if (d['has_next'] == true) return true;
    final next = d['next'];
    return next != null && next.toString().isNotEmpty;
  }

  static int _count(dynamic d) =>
      d is Map ? (d['count'] as num?)?.toInt() ?? 0 : 0;

  String coverUrl(Map s) {
    final c = s['cover_image'];
    if (c == null || c.toString().isEmpty) return '';
    if (c.toString().startsWith('http')) return c.toString();
    return 'http://10.0.2.2:8000$c';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class ViewAllScreen extends StatefulWidget {
  final SectionType section;
  final String? title;
  final String? genre;
  final String? gender;
  final List<String>? genres;
  final String? sortBy;

  const ViewAllScreen({
    super.key,
    required this.section,
    this.title,
    this.genre,
    this.gender,
    this.genres,
    this.sortBy,
  });

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  late final ViewAllController ctrl;
  final _scrollCtrl = ScrollController();

  static const _sortKeys = [
    'views',
    'comments',
    'ratings',
    'topBuzz',
    'tips',
    'status',
  ];
  static const _sortLabels = [
    'Most Read',
    'Most Engaging',
    'Top Rated',
    'Top Buzz',
    'Top Earners',
    'Top Completed',
  ];

  int _sortIdx = 0;

  @override
  void initState() {
    super.initState();
    final initialSort = widget.sortBy ?? 'views';
    final idx = _sortKeys.indexOf(initialSort);
    _sortIdx = idx < 0 ? 0 : idx;
    ctrl = Get.put(
      ViewAllController(
        section: widget.section,
        genre: widget.genre,
        gender: widget.gender,
        genres: widget.genres,
        sortBy: widget.sortBy,
      ),
    );
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    Get.delete<ViewAllController>();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    // Trigger load when within 400 px of the bottom (fires before sentinel).
    if (_scrollCtrl.position.extentAfter < 400) ctrl.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = widget.title ?? widget.section.defaultTitle;

    final theme = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
        final onBg =
            !isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
        final cardBg =
            isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;

        return Scaffold(
          backgroundColor: bg,
          body: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ─────────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: bg,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, color: onBg, size: 28),
                  onPressed: () => Get.back(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      screenTitle,
                      style: TextStyle(
                        color: txt,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Obx(
                      () =>
                          ctrl.totalCount.value > 0
                              ? Text(
                                '${ctrl.totalCount.value}+ stories',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: onBg, size: 20),
                    onPressed: ctrl.refresh,
                    tooltip: 'Refresh',
                  ),
                ],
              ),

              // ── Sort tabs (Best Novels only) ────────────────────────────────
              if (widget.section == SectionType.bestNovel)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      itemCount: _sortLabels.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final selected = i == _sortIdx;
                        return GestureDetector(
                          onTap: () {
                            if (_sortIdx == i) return;
                            setState(() => _sortIdx = i);
                            ctrl.changeSortBy(_sortKeys[i]);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? onBg : cardBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _sortLabels[i],
                              style: TextStyle(
                                color: selected ? bg : sub,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // ── Body ────────────────────────────────────────────────────────
              Obx(() {
                // First-load skeleton
                if (ctrl.isLoading.value) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const _SkeletonListCard(),
                        childCount: 6,
                      ),
                    ),
                  );
                }

                // Error state
                if (ctrl.error.value.isNotEmpty && ctrl.stories.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: cardBg, size: 52),
                          const SizedBox(height: 16),
                          Text(
                            ctrl.error.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: sub, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: depperBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: ctrl.refresh,
                            child: Text(
                              'Try again',
                              style: TextStyle(color: txt),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Empty state
                if (ctrl.stories.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            color: Colors.grey[700],
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No stories found',
                            style: TextStyle(color: txt, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Story list
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      // Every 11th slot (indices 10, 21, 32…) is a native ad.
                      if ((i + 1) % 11 == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: NativeAdWidget(height: 200),
                        );
                      }
                      final si = i - (i ~/ 11);
                      if (si >= ctrl.stories.length) return null;
                      // Sentinel: when last story is visible, fetch next page.
                      if (si == ctrl.stories.length - 1 && ctrl.hasMore.value) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => ctrl.loadMore(),
                        );
                      }
                      final story = ctrl.stories[si] as Map;
                      return _StoryListCard(
                        story: story,
                        coverUrl: ctrl.coverUrl(story),
                      );
                    }, childCount: ctrl.stories.length + (ctrl.stories.length ~/ 10)),
                  ),
                );
              }),

              // ── Load-more / end indicator ────────────────────────────────────
              Obx(() {
                if (ctrl.isLoadingMore.value) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: depperBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }

                if (!ctrl.hasMore.value && ctrl.stories.isNotEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 6),
                            Text(
                              "You've seen all ${ctrl.totalCount.value} stories",
                              style: TextStyle(color: txt, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox(height: 40));
              }),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STORY LIST CARD  (horizontal layout from the commented code)
// ══════════════════════════════════════════════════════════════════════════════

class _StoryListCard extends StatelessWidget {
  final Map story;
  final String coverUrl;

  const _StoryListCard({required this.story, required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final title = story['title']?.toString() ?? '';
    final desc = story['description']?.toString() ?? '';
    final rating =
        double.tryParse(story['average_rating']?.toString() ?? '0') ?? 0.0;
    final views = story['total_views'] ?? 0;
    final chaps = story['total_chapters'] ?? 0;
    final tags = (story['tags'] as List? ?? []);
    // target_word_count arrives as e.g. "50,000 - 80,000" or "120,000+".
    // Parse the lower bound by stripping commas and taking text before " - " or "+".
    final rawWordCount = story['target_word_count']?.toString() ?? '';
    final lowerBound = int.tryParse(
      rawWordCount.replaceAll(',', '').split(RegExp(r'[\-\+]'))[0].trim(),
    );
    final isShort = lowerBound != null && lowerBound < 80000;
    final isCompleted =
        story['status']?.toString().toLowerCase() == 'completed';

    final theme = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
        final onBg =
            !isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
        final cardBg =
            isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;

        return GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => StoryDetailScreen(slug: story['slug'], heroTag: 'hero-viewall-${story['slug']}'),
                ),
              ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover ──────────────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 85,
                    height: 115,
                    child:
                        coverUrl.isNotEmpty
                            ? Hero(
                              tag: 'hero-viewall-${story['slug']}',
                              child: CustomImageView(
                                imagePath: coverUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                            :
                            // Container(
                            //   color: const Color(0xFF2a2a2a),
                            //   child: const Center(
                            //     child: Icon(
                            //       Icons.book,
                            //       color: Colors.grey,
                            //       size: 30,
                            //     ),
                            //   ),
                            // ),
                            CustomImageView(
                      imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Info ───────────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: txt,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Description
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sub,
                          fontSize: 12,
                          fontFamily: kFontFamily,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Stats row
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFD700),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                            style: TextStyle(color: sub, fontSize: 11),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.visibility_outlined, color: sub, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            _fmt(views),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.menu_book_outlined,
                            color: Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$chaps ch',
                            style: TextStyle(color: sub, fontSize: 11),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Tags row: status badges + genre tags
                      if (isShort || isCompleted || tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (isCompleted)
                              _badge(
                                'Completed',
                                const Color(0xFF2E7D32),
                                const Color(0xFFE8F5E9),
                              ),
                            if (isShort)
                              _badge(
                                'Short',
                                const Color(0xFF1565C0),
                                const Color(0xFFE3F2FD),
                              ),
                            ...tags.take(2).map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: depperBlue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t['name'] ?? '',
                                  style: TextStyle(
                                    color: depperBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
        );
      },
    );
  }

  Widget _badge(String label, Color textColor, Color bgColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  SKELETON LIST CARD
// ══════════════════════════════════════════════════════════════════════════════

class _SkeletonListCard extends StatefulWidget {
  const _SkeletonListCard();

  @override
  State<_SkeletonListCard> createState() => _SkeletonListCardState();
}

class _SkeletonListCardState extends State<_SkeletonListCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _a = Tween(begin: 0.3, end: 0.85).animate(_ac);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder:
          (_, __) => Opacity(
            opacity: _a.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover placeholder
                  Container(
                    width: 85,
                    height: 115,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2a2a2a),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 13,
                          width: double.infinity,
                          color: const Color(0xFF2a2a2a),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 11,
                          width: double.infinity,
                          color: const Color(0xFF2a2a2a),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 11,
                          width: 160,
                          color: const Color(0xFF2a2a2a),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 10,
                          width: 120,
                          color: const Color(0xFF2a2a2a),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              height: 20,
                              width: 50,
                              color: const Color(0xFF2a2a2a),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              height: 20,
                              width: 50,
                              color: const Color(0xFF2a2a2a),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _fmt(dynamic n) {
  final v = int.tryParse(n?.toString() ?? '0') ?? 0;
  if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
  if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(1)}K';
  return '$v';
}
