import 'dart:developer' as myLog;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/download_screen/controller/download_controller.dart';
import 'package:novelux/screen/reading_interface/audio_player_screen.dart';
import 'package:novelux/screen/reading_interface/reading_interface.dart';
import 'package:novelux/screen/reading_interface/reading_position_store.dart';
import 'package:novelux/screen/author/author_profile_screen.dart';
import 'package:novelux/screen/review_comment_story/reviews_and_comments_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:novelux/screen/library/controller/library_controller.dart';
import 'package:novelux/widgets/auth_prompt_sheet.dart';
import 'package:novelux/core/constants/app_constants.dart';
import 'package:novelux/widgets/app_glass.dart';

const _kPlaceholderCover = 'assets/images/novelux_placeholder_transcpr.jpg';

// ══════════════════════════════════════════════════════════════════════════════
//  PALETTE
// ══════════════════════════════════════════════════════════════════════════════
const _kGreen = Color(0xFF2E9E5B);

/// The app's light/dark colours plus [accent], the muted tone sampled from
/// the story's cover (falls back to the brand colour until it's ready).
class _Palette {
  final bool isDark;
  final Color bg, gap, surface, sheet, txt, sub, divider, accent;

  const _Palette._({
    required this.isDark,
    required this.bg,
    required this.gap,
    required this.surface,
    required this.sheet,
    required this.txt,
    required this.sub,
    required this.divider,
    required this.accent,
  });

  factory _Palette.of(BuildContext context, [Color accent = depperBlue]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? _Palette._(
          isDark: true,
          bg: const Color(0xFF0d0d0f),
          gap: const Color(0xFF1a1a1c),
          surface: const Color.fromARGB(255, 33, 35, 36),
          sheet: const Color(0xFF1e1e22),
          txt: Colors.white,
          sub: Colors.grey[400]!,
          divider: const Color(0xFF2a2a2a),
          accent: accent,
        )
        : _Palette._(
          isDark: false,
          bg: const Color(0xFFF2F2F7),
          gap: Colors.grey[200]!,
          surface: Colors.white,
          sheet: Colors.white,
          txt: const Color(0xFF1a1a1a),
          sub: Colors.grey[600]!,
          divider: Colors.grey[200]!,
          accent: accent,
        );
  }

  Color get tagBg => accent.withValues(alpha: isDark ? 0.18 : 0.10);
}

// ══════════════════════════════════════════════════════════════════════════════
//  CONTROLLER
// ══════════════════════════════════════════════════════════════════════════════
class StoryDetailController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool loadFailed = false.obs;
  final RxBool isLoadingChapters = false.obs;
  final RxBool isLoadingSimilar = false.obs;

  final Rx<Map?> story = Rx<Map?>(null);
  /// Chapters loaded so far: a page around where the reader is (enough for
  /// the 3-row preview) until the "All chapters" sheet loads the full list.
  final RxList chapters = [].obs;
  final RxInt totalChapters = 0.obs;
  final RxBool chaptersComplete = false.obs;
  final RxBool isLoadingAllChapters = false.obs;
  static const _previewPageSize = 10;
  final RxList similarStories = [].obs;
  final RxList reviews = [].obs;
  final RxInt reviewCount = 0.obs;

  final List _allSimilarStories = [];

  final RxBool isBookmarked = false.obs;
  final RxDouble avgRating = 0.0.obs;

  // ── Follow ─────────────────────────────────────────────────────────────────
  final RxBool isFollowing = false.obs;
  final RxBool isFollowLoading = false.obs;
  final RxInt followerCount = 0.obs;

  // ── Reading position ───────────────────────────────────────────────────────
  // Saved per story by the reader (ReadingPositionStore); null = never opened.
  final Rx<ReadingPosition?> position = Rx<ReadingPosition?>(null);

  // ── Cover-derived accent color ────────────────────────────────────────────
  // Starts as the brand color; replaced once the cover's dominant color is
  // sampled and dulled down, so buttons/icons never flash bright/neon.
  final Rx<Color> accentColor = depperBlue.obs;
  String _accentSource = '';

  // Downsamples the cover image, averages its pixels, then desaturates and
  // clamps the lightness so the result always reads as a dull/muted tone
  // regardless of how vivid the source cover is.
  Future<void> _extractAccentColor(String coverUrl) async {
    if (coverUrl.isEmpty || coverUrl == _accentSource) return;
    _accentSource = coverUrl;
    try {
      final res = await http
          .get(Uri.parse(coverUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;

      final codec = await ui.instantiateImageCodec(
        res.bodyBytes,
        targetWidth: 40,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return;

      final pixels = byteData.buffer.asUint8List();
      int rSum = 0, gSum = 0, bSum = 0, count = 0;
      for (int i = 0; i + 3 < pixels.length; i += 4) {
        final alpha = pixels[i + 3];
        if (alpha < 200) continue; // skip transparent edges
        rSum += pixels[i];
        gSum += pixels[i + 1];
        bSum += pixels[i + 2];
        count++;
      }
      if (count == 0) return;

      final avg = Color.fromARGB(
        255,
        rSum ~/ count,
        gSum ~/ count,
        bSum ~/ count,
      );
      accentColor.value = _muteColor(avg);
    } catch (e) {
      _accentSource = ''; // let a later refresh try again
      myLog.log(
        'Accent color extraction failed: $e',
        name: 'StoryDetailController',
      );
    }
  }

  Color _muteColor(Color c) {
    final hsl = HSLColor.fromColor(c);
    // Cap saturation and clamp lightness into a mid range so the accent
    // never reads as bright/neon, no matter how vivid the cover is.
    return hsl
        .withSaturation(hsl.saturation.clamp(0.0, 0.45))
        .withLightness(hsl.lightness.clamp(0.32, 0.55))
        .toColor();
  }

  // ── Load story ─────────────────────────────────────────────────────────────
  /// [silent] refreshes in place (pull-to-refresh, revisiting a cached story)
  /// without swapping the page for the loading skeleton.
  Future<void> loadStory(String slug, {bool silent = false}) async {
    if (!silent) isLoading.value = true;
    loadFailed.value = false;
    final res = await ApiService.getStoryDetail(slug);
    isLoading.value = false;
    if (res['success'] != true) {
      if (story.value == null) loadFailed.value = true;
      return;
    }
    final data = res['data'];
    story.value = data;
    isBookmarked.value = data['is_bookmarked'] ?? false;
    _extractAccentColor(getCoverUrl(data));
    avgRating.value =
        double.tryParse(data['average_rating']?.toString() ?? '0') ?? 0.0;

    // ── Follow state from API ────────────────────────────────────────────
    isFollowing.value = data['is_following'] ?? false;
    followerCount.value =
        int.tryParse(data['author']?['followers_count']?.toString() ?? '0') ??
        0;

    await Future.wait([
      () async {
        await loadPosition(slug);
        await loadChapters(slug);
      }(),
      loadReviews(slug),
      // Keep the current picks on a refresh; "More" brings new ones
      if (!silent || _allSimilarStories.isEmpty) loadSimilarStories(slug),
    ]);
  }

  /// Chapter number Read / Listen continue from (the saved chapter, or the
  /// next one once it's finished); 1 for a new reader.
  int get resumeChapterNumber {
    final pos = position.value;
    if (pos == null) return 1;
    return pos.fraction >= 0.95 ? pos.chapter + 1 : pos.chapter;
  }

  /// Loads just the page of chapters around where the reader is — the full
  /// list is only fetched when the "All chapters" sheet opens. (Once it has
  /// been loaded, refreshes keep the full list.)
  Future<void> loadChapters(String slug) async {
    if (chaptersComplete.value) return loadAllChapters(slug, force: true);
    myLog.log(
      'Loading chapters for story: $slug',
      name: 'StoryDetailController',
    );
    isLoadingChapters.value = chapters.isEmpty;
    final page = ((resumeChapterNumber - 1) ~/ _previewPageSize) + 1;
    var res = await ApiService.getChapters(slug, page: page, pageSize: _previewPageSize);
    if (res['success'] != true && page > 1) {
      // Saved position beyond the last page (chapters removed) — use page 1
      res = await ApiService.getChapters(slug, page: 1, pageSize: _previewPageSize);
    }
    isLoadingChapters.value = false;
    if (res['success'] == true) {
      final data = res['data'];
      final List list = data is List ? data : (data['results'] ?? []);
      chapters.value = list;
      totalChapters.value =
          data is Map ? (data['count'] as num?)?.toInt() ?? list.length : list.length;
      chaptersComplete.value = list.length >= totalChapters.value;
    }
  }

  /// Every chapter, for the "All chapters" sheet (and to find the resume
  /// chapter if it isn't in the preview page).
  Future<void> loadAllChapters(String slug, {bool force = false}) async {
    if (chaptersComplete.value && !force) return;
    if (isLoadingAllChapters.value) return;
    isLoadingAllChapters.value = true;
    final all = [];
    var page = 1;
    var ok = true;
    while (true) {
      final res = await ApiService.getChapters(slug, page: page, pageSize: 500);
      if (res['success'] != true) {
        ok = false;
        break;
      }
      final data = res['data'];
      final List list = data is List ? data : (data['results'] ?? []);
      all.addAll(list);
      if (data is! Map || data['next'] == null || list.isEmpty) break;
      page++;
    }
    isLoadingAllChapters.value = false;
    if (ok) {
      chapters.value = all;
      totalChapters.value = all.length;
      chaptersComplete.value = true;
    }
  }

  /// Make sure the chapter Read / Listen should open is loaded.
  Future<void> ensureResumeChapterLoaded(String slug) async {
    if (chaptersComplete.value) return;
    final want = resumeChapterNumber;
    final has = chapters.any((c) => chapterNumber(c as Map, 0) == want);
    if (!has) await loadAllChapters(slug);
  }

  Future<void> loadSimilarStories(String slug) async {
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
      refreshSimilarStories(slug);
    }
  }

  /// Swaps in a new batch of picks, preferring ones not on screen yet.
  void refreshSimilarStories(String slug) {
    if (_allSimilarStories.isEmpty) return;
    final shown = similarStories.map((s) => s['slug']).toSet();
    final pool = List.from(_allSimilarStories)..shuffle();
    similarStories.value =
        [
          ...pool.where((s) => !shown.contains(s['slug'])),
          ...pool.where((s) => shown.contains(s['slug'])),
        ].take(10).toList();
  }

  Future<bool> submitReview(
    String slug, {
    required String rating,
    required String content,
  }) async {
    if (!Get.find<AuthController>().isLoggedIn.value) {
      if (await promptSignIn(AuthPromptReason.review) != true) return false;
    }
    final res = await ApiService.submitReview(
      slug,
      rating: rating,
      content: content,
    );
    if (res['success'] != true) {
      AppAlert.error(res['error']?.toString() ?? 'Could not submit review');
      return false;
    }
    AppAlert.success('Review submitted! — Thanks for your feedback 😊');
    // The new review can move the average as well as the list
    loadStory(slug, silent: true);
    return true;
  }

  Future<void> loadReviews(String slug) async {
    final res = await ApiService.getStoryReviews(slug);
    if (res['success'] != true) return;
    final data = res['data'];
    final List all = data is List ? data : (data['results'] ?? []);
    reviews.value = all.take(2).toList();
    reviewCount.value =
        data is Map
            ? int.tryParse(data['total_count']?.toString() ?? '') ?? all.length
            : all.length;
  }

  Future<void> loadPosition(String slug) async {
    position.value = await ReadingPositionStore.get(slug);
  }

  // ── Follow / Unfollow ─────────────────────────────────────────────────────
  Future<void> toggleFollow(String authorUsername) async {
    if (isFollowLoading.value) return;
    if (!Get.find<AuthController>().isLoggedIn.value) {
      if (await promptSignIn(AuthPromptReason.follow) != true) return;
    }
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
  /// Works signed out — LibraryController keeps a guest's shelf on the device
  /// and pushes it up when they eventually sign in.
  Future<void> toggleBookmark(String slug) async {
    final lib =
        Get.isRegistered<LibraryController>()
            ? Get.find<LibraryController>()
            : Get.put(LibraryController());
    if (isBookmarked.value) {
      await lib.removeBookmark(slug);
      isBookmarked.value = false;
    } else {
      await lib.addBookmark(slug, story: story.value);
      isBookmarked.value = true;
    }
  }

  // ── Chapters & progress ───────────────────────────────────────────────────
  static int chapterNumber(Map ch, int index) =>
      (ch['chapter_number'] as num?)?.toInt() ?? index + 1;

  static bool isChapterLocked(Map ch) =>
      ch['is_locked'] == true && ch['is_unlocked'] != true;

  bool get hasStarted => position.value != null;

  /// Index into [chapters] of where Read / Listen pick up: the saved chapter,
  /// or the one after it once that chapter is finished.
  int get resumeIndex {
    final pos = position.value;
    if (pos == null || chapters.isEmpty) return 0;
    final want = resumeChapterNumber;
    final i = chapters.indexWhere((c) => chapterNumber(c as Map, 0) == want);
    if (i >= 0) return i;
    // Finished the last chapter: stay on it
    final j = chapters.indexWhere((c) => chapterNumber(c as Map, 0) == pos.chapter);
    return j >= 0 ? j : 0;
  }

  /// 1.0 for chapters before the saved one, the saved fraction for the saved
  /// chapter itself, 0.0 after it.
  double progressOf(int chNum) {
    final pos = position.value;
    if (pos == null || chNum > pos.chapter) return 0.0;
    if (chNum < pos.chapter) return 1.0;
    return pos.fraction;
  }

  bool get isFree =>
      story.value?['is_free'] == true ||
      (chapters.isNotEmpty && chapters.every((c) => c['is_locked'] != true));

  // ── URLs ──────────────────────────────────────────────────────────────────
  static String resolveUrl(Object? path) {
    final p = path?.toString() ?? '';
    if (p.isEmpty || p.startsWith('http')) return p;
    return 'https://novelux.onrender.com$p';
  }

  String getCoverUrl(Map? s) => resolveUrl(s?['cover_image']);
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
  final _scroll = ScrollController();

  // True once the header has scrolled under the app bar, which then shows the
  // compact cover + title.
  final _collapsed = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final alreadyCached = Get.isRegistered<StoryDetailController>(
      tag: widget.slug,
    );
    ctrl = Get.put(StoryDetailController(), tag: widget.slug);
    // Revisiting a cached story shows it at once and refreshes underneath, so
    // unlocks, counts and the reading position are never stale.
    ctrl.loadStory(widget.slug, silent: alreadyCached);
    _scroll.addListener(() => _collapsed.value = _scroll.offset > 170);
  }

  @override
  void dispose() {
    // The controller stays registered so revisiting the same story is instant.
    _scroll.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  void _shareStory(Map story) {
    Share.share(
      'Check out "${story['title']}" on ${AppConstants.appName}!\n'
      'https://www.novelux.app/story/${story['slug']}/',
    );
  }

  String _authorName(Map story) {
    final a = story['author'];
    return a is Map ? a['username']?.toString() ?? '' : a?.toString() ?? '';
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  /// Opens [ch] in the reader. Locked chapters open too: the reader shows the
  /// unlock options (coins or a rewarded ad) in place of the text.
  Future<void> _openChapter(Map ch) async {
    final story = ctrl.story.value;
    if (story == null) return;
    final genre = story['genre'];
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder:
            (_) => NovelUpReadingInterface(
              coverUrl: ctrl.getCoverUrl(story),
              storySlug: widget.slug,
              storyTitle: story['title']?.toString() ?? '',
              chapterNumber: StoryDetailController.chapterNumber(
                ch,
                ctrl.chapters.indexOf(ch),
              ),
              chapterTitle: ch['title']?.toString() ?? '',
              totalChapter: ctrl.totalChapters.value > 0
                  ? ctrl.totalChapters.value
                  : ctrl.chapters.length,
              author: _authorName(story),
              genreSlug: genre is Map ? genre['slug']?.toString() : null,
              status: story['status']?.toString(),
            ),
      ),
    );
    // Pick up the new position and anything unlocked while reading
    await ctrl.loadPosition(widget.slug);
    ctrl.loadChapters(widget.slug);
  }

  Future<void> _readNow() async {
    if (ctrl.chapters.isEmpty) {
      if (!ctrl.isLoadingChapters.value) {
        AppAlert.info('No chapters published yet');
      }
      return;
    }
    await ctrl.ensureResumeChapterLoaded(widget.slug);
    if (!mounted) return;
    _openChapter(ctrl.chapters[ctrl.resumeIndex] as Map);
  }

  void _download() {
    final story = ctrl.story.value;
    if (story == null) return;
    Get.put(DownloadController()).requestDownload(
      slug: widget.slug,
      title: story['title']?.toString() ?? widget.slug,
      author: _authorName(story),
      coverUrl: ctrl.getCoverUrl(story),
      isExclusive: story['is_exclusive'] == true,
    );
  }

  Future<void> _listen() async {
    final story = ctrl.story.value;
    if (story == null || ctrl.chapters.isEmpty) return;
    await ctrl.ensureResumeChapterLoaded(widget.slug);
    if (!mounted) return;
    final ch = ctrl.chapters[ctrl.resumeIndex] as Map;
    final chNum = StoryDetailController.chapterNumber(ch, ctrl.resumeIndex);
    if (StoryDetailController.isChapterLocked(ch)) {
      AppAlert.warning('Unlock Chapter $chNum to listen to it');
      return;
    }
    final authorName = _authorName(story);
    final coverUrl = ctrl.getCoverUrl(story);
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
        builder: (_) => AudioPlayerScreen(coverUrl, authorName, storyTitle),
      ),
    );

    // Fetch the chapter content in the background
    final res = await ApiService.getChapter(widget.slug, chNum);
    if (res['success'] == true) {
      final data = res['data'] as Map?;
      audioCtrl.loadChapter(
        content: data?['content']?.toString() ?? '',
        chapter: data?['title']?.toString() ?? 'Chapter $chNum',
        story: storyTitle,
        cover: coverUrl,
        author: authorName,
      );
    } else {
      audioCtrl.isLoading.value = false;
      AppAlert.error('Could not load audio for Chapter $chNum');
    }
  }

  Future<void> _openReviews() async {
    final story = ctrl.story.value;
    if (story == null) return;
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder:
            (_) => ReviewsAndCommentsScreen(
              slug: widget.slug,
              storyTitle: story['title'] ?? '',
              avgRating: ctrl.avgRating.value,
            ),
      ),
    );
    // A new review can change the rating as well as the list
    ctrl.loadStory(widget.slug, silent: true);
  }

  void _openAuthor(String username) {
    if (username.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorProfileScreen(username: username),
      ),
    );
  }

  void _showReportSheet(_Palette p) {
    showGlassBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportSheet(slug: widget.slug, p: p),
    );
  }

  void _showAllChapters(_Palette p) {
    // The page only holds a preview; fetch every chapter for the sheet
    ctrl.loadAllChapters(widget.slug);
    showGlassBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetCtx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.92,
            builder:
                (_, scroll) => Column(
                  children: [
                    const _SheetHandle(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            'All Chapters',
                            style: TextStyle(
                              color: p.txt,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Obx(
                            () => Text(
                              '${ctrl.totalChapters.value > 0 ? ctrl.totalChapters.value : ctrl.chapters.length} chapters',
                              style: TextStyle(color: p.sub, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        if (!ctrl.chaptersComplete.value &&
                            ctrl.isLoadingAllChapters.value) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: p.accent,
                              strokeWidth: 2,
                            ),
                          );
                        }
                        final resume = ctrl.resumeIndex;
                        return ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: ctrl.chapters.length,
                          itemBuilder: (_, i) {
                            final ch = ctrl.chapters[i] as Map;
                            return _ChapterRow(
                              ch: ch,
                              chNum: StoryDetailController.chapterNumber(ch, i),
                              isCurrent: i == resume,
                              progress: ctrl.progressOf(
                                StoryDetailController.chapterNumber(ch, i),
                              ),
                              showDivider: i < ctrl.chapters.length - 1,
                              p: p,
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                _openChapter(ch);
                              },
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
          ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final base = _Palette.of(context);

        return Scaffold(
          backgroundColor: base.bg,
          body: Obx(() {
            final p = _Palette.of(context, ctrl.accentColor.value);
            final story = ctrl.story.value;
            if (ctrl.isLoading.value && story == null) {
              return _DetailSkeleton(p: p);
            }
            if (story == null) {
              return _LoadError(
                p: p,
                failed: ctrl.loadFailed.value,
                onRetry: () => ctrl.loadStory(widget.slug),
              );
            }

            return RefreshIndicator(
              color: p.accent,
              backgroundColor: p.sheet,
              onRefresh: () => ctrl.loadStory(widget.slug, silent: true),
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(story, p),
                  SliverToBoxAdapter(
                    child: _Header(
                      story: story,
                      ctrl: ctrl,
                      heroTag: widget.heroTag,
                      p: p,
                      onAuthorTap: () => _openAuthor(_authorName(story)),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _StatsRow(
                      story: story,
                      ctrl: ctrl,
                      p: p,
                      onRatingTap: _openReviews,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _SynopsisSection(story: story, p: p),
                  ),
                  SliverToBoxAdapter(child: _SectionGap(p: p)),
                  SliverToBoxAdapter(
                    child: _ChaptersSection(
                      ctrl: ctrl,
                      p: p,
                      onOpen: _openChapter,
                      onViewAll: () => _showAllChapters(p),
                    ),
                  ),
                  SliverToBoxAdapter(child: _SectionGap(p: p)),
                  SliverToBoxAdapter(
                    child: _CommentsSection(
                      ctrl: ctrl,
                      slug: widget.slug,
                      p: p,
                      onOpen: _openReviews,
                    ),
                  ),
                  SliverToBoxAdapter(child: _SectionGap(p: p)),
                  SliverToBoxAdapter(
                    child: _AuthorSection(
                      author: story['author'] as Map? ?? {},
                      ctrl: ctrl,
                      p: p,
                      onTap: () => _openAuthor(_authorName(story)),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _SimilarSection(ctrl: ctrl, slug: widget.slug, p: p),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          }),
          bottomNavigationBar: Obx(() {
            if (ctrl.story.value == null) return const SizedBox.shrink();
            final p = _Palette.of(context, ctrl.accentColor.value);
            return _BottomBar(
              ctrl: ctrl,
              p: p,
              onDownload: _download,
              onListen: _listen,
              onRead: _readNow,
            );
          }),
        );
      },
    );
  }

  Widget _buildAppBar(Map story, _Palette p) {
    final coverUrl = ctrl.getCoverUrl(story);
    return ValueListenableBuilder<bool>(
      valueListenable: _collapsed,
      builder:
          (_, collapsed, __) => SliverAppBar(
            pinned: true,
            toolbarHeight: 64,
            leadingWidth: 64,
            backgroundColor: p.bg,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            shape: Border(
              bottom: BorderSide(
                color: collapsed ? p.divider : Colors.transparent,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: _CircleIconButton(
                  icon: LucideIcons.chevronLeft,
                  p: p,
                  onTap: () => Get.back(),
                ),
              ),
            ),
            title: AnimatedOpacity(
              opacity: collapsed ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomImageView(
                      imagePath:
                          coverUrl.isNotEmpty ? coverUrl : _kPlaceholderCover,
                      width: 34,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story['title'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.txt,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _authorName(story),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.sub, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (!collapsed) ...[
                _CircleIconButton(
                  icon: LucideIcons.share,
                  p: p,
                  onTap: () => _shareStory(story),
                ),
                const SizedBox(width: 10),
              ],
              Obx(
                () => _CircleIconButton(
                  icon:
                      ctrl.isBookmarked.value
                          ? Icons.bookmark_rounded
                          : LucideIcons.bookmark,
                  iconColor: ctrl.isBookmarked.value ? p.accent : null,
                  p: p,
                  onTap: () => ctrl.toggleBookmark(widget.slug),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                color: p.sheet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) {
                  if (v == 'share') _shareStory(story);
                  if (v == 'report') _showReportSheet(p);
                },
                itemBuilder:
                    (_) => [
                      _menuItem('share', LucideIcons.share, 'Share', p.txt),
                      _menuItem(
                        'report',
                        Icons.flag_outlined,
                        'Report',
                        Colors.redAccent,
                      ),
                    ],
                child: _CircleIconButton(icon: Icons.more_horiz_rounded, p: p),
              ),
              const SizedBox(width: 16),
            ],
          ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color iconColor,
  ) => PopupMenuItem(
    value: value,
    child: Builder(
      builder: (context) {
        final p = _Palette.of(context);
        return Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: p.txt, fontSize: 13)),
          ],
        );
      },
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  HEADER — cover, title, author, language / age rating, status
// ══════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final Map story;
  final StoryDetailController ctrl;
  final String? heroTag;
  final _Palette p;
  final VoidCallback onAuthorTap;

  const _Header({
    required this.story,
    required this.ctrl,
    required this.heroTag,
    required this.p,
    required this.onAuthorTap,
  });

  static const _languages = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'pt': 'Portuguese',
    'de': 'German',
    'ar': 'Arabic',
    'zh': 'Chinese',
    'yo': 'Yoruba',
  };

  @override
  Widget build(BuildContext context) {
    final coverUrl = ctrl.getCoverUrl(story);
    final author = story['author'] as Map? ?? {};
    final username = author['username']?.toString() ?? '';
    final rawLang = story['language']?.toString() ?? '';
    final language = _languages[rawLang.toLowerCase()] ?? rawLang;
    final ageRating = story['age_rating']?.toString();
    final status = story['status']?.toString();
    final completed = status == 'completed';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Stack(
            children: [
              _maybehero(
                heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomImageView(
                    imagePath:
                        coverUrl.isNotEmpty ? coverUrl : _kPlaceholderCover,
                    width: 112,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Obx(
                  () =>
                      ctrl.isFree
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _kGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Free',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story['title'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.txt,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onAuthorTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      _Avatar(author: author, radius: 11, p: p),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          username.isEmpty ? 'Unknown Author' : username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.sub, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (language.isNotEmpty)
                      Text(
                        'Language: $language',
                        style: TextStyle(color: p.sub, fontSize: 13),
                      ),
                    if (language.isNotEmpty && ageRating != null)
                      Text('·', style: TextStyle(color: p.sub)),
                    if (ageRating != null)
                      _Pill(
                        label: ageRating,
                        fg: ageRating == '18+' ? Colors.red : p.sub,
                        bg:
                            ageRating == '18+'
                                ? Colors.red.withValues(alpha: 0.12)
                                : p.surface,
                      ),
                  ],
                ),
                if (status != null) ...[
                  const SizedBox(height: 10),
                  _Pill(
                    label: status.toUpperCase(),
                    fg: completed ? Colors.green : Colors.orange,
                    bg: (completed ? Colors.green : Colors.orange).withValues(
                      alpha: 0.15,
                    ),
                    bold: true,
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

// ══════════════════════════════════════════════════════════════════════════════
//  STATS ROW
// ══════════════════════════════════════════════════════════════════════════════
class _StatsRow extends StatelessWidget {
  final Map story;
  final StoryDetailController ctrl;
  final _Palette p;
  final VoidCallback onRatingTap;

  const _StatsRow({
    required this.story,
    required this.ctrl,
    required this.p,
    required this.onRatingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: p.divider)),
      ),
      child: Row(
        children: [
          _stat(
            _fmtCount(story['total_views'] ?? 0),
            'Views',
            LucideIcons.eye,
            p.sub,
          ),
          _divider(),
          _stat(
            '${story['total_chapters'] ?? 0}',
            'Chapters',
            LucideIcons.bookOpen,
            p.sub,
          ),
          _divider(),
          Obx(
            () => _stat(
              ctrl.avgRating.value.toStringAsFixed(1),
              'Rating',
              LucideIcons.star,
              Colors.amber[700]!,
              onTap: onRatingTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    String value,
    String label,
    IconData icon,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: p.txt,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: p.sub, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: p.divider);
}

// ══════════════════════════════════════════════════════════════════════════════
//  SYNOPSIS + TAGS
// ══════════════════════════════════════════════════════════════════════════════
class _SynopsisSection extends StatelessWidget {
  final Map story;
  final _Palette p;

  const _SynopsisSection({required this.story, required this.p});

  @override
  Widget build(BuildContext context) {
    final genre = story['genre'];
    final genreName = genre is Map ? genre['name']?.toString() : null;
    final tagNames = [
      for (final t in story['tags'] as List? ?? [])
        if (t is Map && (t['name']?.toString() ?? '').isNotEmpty)
          t['name'].toString(),
    ];
    // The genre leads the chips unless a tag already names it
    final chips = [
      if (genreName != null && !tagNames.contains(genreName)) genreName,
      ...tagNames,
    ];
    final description = story['description']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Synopsis', p: p),
          const SizedBox(height: 10),
          if (description.isNotEmpty)
            _ExpandableText(text: description, p: p)
          else
            Text(
              'No synopsis yet.',
              style: TextStyle(color: p.sub, fontSize: 15),
            ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.tagBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHAPTERS — a 3-chapter window around where the reader is
// ══════════════════════════════════════════════════════════════════════════════
class _ChaptersSection extends StatelessWidget {
  final StoryDetailController ctrl;
  final _Palette p;
  final void Function(Map ch) onOpen;
  final VoidCallback onViewAll;

  const _ChaptersSection({
    required this.ctrl,
    required this.p,
    required this.onOpen,
    required this.onViewAll,
  });

  static const _preview = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Obx(() {
        final chapters = ctrl.chapters;
        final loaded = chapters.length;
        final total =
            ctrl.totalChapters.value > 0 ? ctrl.totalChapters.value : loaded;
        final resume = ctrl.resumeIndex;
        // Keep the chapter Read opens in view: one before it, it, one after
        final start = (resume - 1).clamp(0, (loaded - _preview).clamp(0, loaded));
        final end = (start + _preview).clamp(0, loaded);
        final more = total - (end - start);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: total > 0 ? onViewAll : null,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  _SectionTitle('Chapters', p: p),
                  const Spacer(),
                  Text(
                    '$total chapters',
                    style: TextStyle(color: p.sub, fontSize: 14),
                  ),
                  if (total > 0)
                    Icon(LucideIcons.chevronRight, color: p.sub, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (ctrl.isLoadingChapters.value)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: p.accent,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No chapters published yet.',
                  style: TextStyle(color: p.sub, fontSize: 14),
                ),
              )
            else ...[
              for (var i = start; i < end; i++)
                _ChapterRow(
                  ch: chapters[i] as Map,
                  chNum: StoryDetailController.chapterNumber(
                    chapters[i] as Map,
                    i,
                  ),
                  isCurrent: i == resume,
                  progress: ctrl.progressOf(
                    StoryDetailController.chapterNumber(chapters[i] as Map, i),
                  ),
                  showDivider: i < end - 1 || more > 0,
                  p: p,
                  onTap: () => onOpen(chapters[i] as Map),
                ),
              if (more > 0)
                InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        '— $more more chapters —',
                        style: TextStyle(color: p.sub, fontSize: 14),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  final Map ch;
  final int chNum;
  final bool isCurrent, showDivider;
  final double progress;
  final _Palette p;
  final VoidCallback onTap;

  const _ChapterRow({
    required this.ch,
    required this.chNum,
    required this.isCurrent,
    required this.progress,
    required this.showDivider,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = StoryDetailController.isChapterLocked(ch);
    final read = !isCurrent && progress >= 0.95;
    final partly = isCurrent && progress > 0.01 && progress < 0.95;

    final meta = <String>['${ch['word_count'] ?? 0} words'];
    if (partly) meta.add('${(progress * 100).round()}% read');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: showDivider ? p.divider : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            // Number badge — filled for the chapter Read opens
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCurrent ? p.accent : p.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child:
                    read
                        ? Icon(Icons.check_rounded, color: _kGreen, size: 18)
                        : Text(
                          '$chNum',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : p.txt,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ch['title']?.toString() ?? 'Chapter $chNum',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.txt,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        meta.join(' · '),
                        style: TextStyle(color: p.sub, fontSize: 13),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.monetization_on_outlined,
                          color: Colors.orange,
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${ch['coin_cost'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (partly) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: p.divider,
                        color: p.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              locked ? LucideIcons.lock : LucideIcons.circlePlay,
              color:
                  isCurrent && !locked
                      ? p.accent
                      : p.sub.withValues(alpha: locked ? 1 : 0.45),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  COMMENTS — story-level reviews, with an inline composer
// ══════════════════════════════════════════════════════════════════════════════
class _CommentsSection extends StatelessWidget {
  final StoryDetailController ctrl;
  final String slug;
  final _Palette p;
  final VoidCallback onOpen;

  const _CommentsSection({
    required this.ctrl,
    required this.slug,
    required this.p,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Obx(() {
        final reviews = ctrl.reviews;
        final count = ctrl.reviewCount.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionTitle(
                  count > 0 ? 'Comments ($count)' : 'Comments',
                  p: p,
                ),
                const Spacer(),
                _LinkAction(
                  label: count > 2 ? 'See all' : 'Write a review',
                  color: p.accent,
                  onTap: onOpen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              Text(
                'Be the first to share your thoughts.',
                style: TextStyle(color: p.txt, fontSize: 15),
              )
            else
              for (final r in reviews) _ReviewTile(review: r as Map, p: p),
            const SizedBox(height: 14),
            Divider(color: p.divider, height: 1),
            const SizedBox(height: 14),
            _ReviewComposer(ctrl: ctrl, slug: slug, p: p),
          ],
        );
      }),
    );
  }
}

/// The "Write a comment…" field. A story review needs a rating as well as
/// text, so the rating choices slide in once the reader starts writing.
class _ReviewComposer extends StatefulWidget {
  final StoryDetailController ctrl;
  final String slug;
  final _Palette p;

  const _ReviewComposer({
    required this.ctrl,
    required this.slug,
    required this.p,
  });

  @override
  State<_ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<_ReviewComposer> {
  static const _ratings = [
    ('recommend', '😊', 'Recommend'),
    ('average', '😐', 'Average'),
    ('not_good', '😒', 'Not good'),
  ];

  final _text = TextEditingController();
  final _focus = FocusNode();
  String _rating = 'recommend';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _text.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await widget.ctrl.submitReview(
      widget.slug,
      rating: _rating,
      content: content,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _text.clear();
      _focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final open = _focus.hasFocus || _text.text.isNotEmpty;
    final canSend = _text.text.trim().isNotEmpty && !_sending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child:
              open
                  ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (value, emoji, label) in _ratings)
                          GestureDetector(
                            onTap: () => setState(() => _rating = value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _rating == value ? p.tagBg : p.surface,
                                border: Border.all(
                                  color:
                                      _rating == value ? p.accent : p.divider,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$emoji $label',
                                style: TextStyle(
                                  color: _rating == value ? p.accent : p.sub,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                  : const SizedBox(width: double.infinity),
        ),
        Container(
          padding: const EdgeInsets.only(left: 18, right: 4),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: _focus.hasFocus ? p.accent : p.divider),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: p.txt, fontSize: 15),
                  cursorColor: p.accent,
                  decoration: InputDecoration(
                    hintText: 'Write a comment…',
                    hintStyle: TextStyle(color: p.sub, fontSize: 15),
                    // The pill around it is the outline — switch off every
                    // state the app theme would otherwise draw inside it
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              IconButton(
                onPressed: canSend ? _send : null,
                icon:
                    _sending
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.accent,
                          ),
                        )
                        : Icon(
                          LucideIcons.send,
                          color:
                              canSend ? p.accent : p.sub.withValues(alpha: 0.5),
                          size: 20,
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map review;
  final _Palette p;

  const _ReviewTile({required this.review, required this.p});

  static const _ratings = {
    'recommend': '😊 Recommend',
    'average': '😐 Average',
    'not_good': '😒 Not good',
  };

  @override
  Widget build(BuildContext context) {
    final user = review['user'] is Map ? review['user'] as Map : {};
    final content = review['content']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(author: user, radius: 16, p: p),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user['username']?.toString() ?? 'Anonymous',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.txt,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _ratings[review['rating']?.toString()] ?? '',
                      style: TextStyle(color: p.sub, fontSize: 12),
                    ),
                  ],
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.txt.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.45,
                    ),
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

// ══════════════════════════════════════════════════════════════════════════════
//  ABOUT THE AUTHOR
// ══════════════════════════════════════════════════════════════════════════════
class _AuthorSection extends StatelessWidget {
  final Map author;
  final StoryDetailController ctrl;
  final _Palette p;
  final VoidCallback onTap;

  const _AuthorSection({
    required this.author,
    required this.ctrl,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final username = author['username']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('About the Author', p: p),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      _Avatar(author: author, radius: 26, p: p),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username.isEmpty ? 'Unknown Author' : username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.txt,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                '${_fmtCount(ctrl.followerCount.value)} Followers',
                                style: TextStyle(color: p.sub, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (username.isNotEmpty) ...[
                const SizedBox(width: 12),
                _FollowButton(ctrl: ctrl, username: username, p: p),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final StoryDetailController ctrl;
  final String username;
  final _Palette p;

  const _FollowButton({
    required this.ctrl,
    required this.username,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final following = ctrl.isFollowing.value;
      final loading = ctrl.isFollowLoading.value;
      return GestureDetector(
        onTap: loading ? null : () => ctrl.toggleFollow(username),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: following ? Colors.transparent : p.accent,
            border: Border.all(
              color: following ? p.divider : p.accent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child:
                loading
                    ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: following ? p.sub : Colors.white,
                      ),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (following) ...[
                          Icon(Icons.check_rounded, color: p.sub, size: 15),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          following ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: following ? p.sub : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  YOU MIGHT LIKE
// ══════════════════════════════════════════════════════════════════════════════
class _SimilarSection extends StatelessWidget {
  final StoryDetailController ctrl;
  final String slug;
  final _Palette p;

  const _SimilarSection({
    required this.ctrl,
    required this.slug,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.similarStories.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionGap(p: p),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: [
                _SectionTitle('You Might Like', p: p),
                const Spacer(),
                ctrl.isLoadingSimilar.value
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.accent,
                      ),
                    )
                    : _LinkAction(
                      label: 'More',
                      color: p.accent,
                      onTap: () => ctrl.refreshSimilarStories(slug),
                    ),
              ],
            ),
          ),
          SizedBox(
            height: 262,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: ctrl.similarStories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder:
                  (_, i) => _SimilarCard(
                    s: ctrl.similarStories[i] as Map,
                    coverUrl: ctrl.getCoverUrl(ctrl.similarStories[i] as Map),
                    p: p,
                  ),
            ),
          ),
        ],
      );
    });
  }
}

class _SimilarCard extends StatelessWidget {
  final Map s;
  final String coverUrl;
  final _Palette p;

  const _SimilarCard({
    required this.s,
    required this.coverUrl,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(s['average_rating']?.toString() ?? '0') ?? 0;
    final genre = s['genre'];
    final tags = s['tags'] as List?;
    final genreName =
        genre is Map
            ? genre['name']?.toString()
            : (tags?.isNotEmpty == true ? tags![0]['name']?.toString() : null);

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => StoryDetailScreen(slug: s['slug']),
            ),
          ),
      child: SizedBox(
        width: 128,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomImageView(
                    imagePath:
                        coverUrl.isNotEmpty ? coverUrl : _kPlaceholderCover,
                    width: 128,
                    height: 176,
                    fit: BoxFit.cover,
                  ),
                ),
                if (genreName != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE62C3E50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        genreName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kFontFamily,
                color: p.txt,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.star, color: Colors.amber[700], size: 13),
                const SizedBox(width: 3),
                Text(
                  '${rating.toStringAsFixed(1)} · ${s['total_chapters'] ?? 0}ch',
                  style: TextStyle(color: p.sub, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOTTOM BAR — download, listen, read / continue
// ══════════════════════════════════════════════════════════════════════════════
class _BottomBar extends StatelessWidget {
  final StoryDetailController ctrl;
  final _Palette p;
  final VoidCallback onDownload, onListen, onRead;

  const _BottomBar({
    required this.ctrl,
    required this.p,
    required this.onDownload,
    required this.onListen,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(top: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              _CircleIconButton(
                icon: LucideIcons.download,
                p: p,
                size: 52,
                onTap: onDownload,
              ),
              const SizedBox(width: 12),
              _CircleIconButton(
                icon: LucideIcons.headphones,
                p: p,
                size: 52,
                onTap: onListen,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Obx(() {
                  String label = 'READ';
                  if (ctrl.hasStarted && ctrl.chapters.isNotEmpty) {
                    final i = ctrl.resumeIndex;
                    final loadedNum = StoryDetailController.chapterNumber(
                      ctrl.chapters[i] as Map,
                      i,
                    );
                    label =
                        'CONTINUE · CH ${ctrl.chaptersComplete.value ? loadedNum : ctrl.resumeChapterNumber.clamp(1, ctrl.totalChapters.value > 0 ? ctrl.totalChapters.value : loadedNum)}';
                  }
                  return SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: onRead,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            ctrl.hasStarted
                                ? LucideIcons.circlePlay
                                : LucideIcons.menu,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SMALL PIECES
// ══════════════════════════════════════════════════════════════════════════════
class _SectionGap extends StatelessWidget {
  final _Palette p;
  const _SectionGap({required this.p});

  @override
  Widget build(BuildContext context) => Container(height: 10, color: p.gap);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final _Palette p;
  const _SectionTitle(this.text, {required this.p});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: p.txt, fontSize: 19, fontWeight: FontWeight.w700),
  );
}

class _LinkAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _LinkAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(LucideIcons.chevronRight, color: color, size: 17),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final _Palette p;
  final VoidCallback? onTap;
  final Color? iconColor;
  final double size;

  const _CircleIconButton({
    required this.icon,
    required this.p,
    this.onTap,
    this.iconColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surface,
        shape: BoxShape.circle,
        border: Border.all(color: p.divider),
      ),
      child: Icon(icon, color: iconColor ?? p.txt, size: size * 0.48),
    );
    // Without onTap the button sits inside another tap target (popup menu)
    return onTap == null
        ? circle
        : GestureDetector(onTap: onTap, child: circle);
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color fg, bg;
  final bool bold;

  const _Pill({
    required this.label,
    required this.fg,
    required this.bg,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: fg,
        fontSize: 12,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: bold ? 0.3 : 0,
      ),
    ),
  );
}

/// The user's avatar image, or their initial on the brand red.
class _Avatar extends StatelessWidget {
  final Map author;
  final double radius;
  final _Palette p;

  const _Avatar({required this.author, required this.radius, required this.p});

  @override
  Widget build(BuildContext context) {
    final name = author['username']?.toString() ?? '';
    final url = StoryDetailController.resolveUrl(author['avatar']);
    return CircleAvatar(
      radius: radius,
      backgroundColor: p.accent,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child:
          url.isEmpty
              ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.85,
                  fontWeight: FontWeight.w700,
                ),
              )
              : null,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  EXPANDABLE TEXT
// ══════════════════════════════════════════════════════════════════════════════
class _ExpandableText extends StatefulWidget {
  final String text;
  final _Palette p;
  const _ExpandableText({required this.text, required this.p});
  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const _collapsedLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final style = TextStyle(
      color: p.sub,
      fontFamily: kFontFamily,
      fontSize: 16,
      height: 1.6,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Only offer "Show more" when the text actually overflows
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : _collapsedLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: style,
            ),
            if (overflows) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Show less' : 'Show more',
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      color: p.accent,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  LOADING / ERROR
// ══════════════════════════════════════════════════════════════════════════════
class _DetailSkeleton extends StatelessWidget {
  final _Palette p;
  const _DetailSkeleton({required this.p});

  Widget _box(double w, double h, {double r = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: p.surface,
      borderRadius: BorderRadius.circular(r),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CircleIconButton(
              icon: LucideIcons.chevronLeft,
              p: p,
              onTap: () => Get.back(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(112, 160, r: 10),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(double.infinity, 20),
                        const SizedBox(height: 8),
                        _box(140, 20),
                        const SizedBox(height: 16),
                        _box(110, 14),
                        const SizedBox(height: 12),
                        _box(150, 14),
                        const SizedBox(height: 12),
                        _box(80, 22, r: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            for (final w in [1.0, 1.0, 1.0, 0.6]) ...[
              FractionallySizedBox(widthFactor: w, child: _box(0, 14)),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final _Palette p;
  final bool failed;
  final VoidCallback onRetry;
  const _LoadError({
    required this.p,
    required this.failed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _CircleIconButton(
                icon: LucideIcons.chevronLeft,
                p: p,
                onTap: () => Get.back(),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.bookX, color: p.sub, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    failed ? "Couldn't load this story" : 'Story not found',
                    style: TextStyle(
                      color: p.txt,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(
                      'Try again',
                      style: TextStyle(
                        color: p.accent,
                        fontWeight: FontWeight.w600,
                      ),
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
}

// ══════════════════════════════════════════════════════════════════════════════
//  REPORT SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _ReportSheet extends StatefulWidget {
  final String slug;
  final _Palette p;
  const _ReportSheet({required this.slug, required this.p});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = [
    {'value': 'sexual', 'label': 'Sexual or explicit content'},
    {'value': 'violence', 'label': 'Graphic violence'},
    {'value': 'hate', 'label': 'Hate speech or harassment'},
    {'value': 'copyright', 'label': 'Copyright infringement'},
    {'value': 'spam', 'label': 'Spam or misleading'},
    {'value': 'other', 'label': 'Other'},
  ];

  String _reason = 'sexual';
  final _detailsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final res = await ApiService.reportStory(
      widget.slug,
      reason: _reason,
      details: _detailsCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      Navigator.pop(context);
      AppAlert.success(
        'Report submitted — thank you, our editorial team will review this.',
      );
    } else {
      AppAlert.error(res['error']?.toString() ?? 'Could not submit report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                color: Colors.redAccent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Report this story',
                style: TextStyle(
                  color: p.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us what\'s wrong — our editorial team reviews every report.',
            style: TextStyle(color: p.sub, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _reason,
                isExpanded: true,
                dropdownColor: p.surface,
                style: TextStyle(color: p.txt, fontSize: 13),
                items:
                    _reasons
                        .map(
                          (r) => DropdownMenuItem(
                            value: r['value'],
                            child: Text(r['label']!),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsCtrl,
            maxLines: 3,
            style: TextStyle(color: p.txt, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Additional details (optional)…',
              hintStyle: TextStyle(color: p.sub),
              filled: true,
              fillColor: p.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : _submit,
              child:
                  _submitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Submit report',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
