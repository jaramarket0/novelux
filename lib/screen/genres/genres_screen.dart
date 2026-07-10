import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/screen/explore/search.dart';
import 'package:novelux/screen/genres/controller/genres_controller.dart';
import 'package:novelux/widgets/custom_image_view.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  late final GenresController ctrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(GenresController());
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
    if (_scrollCtrl.position.extentAfter < 400) ctrl.loadMore();
  }

  @override
  Widget build(BuildContext context) {
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: bg,
            elevation: 0,
            title: Text(
              'Genres',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: kFontFamily,
                color: txt,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: txt),
                onPressed: () {
                  Get.to(() => const SearchScreen());
                },
              ),
            ],
          ),
          body: Container(
            color: bg,
            child: Obx(() {
              // Initial genres load
              if (ctrl.genres.isEmpty && ctrl.isLoading.value) {
                return Center(
                  child: Container(
                    height: 130,
                    width: 130,
                    decoration: BoxDecoration(
                      color: divClr,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SpinKitWanderingCubes(
                      size: 30,
                      itemBuilder: (context, index) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: index.isEven ? depperBlue : Colors.white,
                            shape: BoxShape.rectangle,
                          ),
                        );
                      },
                      duration: const Duration(milliseconds: 1200),
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  // ── Left sidebar: genres ─────────────────────────────────────
                  SizedBox(
                    width: 95,
                    child: ListView.builder(
                      itemCount: ctrl.genres.length,
                      itemBuilder: (_, i) {
                        final genre = ctrl.genres[i];
                        final isSelected = ctrl.selectedIndex.value == i;
                        return GestureDetector(
                          onTap:
                              () =>
                                  ctrl.selectGenre(i, genre['slug'].toString()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color:
                                      isSelected
                                          ? depperBlue
                                          : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              genre['name'] ?? '',
                              style: TextStyle(
                                color: isSelected ? depperBlue : sub,
                                fontSize: isSelected ? 12 : 10,
                                fontFamily: kFontFamily,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Right: stories for selected genre ────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: divClr,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                      child: Obx(() {
                        // First-page load for a genre
                        if (ctrl.isLoading.value) {
                          return Center(
                            child: Container(
                              height: 130,
                              width: 130,
                              decoration: BoxDecoration(
                                color: bg.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SpinKitWanderingCubes(
                                size: 30,
                                itemBuilder: (context, index) {
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      color:
                                          index.isEven
                                              ? depperBlue
                                              : Colors.white,
                                      shape: BoxShape.rectangle,
                                    ),
                                  );
                                },
                                duration: const Duration(milliseconds: 1200),
                              ),
                            ),
                          );
                        }

                        if (ctrl.stories.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  color: Colors.grey[700],
                                  size: 50,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No stories in this genre yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: kFontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // +1 for the load-more / end-of-list footer
                        final itemCount = ctrl.stories.length + 1;

                        return ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(14),
                          itemCount: itemCount,
                          itemBuilder: (_, i) {
                            // Footer
                            if (i == ctrl.stories.length) {
                              return Obx(() {
                                if (ctrl.isLoadingMore.value) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: depperBlue,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                if (!ctrl.hasMore.value) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "You've seen all stories",
                                        style: TextStyle(
                                          color: sub,
                                          fontSize: 12,
                                          fontFamily: kFontFamily,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox(height: 20);
                              });
                            }

                            final story = ctrl.stories[i];
                            final coverUrl = ctrl.getCoverUrl(story);
                            final tags = (story['tags'] as List? ?? []);

                            return GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder:
                                          (_) => StoryDetailScreen(
                                            slug: story['slug'],
                                            heroTag: 'hero-genres-${story['slug']}',
                                          ),
                                    ),
                                  ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cover
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 80,
                                        height: 100,
                                        child:
                                            coverUrl.isNotEmpty
                                                ? Hero(
                                                  tag: 'hero-genres-${story['slug']}',
                                                  child: CustomImageView(
                                                    imagePath: coverUrl,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                                : CustomImageView(
                                                  imagePath:
                                                      'assets/images/novelux_placeholder_transcpr.jpg',
                                                  width: 60,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                        // _placeholder(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            story['title'] ?? '',
                                            style: TextStyle(
                                              color: txt,
                                              fontFamily: kFontFamily,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            story['description'] ?? '',
                                            style: TextStyle(
                                              color: sub,
                                              fontFamily: kFontFamily,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                '${double.tryParse(story['average_rating'].toString())?.toStringAsFixed(1) ?? '0.0'}',
                                                style: TextStyle(
                                                  color: sub,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: kFontFamily,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                Icons.star,
                                                color: Color(0xFFFFD700),
                                                size: 12,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '${story['total_views'] ?? 0} views',
                                                style: TextStyle(
                                                  color: sub,
                                                  fontFamily: kFontFamily,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (tags.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: depperBlue.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                tags[0]['name'] ?? '',
                                                style: TextStyle(
                                                  color: depperBlue,
                                                  fontSize: 10,
                                                  fontFamily: kFontFamily,
                                                  fontWeight: FontWeight.w600,
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
                          },
                        );
                      }),
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

  Widget _placeholder() => Container(
    color: const Color(0xFF3a3a3a),
    child: const Center(child: Icon(Icons.book, color: Colors.grey, size: 28)),
  );
}
