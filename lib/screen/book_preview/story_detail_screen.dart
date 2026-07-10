import 'dart:developer' as myLog;
import 'package:flutter/cupertino.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/local_storage.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/download_screen/controller/download_controller.dart';
import 'package:novelux/screen/reading_interface/audio_player_screen.dart';
import 'package:novelux/screen/reading_interface/reading_interface.dart';
import 'package:novelux/screen/author/author_profile_screen.dart';
import 'package:novelux/screen/review_comment_story/reviews_and_comments_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';
import 'package:share_plus/share_plus.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════
class StoryDetailController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isLoadingChapters = false.obs;
  final RxBool isLoadingSimilar = false.obs;
  final RxBool isLoadingTippers = false.obs;

  final Rx<Map?> story = Rx<Map?>(null);
  final RxList chapters = [].obs;
  final RxList similarStories = [].obs;
  final RxList tippers = [].obs;

  final List _allSimilarStories = [];

  final RxBool isBookmarked = false.obs;
  final RxDouble avgRating = 0.0.obs;

  // ── Follow ─────────────────────────────────────────────────────────────────
  final RxBool isFollowing = false.obs;
  final RxBool isFollowLoading = false.obs;
  final RxInt followerCount = 0.obs;

  // ── Reading progress ───────────────────────────────────────────────────────
  final RxMap<int, double> chapterProgress = <int, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProgress();
  }

  // ── Load story ─────────────────────────────────────────────────────────────
  void loadStory(String slug) async {
    isLoading.value = true;
    final res = await ApiService.getStoryDetail(slug);
    isLoading.value = false;
    if (res['success']) {
      final data = res['data'];
      story.value = data;
      isBookmarked.value = data['is_bookmarked'] ?? false;
      avgRating.value =
          double.tryParse(data['average_rating']?.toString() ?? '0') ?? 0.0;

      // ── Follow state from API ────────────────────────────────────────────
      isFollowing.value = data['is_following'] ?? false;
      followerCount.value =
          int.tryParse(data['author']?['followers_count']?.toString() ?? '0') ??
          0;

      loadChapters(slug);
      loadSimilarStories(slug);
      loadTippers(slug);
    }
  }

  void loadChapters(String slug) async {
    myLog.log(
      'Loading chapters for story: $slug',
      name: 'StoryDetailController',
    );
    isLoadingChapters.value = true;
    final res = await ApiService.getChapters(slug);
    isLoadingChapters.value = false;
    if (res['success']) {
      chapters.value =
          res['data'] is List ? res['data'] : (res['data']['results'] ?? []);
    }
  }

  void loadSimilarStories(String slug) async {
    isLoadingSimilar.value = true;
    final genre = story.value?['genre'];
    final genreSlug = genre is Map ? genre['slug'] : null;
    final res =
        genreSlug != null
            ? await ApiService.getStories(genre: genreSlug.toString())
            : await ApiService.getTrending();
    isLoadingSimilar.value = false;
    if (res['success']) {
      final data = res['data'];
      final List all = data is List ? data : (data['results'] ?? []);
      _allSimilarStories
        ..clear()
        ..addAll(all.where((s) => s['slug'] != slug));
      similarStories.value = List.from(_allSimilarStories)..shuffle();
      if (similarStories.length > 10)
        similarStories.value = similarStories.sublist(0, 10);
    }
  }

  void refreshSimilarStories(String slug) {
    if (_allSimilarStories.isEmpty) return;
    final shuffled =
        List.from(_allSimilarStories)
          ..shuffle()
          ..removeWhere((s) => s['slug'] == slug);
    similarStories.value = shuffled.take(10).toList();
  }

  void loadTippers(String slug) async {
    isLoadingTippers.value = true;
    final res = await ApiService.getTopTippers(slug);
    isLoadingTippers.value = false;
    if (res['success']) {
      final data = res['data'];
      tippers.value = data is List ? data : (data['results'] ?? []);
    }
  }

  // ── Follow / Unfollow ─────────────────────────────────────────────────────
  Future<void> toggleFollow(String authorUsername) async {
    if (isFollowLoading.value) return;
    isFollowLoading.value = true;
    final wasFollowing = isFollowing.value;

    // Optimistic update immediately
    isFollowing.value = !wasFollowing;
    followerCount.value =
        wasFollowing
            ? (followerCount.value - 1).clamp(0, 999999)
            : followerCount.value + 1;

    final res =
        wasFollowing
            ? await ApiService.unfollowUser(authorUsername)
            : await ApiService.followUser(authorUsername);

    isFollowLoading.value = false;
    myLog.log(res.toString(), name: 'FollowToggleResponse');
    if (!res['success']) {
      // Revert on failure
      isFollowing.value = wasFollowing;
      followerCount.value =
          wasFollowing
              ? followerCount.value + 1
              : (followerCount.value - 1).clamp(0, 999999);
      AppAlert.error(res['error'] ?? 'Could not update follow');
    }
  }

  // ── Bookmark ──────────────────────────────────────────────────────────────
  Future<void> toggleBookmark(String slug) async {
    if (isBookmarked.value) {
      await ApiService.removeBookmark(slug);
      isBookmarked.value = false;
    } else {
      await ApiService.bookmarkStory(slug);
      isBookmarked.value = true;
    }
  }

  // ── Reading progress ───────────────────────────────────────────────────────
  void _loadProgress() async {
    final db = Get.find<DataBase>();
    final saved = await db.getChapterProgress();
    if (saved != null) {
      chapterProgress.value = Map<int, double>.from(saved);
    }
  }

  void updateProgress(int chapterNumber, double progress) async {
    chapterProgress[chapterNumber] = progress;
    final db = Get.find<DataBase>();
    await db.saveChapterProgress(chapterProgress);
  }

  double getProgress(int chapterNumber) =>
      chapterProgress[chapterNumber] ?? 0.0;

  bool isChapterStarted(int chapterNumber) =>
      (chapterProgress[chapterNumber] ?? 0.0) > 0.01;

  bool isChapterFinished(int chapterNumber) =>
      (chapterProgress[chapterNumber] ?? 0.0) >= 0.95;

  // ── Cover URL ─────────────────────────────────────────────────────────────
  String getCoverUrl(Map? s) {
    final c = s?['cover_image'];
    if (c == null || c.toString().isEmpty) return '';
    if (c.toString().startsWith('http')) return c.toString();
    return 'https://novelux.onrender.com$c';
  }
}

// Wraps [child] in a Hero only when [tag] is non-null.
Widget _maybehero(String? tag, {required Widget child}) =>
    tag != null ? Hero(tag: tag, child: child) : child;

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class StoryDetailScreen extends StatefulWidget {
  final String slug;
  final String? heroTag;
  const StoryDetailScreen({super.key, required this.slug, this.heroTag});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  late final StoryDetailController ctrl;
  late final AuthController auth;

  @override
  void initState() {
    super.initState();
    final alreadyCached = Get.isRegistered<StoryDetailController>(
      tag: widget.slug,
    );
    ctrl = Get.put(StoryDetailController(), tag: widget.slug);
    auth = Get.find<AuthController>();
    if (!alreadyCached) ctrl.loadStory(widget.slug);
  }

  @override
  void dispose() {
    // Keep controller alive so revisiting the same story uses cached data.
    super.dispose();
  }

  String _fmtNum(dynamic n) {
    final v = int.tryParse(n?.toString() ?? '0') ?? 0;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  void _shareStory(Map story) {
    Share.share(
      'Check out "${story['title']}" on NoveluX!\n'
      'https://novelux.onrender.com/story/${story['slug']}',
    );
  }

  void _handleChapterTap(BuildContext ctx, Map ch, AuthController auth) {
    final isLocked = ch['is_locked'] ?? false;
    final isUnlocked = ch['is_unlocked'] ?? false;
    if (isLocked && !isUnlocked) {
      _showUnlockSheet(ctx, ch);
      return;
    }
    // Navigator.push(
    //   ctx,
    //   CupertinoPageRoute(
    //     builder:
    //         (_) => NovelUpReadingInterface(
    //           coverUrl: ctrl.getCoverUrl(ctrl.story.value),
    //           storySlug: widget.slug,
    //           chapterNumber: ch['chapter_number'],
    //           chapterTitle: ch['title'] ?? '',
    //         ),
    //   ),
    // );
    final story = ctrl.story.value;
    if (story == null) return;
    final author = story['author'] as Map? ?? {};
    final genre = story['genre'];
    final genreSlug = genre is Map ? genre['slug']?.toString() : null;
    Navigator.push(
      ctx,
      CupertinoPageRoute(
        builder:
            (_) => NovelUpReadingInterface(
              coverUrl: ctrl.getCoverUrl(ctrl.story.value),
              storySlug: widget.slug,
              storyTitle: story['title']?.toString() ?? '',
              chapterNumber: ch['chapter_number'],
              chapterTitle: ch['title'] ?? '',
              totalChapter: ctrl.chapters.length,
              author: author['username'],
              genreSlug: genreSlug,
              status: story['status']?.toString(),
            ),
      ),
    );
  }

  void _showUnlockSheet(BuildContext ctx, Map ch) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1e1e22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(Icons.lock_outline, color: Colors.orange, size: 40),
                const SizedBox(height: 14),
                Text(
                  ch['title'] ?? 'Locked Chapter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock with ${ch['coin_cost'] ?? 0} coins to read this chapter',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: depperBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final res = await ApiService.unlockChapter(
                        widget.slug,
                        ch['chapter_number'],
                      );
                      if (res['success']) {
                        ctrl.loadChapters(widget.slug);
                        Get.find<AuthController>().refreshCoins();
                        AppAlert.success(
                          'Unlocked! — Chapter unlocked successfully',
                        );
                      } else {
                        AppAlert.error(
                          'Insufficient coins — ${res['error'] ?? 'Not enough coins'}',
                        );
                      }
                    },
                    child: Text(
                      'Unlock — ${ch['coin_cost'] ?? 0} coins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          body: Obx(() {
            if (ctrl.isLoading.value) {
              return Center(
                child: Container(
                  color: divClr,
                  child: Center(
                    child: Container(
                      height: 130,
                      width: 130,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SpinKitWanderingCubes(
                        size: 30,
                        //color: depperBlue,
                        itemBuilder: (context, index) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: index.isEven ? depperBlue : Colors.white,
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
              );
            }
            final story = ctrl.story.value;
            if (story == null) {
              return const Center(
                child: Text(
                  'Story not found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final author = story['author'] as Map? ?? {};
            final tags = story['tags'] as List? ?? [];
            final coverUrl = ctrl.getCoverUrl(story);

            return CustomScrollView(
              slivers: [
                // ── AppBar with cover ──────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: bg,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => _shareStory(story),
                    ),
                    Obx(
                      () => IconButton(
                        icon: Icon(
                          ctrl.isBookmarked.value
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color:
                              ctrl.isBookmarked.value
                                  ? depperBlue
                                  : Colors.white,
                        ),
                        onPressed: () => ctrl.toggleBookmark(widget.slug),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _maybehero(
                          widget.heroTag,
                          child: coverUrl.isNotEmpty
                              ? CustomImageView(
                                imagePath: coverUrl,
                                fit: BoxFit.cover,
                              )
                              : CustomImageView(
                                imagePath:
                                    'assets/images/novelux_placeholder_transcpr.jpg',
                                width: 60,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, bg],
                              stops: [0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Story info ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          story['title'] ?? '',
                          style: TextStyle(
                            color: txt,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ══ AUTHOR ROW WITH FOLLOW BUTTON ══════════════════════
                        _AuthorRow(
                          author: author,
                          story: story,
                          ctrl: ctrl,
                          txt: txt,
                          sub: sub,
                        ),
                        const SizedBox(height: 16),

                        // Stats bar
                        _StatsBar(
                          story: story,
                          ctrl: ctrl,
                          slug: widget.slug,
                          context: context,
                          bg: bg,
                          sub: sub,
                          onbg: onBg,
                          cardbg: cardBg,
                          txt: txt,
                        ),
                        const SizedBox(height: 16),

                        // Tags
                        if (tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children:
                                tags
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          //depperBlue.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Text(
                                          tag['name'] ?? '',
                                          style: TextStyle(
                                            color: onBg,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Synopsis
                        Text(
                          'Synopsis',
                          style: TextStyle(
                            color: txt,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ExpandableText(
                          text: story['description'] ?? '',
                          sub: sub,
                        ),
                        const SizedBox(height: 20),

                        Divider(color: divClr),
                        const SizedBox(height: 16),

                        // Chapter header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chapters',
                              style: TextStyle(
                                color: txt,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Obx(
                              () => Text(
                                '${ctrl.story.value!['total_chapters']} chapters',
                                style: TextStyle(color: sub, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ── Chapter list ───────────────────────────────────────────────
                Obx(() {
                  if (ctrl.isLoadingChapters.value) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: depperBlue,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }
                  // return SliverList(
                  //   delegate: SliverChildBuilderDelegate((context, i) {
                  //     final ch = ctrl.chapters[i];
                  //     final isLocked = ch['is_locked'] ?? false;
                  //     final isUnlocked = ch['is_unlocked'] ?? false;
                  //     final canRead = !isLocked || isUnlocked;
                  //     final chNum = ch['chapter_number'] as int? ?? (i + 1);
                  //     return i > 2
                  //         ? Text('${ctrl.chapters.length - 3} more')
                  //         : Obx(
                  //           () => _ChapterTile(
                  //             ch: ch,
                  //             chNum: chNum,
                  //             canRead: canRead,
                  //             isLocked: isLocked,
                  //             isUnlocked: isUnlocked,
                  //             progress: ctrl.getProgress(chNum),
                  //             started: ctrl.isChapterStarted(chNum),
                  //             finished: ctrl.isChapterFinished(chNum),
                  //             onTap: () => _handleChapterTap(context, ch, auth),
                  //           ),
                  //         );
                  //   }, childCount: ctrl.chapters.length),
                  // );
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        // 1. Check if we are at the 4th position (index 3)
                        if (i == 3) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                '-- ${ctrl.story.value!['total_chapters'] - 3} more chapters --',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        // 2. Otherwise, render the standard chapter tile
                        final ch = ctrl.chapters[i];
                        final isLocked = ch['is_locked'] ?? false;
                        final isUnlocked = ch['is_unlocked'] ?? false;
                        final canRead = !isLocked || isUnlocked;
                        final chNum = ch['chapter_number'] as int? ?? (i + 1);

                        return Obx(
                          () => _ChapterTile(
                            ch: ch,
                            chNum: chNum,
                            canRead: canRead,
                            isLocked: isLocked,
                            isUnlocked: isUnlocked,
                            progress: ctrl.getProgress(chNum),
                            started: ctrl.isChapterStarted(chNum),
                            finished: ctrl.isChapterFinished(chNum),
                            onTap: () => _handleChapterTap(context, ch, auth),
                          ),
                        );
                      },
                      // 3. Limit the count to 4 (or less if there are fewer than 3 chapters)
                      childCount:
                          ctrl.chapters.length > 3 ? 4 : ctrl.chapters.length,
                    ),
                  );
                }),

                // ── Similar stories ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (ctrl.similarStories.isEmpty)
                      return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 8, 12),
                          child: Row(
                            children: [
                              Text(
                                'Similar Stories',
                                style: TextStyle(
                                  color: txt,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Obx(
                                () =>
                                    ctrl.isLoadingSimilar.value
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: depperBlue,
                                          ),
                                        )
                                        : IconButton(
                                          onPressed:
                                              () => ctrl.refreshSimilarStories(
                                                widget.slug,
                                              ),
                                          icon: const Icon(
                                            Icons.shuffle_rounded,
                                          ),
                                          color: depperBlue,
                                          tooltip: 'Shuffle',
                                        ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 248,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: ctrl.similarStories.length,
                            itemBuilder: (_, i) {
                              final s = ctrl.similarStories[i] as Map;
                              final sCoverUrl = ctrl.getCoverUrl(s);
                              final rating =
                                  double.tryParse(
                                    s['average_rating']?.toString() ?? '0',
                                  ) ??
                                  0.0;
                              final views = s['total_views'] ?? 0;
                              final chapters = s['total_chapters'] ?? 0;
                              final genre = s['genre'];
                              final genreName =
                                  genre is Map
                                      ? genre['name']
                                      : ((s['tags'] as List?)?.isNotEmpty ==
                                              true
                                          ? s['tags'][0]['name']
                                          : null);
                              return GestureDetector(
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder:
                                            (_) => StoryDetailScreen(
                                              slug: s['slug'],
                                            ),
                                      ),
                                    ),
                                child: Container(
                                  width: 130,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: SizedBox(
                                              width: 130,
                                              height: 160,
                                              child:
                                                  sCoverUrl.isNotEmpty
                                                      ? CustomImageView(
                                                        imagePath: sCoverUrl,
                                                        fit: BoxFit.cover,
                                                      )
                                                      : CustomImageView(
                                                        imagePath:
                                                            'assets/images/novelux_placeholder_transcpr.jpg',
                                                        fit: BoxFit.cover,
                                                      ),
                                            ),
                                          ),
                                          if (genreName != null)
                                            Positioned(
                                              top: 7,
                                              left: 7,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: depperBlue,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  genreName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        s['title'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: kFontFamily,
                                          color: txt,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        s['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: kFontFamily,
                                          color: sub.withValues(alpha: .8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.star400,
                                            color: Colors.amber,
                                            size: 11,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: sub,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            LucideIcons.eye400,
                                            size: 10,
                                            color: sub,
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              _fmtNum(views),
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: sub,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                LucideIcons.book400,
                                                size: 10,
                                                color: sub,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '$chapters ch',
                                                style: TextStyle(
                                                  color: sub,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                //  const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            );
          }),

          // ── Read Now sticky button ─────────────────────────────────────────────
          bottomNavigationBar: Obx(() {
            if (ctrl.story.value == null) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: bg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Start / Continue Reading button (expanded) ───────────
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircleActionButton(
                        icon: Icons.download_rounded,
                        onTap: () {
                          final story = ctrl.story.value;
                          if (story == null) return;
                          final dlCtrl = Get.put(DownloadController());
                          final authorObj = story['author'];
                          final authorName =
                              authorObj is Map
                                  ? authorObj['username']?.toString() ?? ''
                                  : authorObj?.toString() ?? '';
                          final rawCover =
                              story['cover_image']?.toString() ?? '';
                          final coverUrl =
                              rawCover.startsWith('http')
                                  ? rawCover
                                  : (rawCover.isNotEmpty
                                      ? 'http://10.0.2.2:8000$rawCover'
                                      : '');
                          dlCtrl.requestDownload(
                            slug: widget.slug,
                            title: story['title']?.toString() ?? widget.slug,
                            author: authorName,
                            coverUrl: coverUrl,
                            isExclusive: story['is_exclusive'] == true,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _CircleActionButton(
                        icon: Icons.headphones_rounded,
                        badge: 'Free',
                        badgeColor: const Color(0xFF2E7D32),
                        onTap: () async {
                          final story = ctrl.story.value;
                          if (story == null) return;
                          final authorObj = story['author'];
                          final authorName =
                              authorObj is Map
                                  ? authorObj['username']?.toString() ?? ''
                                  : authorObj?.toString() ?? '';
                          final rawCover =
                              story['cover_image']?.toString() ?? '';
                          final coverUrl =
                              rawCover.startsWith('http')
                                  ? rawCover
                                  : (rawCover.isNotEmpty
                                      ? 'http://10.0.2.2:8000$rawCover'
                                      : '');
                          final storyTitle = story['title']?.toString() ?? '';

                          // Register controller
                          if (!Get.isRegistered<AudioPlayerController>()) {
                            Get.put(AudioPlayerController(), permanent: true);
                          }
                          final audioCtrl = Get.find<AudioPlayerController>();
                          // Show loading state immediately
                          audioCtrl.isLoading.value = true;
                          audioCtrl.storyTitle.value = storyTitle;
                          audioCtrl.author.value = authorName;
                          audioCtrl.coverUrl.value = coverUrl;

                          // Navigate to audio screen right away
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder:
                                  (_) => AudioPlayerScreen(
                                    coverUrl,
                                    authorName,
                                    storyTitle,
                                  ),
                            ),
                          );

                          // Fetch chapter 1 content in the background
                          final res = await ApiService.getChapter(
                            widget.slug,
                            1,
                          );
                          if (res['success'] == true) {
                            final data = res['data'] as Map?;
                            final content = data?['content']?.toString() ?? '';
                            final chapterTitle =
                                data?['title']?.toString() ?? 'Chapter 1';
                            audioCtrl.loadChapter(
                              content: content,
                              chapter: chapterTitle,
                              story: storyTitle,
                              cover: coverUrl,
                              author: authorName,
                            );
                          } else {
                            audioCtrl.isLoading.value = false;
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: depperBlue,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: () {
                        if (ctrl.chapters.isEmpty) return;
                        Map ch = ctrl.chapters.first;
                        for (final c in ctrl.chapters) {
                          final n = c['chapter_number'] as int? ?? 1;
                          if (ctrl.isChapterStarted(n) &&
                              !ctrl.isChapterFinished(n)) {
                            ch = c;
                            break;
                          }
                        }
                        if (ctrl.story.value!.isNotEmpty) {
                          final coverUrl = ctrl.story.value!['cover_image'];
                          final story = ctrl.story.value;
                          final author = story!['author'] as Map? ?? {};
                          final genre2 = story['genre'];
                          final genreSlug2 =
                              genre2 is Map ? genre2['slug']?.toString() : null;
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder:
                                  (_) => NovelUpReadingInterface(
                                    coverUrl: coverUrl,
                                    storySlug: widget.slug,
                                    storyTitle:
                                        story['title']?.toString() ?? '',
                                    chapterNumber: ch['chapter_number'],
                                    chapterTitle: ch['title'] ?? '',
                                    totalChapter: ctrl.chapters.length,
                                    author: author['username'],
                                    genreSlug: genreSlug2,
                                    status: story['status'],
                                  ),
                            ),
                          );
                        } else {
                          AppAlert.error('No Story to Read');
                        }
                      },
                      child: Obx(() {
                        final hasProgress = ctrl.chapters.any((c) {
                          final n = c['chapter_number'] as int? ?? 1;
                          return ctrl.isChapterStarted(n) &&
                              !ctrl.isChapterFinished(n);
                        });
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasProgress
                                  ? LucideIcons.circlePlay400
                                  : LucideIcons.menu500,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasProgress
                                  ? 'Continue Reading'
                                  : 'Start Reading',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),

                  // const SizedBox(width: 12),

                  // ── Download + Audio grouped on the right ────────────────
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  AUTHOR ROW — the key component with follow button
// ══════════════════════════════════════════════════════════════════════════════
class _AuthorRow extends StatelessWidget {
  final Map author;
  final Map story;
  final StoryDetailController ctrl;
  final Color txt;
  final Color sub;

  const _AuthorRow({
    required this.author,
    required this.story,
    required this.ctrl,
    required this.txt,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final username = author['username']?.toString() ?? '';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'A';

    return GestureDetector(
      onTap:
          username.isNotEmpty
              ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuthorProfileScreen(username: username),
                ),
              )
              : null,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: depperBlue.withOpacity(0.18),
            child: Text(
              initial,
              style: TextStyle(
                color: depperBlue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + follower count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.isEmpty ? 'Unknown Author' : username,
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Text(
                    _fmtCount(ctrl.followerCount.value) + ' followers',
                    style: TextStyle(color: txt, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          if (story['status'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color:
                    story['status'] == 'completed'
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                story['status'].toString().toUpperCase(),
                style: TextStyle(
                  color:
                      story['status'] == 'completed'
                          ? Colors.green
                          : Colors.orange,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // ── Follow button ──────────────────────────────────────────────────
          if (username.isNotEmpty)
            Obx(() {
              final following = ctrl.isFollowing.value;
              final loading = ctrl.isFollowLoading.value;

              return GestureDetector(
                onTap: loading ? null : () => ctrl.toggleFollow(username),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: following ? Colors.transparent : depperBlue,
                    border: Border.all(
                      color:
                          following ? Colors.grey.withOpacity(0.5) : depperBlue,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      loading
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          )
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (following)
                                const Icon(
                                  Icons.check_rounded,
                                  color: Colors.grey,
                                  size: 13,
                                ),
                              if (following) const SizedBox(width: 4),
                              Text(
                                following ? 'Following' : 'Follow',
                                style: TextStyle(
                                  color:
                                      following
                                          ? Colors.grey[400]
                                          : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATS BAR
// ══════════════════════════════════════════════════════════════════════════════
class _StatsBar extends StatelessWidget {
  final Map story;
  final StoryDetailController ctrl;
  final String slug;
  final BuildContext context;
  final Color bg;
  final Color sub;
  final Color txt;
  final Color cardbg;
  final Color onbg;

  const _StatsBar({
    required this.story,
    required this.ctrl,
    required this.slug,
    required this.context,
    required this.bg,
    required this.sub,
    required this.txt,
    required this.cardbg,
    required this.onbg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cardbg,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            _fmtCount(story['total_views'] ?? 0),
            'Views',
            Icons.visibility_outlined,
            txt,
            sub,
          ),
          _vdivider(),
          _statItem(
            '${story['total_chapters'] ?? 0}',
            'Chapters',
            Icons.menu_book_outlined,
            txt,
            sub,
          ),
          _vdivider(),
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder:
                        (_) => ReviewsAndCommentsScreen(
                          slug: slug,
                          storyTitle: story['title'] ?? '',
                          avgRating: ctrl.avgRating.value,
                        ),
                  ),
                ),
            child: Obx(
              () => _statItem(
                ctrl.avgRating.value > 0
                    ? ctrl.avgRating.value.toStringAsFixed(1)
                    : '—',
                'Rating ›',
                Icons.star_outline,
                highlight: true,
                txt,
                sub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String val,
    String label,
    IconData icon,
    Color? txt,
    Color? sub, {
    bool highlight = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: 3,
          children: [
            Icon(icon, color: highlight ? depperBlue : sub, size: 16),
            const SizedBox(height: 4),
            Text(
              val.toString(),
              style: TextStyle(
                color: highlight ? depperBlue : txt,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(label, style: TextStyle(color: sub, fontSize: 10)),
      ],
    );
  }

  Widget _vdivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.2));
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHAPTER TILE
// ══════════════════════════════════════════════════════════════════════════════
class _ChapterTile extends StatelessWidget {
  final Map ch;
  final int chNum;
  final bool canRead, isLocked, isUnlocked, started, finished;
  final double progress;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.ch,
    required this.chNum,
    required this.canRead,
    required this.isLocked,
    required this.isUnlocked,
    required this.started,
    required this.finished,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: depperBlue.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Number badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        finished
                            ? Colors.green.withOpacity(0.15)
                            : canRead
                            ? depperBlue.withOpacity(0.15)
                            : const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child:
                        finished
                            ? const Icon(
                              Icons.check_rounded,
                              color: Colors.green,
                              size: 16,
                            )
                            : Text(
                              '$chNum',
                              style: TextStyle(
                                color: canRead ? depperBlue : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ch['title'] ?? 'Chapter $chNum',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: canRead ? Colors.white : Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (started && !finished)
                            _badge(
                              'Continue',
                              depperBlue.withOpacity(0.2),
                              depperBlue,
                            ),
                          if (finished)
                            _badge(
                              'Done',
                              Colors.green.withOpacity(0.15),
                              Colors.green,
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '${ch['word_count'] ?? 0} words',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          if (isLocked && !isUnlocked) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.monetization_on_outlined,
                              color: Colors.orange,
                              size: 11,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${ch['coin_cost']} coins',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  isLocked && !isUnlocked
                      ? Icons.lock_outline
                      : Icons.play_circle_outline_rounded,
                  color:
                      isLocked && !isUnlocked ? Colors.grey[700] : depperBlue,
                  size: 20,
                ),
              ],
            ),

            // Progress bar
            if (started && canRead) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: const Color(0xFF2a2a2a),
                        color: finished ? Colors.green : depperBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: finished ? Colors.green : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF1e1e22), height: 1),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  EXPANDABLE TEXT
// ══════════════════════════════════════════════════════════════════════════════
class _ExpandableText extends StatefulWidget {
  final String text;
  final Color sub;
  const _ExpandableText({required this.text, required this.sub});
  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.sub,
            fontSize: 16,
            fontFamily: kFontFamily,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Show more',
            style: TextStyle(
              color: depperBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CIRCLE ACTION BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg =
        isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.grey[200]!;
    final iconClr = isDark ? Colors.white : const Color(0xFF1a1a1a);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: btnBg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Icon(icon, color: iconClr, size: 22),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? depperBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════════════════════════
String _fmtCount(dynamic n) {
  final v = int.tryParse(n?.toString() ?? '0') ?? 0;
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}
