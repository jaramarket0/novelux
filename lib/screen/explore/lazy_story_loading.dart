// ══════════════════════════════════════════════════════════════════════════════
//  Reusable lazy-loading story row
//  File: lib/widgets/lazy_story_list.dart
//
//  Drop this into any horizontal story section in the explore screen.
//  It auto-triggers loadMore when the user scrolls to 80% of the list.
//
//  Usage:
//    LazyStoryRow(
//      stories:        ctrl.trending,
//      isLoading:      ctrl.isLoadingTrending,
//      isLoadingMore:  ctrl.isLoadingMoreTrending,
//      hasMore:        ctrl.hasMoreTrending,
//      onLoadMore:     ctrl.loadMoreTrending,
//      getCoverUrl:    ctrl.getCoverUrl,
//    )
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  HORIZONTAL LAZY ROW  (used in explore sections)
// ══════════════════════════════════════════════════════════════════════════════
class LazyStoryRow extends StatefulWidget {
  final RxList            stories;
  final RxBool            isLoading;
  final RxBool            isLoadingMore;
  final RxBool            hasMore;
  final VoidCallback      onLoadMore;
  final String Function(Map?) getCoverUrl;
  final double            cardWidth;
  final double            cardHeight;

  const LazyStoryRow({
    super.key,
    required this.stories,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.getCoverUrl,
    this.cardWidth  = 110,
    this.cardHeight = 158,
  });

  @override
  State<LazyStoryRow> createState() => _LazyStoryRowState();
}

class _LazyStoryRowState extends State<LazyStoryRow> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    // Trigger load when user reaches 80% of the scrollable width
    if (pos.pixels >= pos.maxScrollExtent * 0.80) {
      if (widget.hasMore.value && !widget.isLoadingMore.value) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── First-load skeleton ───────────────────────────────────────────────
      if (widget.isLoading.value && widget.stories.isEmpty) {
        return SizedBox(
          height: widget.cardHeight + 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => _SkeletonCard(
                width: widget.cardWidth, height: widget.cardHeight),
          ),
        );
      }

      if (widget.stories.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: widget.cardHeight + 44,
        child: ListView.builder(
          controller:     _scrollCtrl,
          scrollDirection: Axis.horizontal,
          padding:        const EdgeInsets.symmetric(horizontal: 16),
          // +1 for the loading indicator at the end
          itemCount: widget.stories.length +
              (widget.isLoadingMore.value ? 1 : 0),
          itemBuilder: (ctx, i) {
            // ── Loading indicator at end ──────────────────────────────────
            if (i == widget.stories.length) {
              return _LoadingMoreCard(
                  width: widget.cardWidth, height: widget.cardHeight);
            }

            final story = widget.stories[i] as Map;
            return _StoryCard(
              story:      story,
              coverUrl:   widget.getCoverUrl(story),
              cardWidth:  widget.cardWidth,
              cardHeight: widget.cardHeight,
            );
          },
        ),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  VERTICAL LAZY LIST  (used for "For You" section — grid style)
// ══════════════════════════════════════════════════════════════════════════════
class LazyStoryGrid extends StatefulWidget {
  final RxList            stories;
  final RxBool            isLoading;
  final RxBool            isLoadingMore;
  final RxBool            hasMore;
  final VoidCallback      onLoadMore;
  final String Function(Map?) getCoverUrl;

  const LazyStoryGrid({
    super.key,
    required this.stories,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.getCoverUrl,
  });

  @override
  State<LazyStoryGrid> createState() => _LazyStoryGridState();
}

class _LazyStoryGridState extends State<LazyStoryGrid> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.80) {
      if (widget.hasMore.value && !widget.isLoadingMore.value) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.isLoading.value && widget.stories.isEmpty) {
        return GridView.builder(
          shrinkWrap:  true,
          physics:     const NeverScrollableScrollPhysics(),
          padding:     const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   2,
            crossAxisSpacing: 12,
            mainAxisSpacing:  16,
            childAspectRatio: 0.62,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const _SkeletonCard(
              width: double.infinity, height: 180),
        );
      }

      if (widget.stories.isEmpty) return const SizedBox.shrink();

      return Column(children: [
        GridView.builder(
          controller:  _scrollCtrl,
          shrinkWrap:  true,
          physics:     const NeverScrollableScrollPhysics(),
          padding:     const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   2,
            crossAxisSpacing: 12,
            mainAxisSpacing:  16,
            childAspectRatio: 0.62,
          ),
          itemCount: widget.stories.length,
          itemBuilder: (ctx, i) {
            final story = widget.stories[i] as Map;
            return _StoryCard(
              story:      story,
              coverUrl:   widget.getCoverUrl(story),
              cardWidth:  double.infinity,
              cardHeight: 180,
              showFullInfo: true,
            );
          },
        ),

        // Load more button / spinner
        Obx(() {
          if (widget.isLoadingMore.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(
                  color: depperBlue, strokeWidth: 2)),
            );
          }
          if (widget.hasMore.value) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: widget.onLoadMore,
                  icon: const Icon(Icons.expand_more,
                      color: depperBlue, size: 18),
                  label: const Text('Load more',
                      style: TextStyle(color: depperBlue)),
                ),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text("You've seen it all 🎉",
                style: TextStyle(color: Colors.grey, fontSize: 12))),
          );
        }),
      ]);
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STORY CARD
// ══════════════════════════════════════════════════════════════════════════════
class _StoryCard extends StatelessWidget {
  final Map    story;
  final String coverUrl;
  final double cardWidth;
  final double cardHeight;
  final bool   showFullInfo;

  const _StoryCard({
    required this.story,
    required this.coverUrl,
    required this.cardWidth,
    required this.cardHeight,
    this.showFullInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final title  = story['title']?.toString() ?? '';
    final rating = double.tryParse(
        story['average_rating']?.toString() ?? '0') ?? 0.0;
    final views  = story['total_views'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(
        builder: (_) => StoryDetailScreen(slug: story['slug']))),
      child: SizedBox(
        width: cardWidth == double.infinity ? null : cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width:  cardWidth == double.infinity ? double.infinity : cardWidth,
                height: cardHeight,
                child: coverUrl.isNotEmpty
                    ? CustomImageView(imagePath: coverUrl, fit: BoxFit.cover)
                    : 
                      // Container(color: const Color(0xFF2a2a2a),
                      //     child: const Center(child: Icon(Icons.book,
                      //         color: Colors.grey, size: 28))),
                      CustomImageView(
                      imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
              ),
            ),
            const SizedBox(height: 6),

            // Title
            Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3)),

            if (showFullInfo) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 11),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 10)),
                const SizedBox(width: 6),
                const Icon(Icons.visibility_outlined,
                    color: Colors.grey, size: 10),
                const SizedBox(width: 2),
                Text(_fmtNum(views),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 10)),
              ]),
            ] else ...[
              const SizedBox(height: 2),
              Text(_fmtNum(views) + ' reads',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Skeleton card (shimmer placeholder) ───────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  final double width;
  final double height;
  const _SkeletonCard({required this.width, required this.height});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.9).animate(_ac);
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: SizedBox(
          width: widget.width == double.infinity ? null : widget.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width:  widget.width == double.infinity
                    ? double.infinity : widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 6),
              Container(height: 10, width: 80,
                  color: const Color(0xFF2a2a2a)),
              const SizedBox(height: 4),
              Container(height: 8,  width: 50,
                  color: const Color(0xFF2a2a2a)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading more indicator ────────────────────────────────────────────────────
class _LoadingMoreCard extends StatelessWidget {
  final double width;
  final double height;
  const _LoadingMoreCard({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height + 44,
    child: const Center(
      child: SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(
            color: depperBlue, strokeWidth: 2),
      ),
    ),
  );
}

// ── Number formatter ──────────────────────────────────────────────────────────
String _fmtNum(dynamic n) {
  final v = int.tryParse(n?.toString() ?? '0') ?? 0;
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}