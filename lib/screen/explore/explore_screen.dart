import 'dart:async';
import 'dart:developer' as myLog;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/screen/explore/ranking_more_screen.dart';
import 'package:novelux/screen/explore/genre_section_more_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/language_controller.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/screen/explore/controller/explore_controller.dart';
import 'package:novelux/screen/explore/search.dart';
import 'package:novelux/screen/reward_screen/reward_screen.dart';
import 'package:novelux/screen/view_all_screen/view_all_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';

class FeaturedCarouselSection extends StatefulWidget {
  const FeaturedCarouselSection({
    super.key,
    required this.stories,
    required this.txt,
    required this.cardBg,
    required this.carouselController,
    required this.coverUrlBuilder,
    required this.onStoryTap,
    this.isLoading = false,
  });

  final List<dynamic> stories;
  final Color txt;
  final Color cardBg;
  final CarouselSliderController carouselController;
  final String Function(Map<dynamic, dynamic> story) coverUrlBuilder;
  final ValueChanged<Map<dynamic, dynamic>> onStoryTap;
  final bool isLoading;

  @override
  State<FeaturedCarouselSection> createState() =>
      _FeaturedCarouselSectionState();
}

class _FeaturedCarouselSectionState extends State<FeaturedCarouselSection> {
  int _currentIndex = 0;

  Widget _bookPlaceholder() => CustomImageView(
    imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
    width: 60,
    height: 80,
    fit: BoxFit.cover,
  );

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.stories.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.stories.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.16)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_outlined, color: depperBlue, size: 28),
                const SizedBox(height: 8),
                Text(
                  'Featured stories will appear soon',
                  style: TextStyle(
                    color: widget.txt,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check back shortly for weekly highlights.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.txt.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stories = widget.stories;
    return Stack(
      children: [
        CarouselSlider.builder(
          carouselController: widget.carouselController,
          itemCount: stories.length,
          options: CarouselOptions(
            height: 180,
            viewportFraction: 1.0,
            autoPlay: false,
            enableInfiniteScroll: true,
            enlargeCenterPage: false,
            scrollPhysics: const ClampingScrollPhysics(),
            onPageChanged: (i, _) => setState(() => _currentIndex = i),
          ),
          itemBuilder: (_, i, __) {
            final story = stories[i] as Map<dynamic, dynamic>;
            final coverUrl = widget.coverUrlBuilder(story);
            return GestureDetector(
              onTap: () => widget.onStoryTap(story),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverUrl.isNotEmpty
                      ? CustomImageView(imagePath: coverUrl, fit: BoxFit.cover)
                      : _bookPlaceholder(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'section_weekly_featured'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: depperBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (story['total_views'] != null)
                            Text(
                              '${story['total_views']} Views  ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            '${story['average_rating']} ⭐',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          story['description'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(stories.length, (d) {
              final active = d == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final ExploreController ctrl;
  int _rankingIndex = 0;
  int _rankingsSectionIndex = 0;
  int _bannerIndex = 0;
  PageController? _bannerCtrl;
  final CarouselSliderController _featuredCarouselCtrl =
      CarouselSliderController();
  Timer? _featuredTimer;
  late final ScrollController _hotScrollCtrl;
  late final PageController _genrePageCtrl;
  int _selectedGenreTab = 0;
  String _rankingNrFilter = 'daily';
  String _rankingMrFilter = 'must-read';
  static const _rankingPeriods = ['all-time', 'monthly', 'weekly', 'daily'];
  static const _rankingLabelKeys = [
    'tab_all_time',
    'tab_monthly',
    'tab_weekly',
    'tab_daily',
  ];
  static const _genreTabs = [
    '🔥 Hot',
    '🐺 Werewolf',
    '💎 Billionaire',
    '📖 Short Fics',
    '🏆 Ranking',
    '💕 For Her',
    '💪 For Him',
    '😱 Suspense',
  ];
  static const _genreSlugs = [
    '',
    'werewolf',
    'billionaire',
    'short-fics',
    'ranking',
    'for-her',
    'for-him',
    'suspense',
  ];

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(ExploreController());
    _bannerCtrl = PageController(viewportFraction: 1.0);
    _genrePageCtrl = PageController();
    _hotScrollCtrl = ScrollController()..addListener(_onHotScrollChanged);
    // Auto-advance banner every 5s
    Future.delayed(const Duration(seconds: 1), _autoAdvanceBanner);
    // Start featured auto-advance after data may have loaded
    Future.delayed(const Duration(seconds: 2), _startFeaturedTimer);
  }

  // ── Featured carousel auto-advance ───────────────────────────────────────
  void _startFeaturedTimer() {
    if (!mounted) return;
    _featuredTimer?.cancel();
    _featuredTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (mounted && ctrl.featured.isNotEmpty) {
        try {
          await _featuredCarouselCtrl.nextPage();
        } catch (_) {}
      }
    });
  }

  void _stopFeaturedTimer() {
    _featuredTimer?.cancel();
    _featuredTimer = null;
  }

  void _onHotScrollChanged() {
    // Featured carousel is ~260px tall at the top.
    // Stop auto-sliding when it's scrolled off screen.
    const threshold = 260.0;
    if (_hotScrollCtrl.offset > threshold) {
      if (_featuredTimer != null) _stopFeaturedTimer();
    } else {
      if (_featuredTimer == null) _startFeaturedTimer();
    }
  }

  void _autoAdvanceBanner() {
    myLog.log('Auto-advancing banner: current index $_bannerIndex');
    if (!mounted || _bannerCtrl == null) return;
    final count = ctrl.promoBanners.length;
    if (count == 0) {
      Future.delayed(const Duration(seconds: 5), _autoAdvanceBanner);
      return;
    }
    final next = (_bannerIndex + 1) % count;
    try {
      _bannerCtrl!.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } catch (_) {}
    Future.delayed(const Duration(seconds: 5), _autoAdvanceBanner);
  }

  @override
  void dispose() {
    _bannerCtrl?.dispose();
    _genrePageCtrl.dispose();
    _hotScrollCtrl.dispose();
    _featuredTimer?.cancel();
    super.dispose();
  }

  void _showLanguagePicker(
    BuildContext context,
    Color txt,
    bool isDark,
    Color cardBg,
  ) {
    final langCtrl = Get.find<LanguageController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Obx(() {
            final current = langCtrl.locale;
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'select_language'.tr,
                      style: TextStyle(
                        color: txt,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      children:
                          LanguageController.supportedLanguages.map((lang) {
                            final selected =
                                current.languageCode == lang.languageCode &&
                                current.countryCode == lang.countryCode;
                            return ListTile(
                              leading: Text(
                                lang.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                lang.nameNative,
                                style: TextStyle(
                                  color: txt,
                                  fontWeight:
                                      selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                ),
                              ),
                              subtitle: Text(
                                lang.nameEn,
                                style: TextStyle(
                                  color: txt.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                              trailing:
                                  selected
                                      ? Icon(
                                        Icons.check_circle_rounded,
                                        color: depperBlue,
                                      )
                                      : null,
                              onTap: () {
                                langCtrl.changeLanguage(lang.locale);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),
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
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        depperBlue.withOpacity(isDark ? 0.0 : 0.34),
                        const Color.fromARGB(3, 193, 96, 60),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          MediaQuery.of(context).padding.top,
                          16,
                          0,
                        ),
                        child: Row(
                          spacing: 8,
                          children: [
                            CustomImageView(
                              radius: BorderRadius.circular(8),
                              imagePath: 'assets/images/1024.png',
                              width: 30,
                              height: 30,
                              placeHolder:
                                  'assets/images/novelux_placeholder_transcpr.jpg',
                            ),
                            Text(
                              'NoveluX',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: depperBlue,
                                fontFamily: kFontFamily,
                              ),
                            ),
                            Spacer(),
                            // ── Language picker button ─────────────────────
                            GestureDetector(
                              onTap:
                                  () => _showLanguagePicker(
                                    context,
                                    txt,
                                    isDark,
                                    cardBg,
                                  ),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: depperBlue.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.language_rounded,
                                  size: 18,
                                  color: depperBlue,
                                ),
                              ),
                            ),
                            // ── Check-in button ────────────────────────────
                            GestureDetector(
                              onTap: () => Get.to(() => RewardsScreen()),
                              child: Container(
                                margin: EdgeInsets.all(8),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: depperBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(LucideIcons.gift500),
                                    Positioned(
                                      top: 20,
                                      child: Container(
                                        padding: EdgeInsets.all(3),
                                        margin: EdgeInsets.only(right: 16),
                                        decoration: BoxDecoration(
                                          color: depperBlue,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'btn_check_in'.tr,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontFamily: kFontFamily,
                                              fontWeight: FontWeight.w500,
                                              color: txt,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Search bar ────────────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap:
                                    () => Get.to(
                                      () => const SearchScreen(),
                                      transition: Transition.cupertino,
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search, color: onBg, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: AnimatedTextKit(
                                          repeatForever: true,
                                          animatedTexts:
                                              [
                                                    'Search novels, authors, genres...',
                                                    'The Ashboard Crown',
                                                    'Sweet chaos',
                                                    "Luna's betrayal",
                                                    'Unexpected desires',
                                                  ]
                                                  .map(
                                                    (t) => FadeAnimatedText(
                                                      t,
                                                      textStyle: TextStyle(
                                                        color: txt,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      duration: const Duration(
                                                        milliseconds: 4500,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
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
                      const SizedBox(height: 10),
                      // ── Genre tab bar ─────────────────────────────────────────────────
                      _buildGenreTabBar(isDark, txt, sub),
                      // ── Paged body ────────────────────────────────────────────────────
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // // ── Genre tab bar ─────────────────────────────────────────────────
                // _buildGenreTabBar(isDark, txt, sub),
                // // ── Paged body ────────────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _genrePageCtrl,
                    onPageChanged: (i) => setState(() => _selectedGenreTab = i),
                    itemCount: _genreTabs.length,
                    itemBuilder: (_, pageIdx) {
                      if (pageIdx != 0) {
                        return _buildGenrePage(
                          _genreSlugs[pageIdx],
                          _genreTabs[pageIdx],
                          isDark,
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: ctrl.fetchAll,
                        color: depperBlue,
                        // KEY FIX: Use CustomScrollView with SliverList — no nested scrollviews
                        child: CustomScrollView(
                          controller: _hotScrollCtrl,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            // ── Featured carousel ────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () => _buildFeaturedCarousel(txt, cardBg),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── For You ──────────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: _sectionWidget(
                                'section_for_you'.tr,
                                cardBg,
                                onBg,
                                txt,
                                Column(
                                  children: [
                                    // Preferred genre tabs
                                    _forYouTabs(),
                                    const SizedBox(height: 12),
                                    Obx(
                                      () =>
                                          ctrl.isLoadingForYou.value
                                              ? _shimmerRow()
                                              : ctrl.forYou.isEmpty
                                              ? _emptyState(
                                                'empty_no_stories'.tr,
                                              )
                                              : _storyRow(
                                                ctrl.forYou,
                                                txt,
                                                heroSection: 'foryou',
                                              ),
                                    ),
                                  ],
                                ),
                                onViewAll:
                                    () => Get.to(
                                      () => ViewAllScreen(
                                        section: SectionType.forYou,
                                      ),
                                      arguments: 'For You',
                                    ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Promo banner (PageView — smooth, no conflict) ────────────
                            Obx(
                              () => SliverToBoxAdapter(
                                child:
                                    ctrl.isLoadingBanners.value
                                        ? SizedBox.shrink()
                                        : _buildPromoBanner(),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Best Novels ──────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: _sectionWidget(
                                'section_best_novels'.tr,
                                cardBg,
                                onBg,
                                txt,
                                Column(
                                  children: [
                                    _tabRow(
                                      [
                                        'tab_most_read'.tr,
                                        'tab_most_engaging'.tr,
                                        'tab_top_rated'.tr,
                                        'tab_top_buzz'.tr,
                                        'tab_top_earners'.tr,
                                        'tab_top_completed'.tr,
                                      ],
                                      _rankingIndex,
                                      (i) {
                                        setState(() => _rankingIndex = i);
                                        const sortKeys = [
                                          'views',
                                          'comments',
                                          'ratings',
                                          'topBuzz',
                                          'tips',
                                          'status',
                                        ];
                                        ctrl.fetchBestNovels(sortKeys[i]);
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Obx(
                                      () =>
                                          ctrl.isLoadingBestNovels.value ||
                                                  ctrl.bestNovels.isEmpty
                                              ? _shimmerRow(height: 300)
                                              : _rankingsList(
                                                ctrl.bestNovels,
                                                txt,
                                                sub,
                                              ),
                                    ),
                                  ],
                                ),
                                onViewAll: () {
                                  const sortKeys = [
                                    'views',
                                    'comments',
                                    'ratings',
                                    'topBuzz',
                                    'tips',
                                    'status',
                                  ];
                                  Get.to(
                                    () => ViewAllScreen(
                                      section: SectionType.bestNovel,
                                      sortBy: sortKeys[_rankingIndex],
                                    ),
                                    arguments: 'Best Novels',
                                  );
                                },
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Trending ─────────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingTrending.value
                                        ? _shimmerRow()
                                        : ctrl.trending.isEmpty
                                        ? SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_trending'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _storyRow(
                                            ctrl.trending,
                                            txt,
                                            heroSection: 'trending',
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section: SectionType.trending,
                                                ),
                                                arguments: 'Trending Now',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Completed ────────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingCompletedStories.value
                                        ? _shimmerRow()
                                        : ctrl.completedStories.isEmpty
                                        ? SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_completed'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _storyRow(
                                            ctrl.completedStories,
                                            txt,
                                            heroSection: 'completed',
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType.completed,
                                                ),
                                                arguments: 'Completed Stories',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── World Famous ─────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingworldFamous.value
                                        ? _shimmerRow()
                                        : ctrl.worldFamous.isEmpty
                                        ? SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_world_famous'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _storyRow(
                                            ctrl.worldFamous,
                                            txt,
                                            heroSection: 'world',
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType.worldFamous,
                                                ),
                                                arguments: 'World Famous',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Free Download ─────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingFreeDownlaod.value
                                        ? _shimmerRow()
                                        : ctrl.freeDownLoad.isEmpty
                                        ? SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_free_download'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _storyRow(
                                            ctrl.freeDownLoad,
                                            txt,
                                            heroSection: 'freedl',
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType.freeDownload,
                                                ),
                                                arguments: 'Free Download',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── African Folk Tale ─────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingAfricanFolkTale.value
                                        ? _shimmerRow()
                                        : ctrl.africanfolktale.isEmpty
                                        ? SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_african_folktale'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _storyRow(
                                            ctrl.africanfolktale,
                                            txt,
                                            heroSection: 'folktale',
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType
                                                          .africanFolktale,
                                                ),
                                                arguments: 'African Folk Tale',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Editor's Pick ─────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingEditors.value
                                        ? _shimmerRow()
                                        : ctrl.editorsPick.isEmpty
                                        ? SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_editors_pick'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _storyRow(
                                            ctrl.editorsPick,
                                            txt,
                                            heroSection: 'editors',
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType.editorsPick,
                                                ),
                                                arguments: "Editor's Pick",
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── New Arrivals ──────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingNewArrivals.value
                                        ? _shimmerRow(height: 220)
                                        : ctrl.newArrivals.isEmpty
                                        ? const SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_new_arrivals'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _newArrivalsFeatured(
                                            ctrl.newArrivals,
                                            txt,
                                            sub,
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType.newArrivals,
                                                ),
                                                arguments: 'New Arrivals',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Recommended For You ───────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingRecommended.value
                                        ? _shimmerRow()
                                        : ctrl.recommended.isEmpty
                                        ? const SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_recommended'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _storyRow(
                                            ctrl.recommended,
                                            txt,
                                            heroSection: 'recommended',
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType.recommended,
                                                ),
                                                arguments:
                                                    'Recommended For You',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Short Stories ─────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingShortStories.value
                                        ? _shimmerRow()
                                        : ctrl.shortStories.isEmpty
                                        ? const SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_short_stories'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _storyRow(
                                            ctrl.shortStories,
                                            txt,
                                            badgeLabel: 'Short',
                                            heroSection: 'short',
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType.shortStories,
                                                ),
                                                arguments: 'Short Stories',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Free & Discount ───────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingFreeDiscount.value
                                        ? _shimmerRow()
                                        : ctrl.freeDiscount.isEmpty
                                        ? const SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_free_discount'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _freeDiscountSection(
                                            ctrl.freeDiscount,
                                            txt,
                                            sub,
                                          ),
                                          onViewAll:
                                              () => Get.to(
                                                () => ViewAllScreen(
                                                  section:
                                                      SectionType.freeDiscount,
                                                ),
                                                arguments: 'Free & Discount',
                                              ),
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Rankings ──────────────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: _sectionWidget(
                                'section_rankings'.tr,
                                cardBg,
                                onBg,
                                txt,
                                _rankingsSection(txt, sub),
                                onViewAll:
                                    () => Get.to(
                                      () => ViewAllScreen(
                                        section: SectionType.rankings,
                                        sortBy:
                                            _rankingPeriods[_rankingsSectionIndex],
                                      ),
                                      arguments: 'Rankings',
                                    ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Author Spotlight ──────────────────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingAuthorSpotlight.value
                                        ? _shimmerRow()
                                        : ctrl.authorSpotlight.value.isEmpty
                                        ? const SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_author_spotlight'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _authorSpotlightSection(txt, sub),
                                          showViewAll: false,
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),

                            // ── Featured For You (list style) ─────────────────────────────
                            SliverToBoxAdapter(
                              child: Obx(
                                () =>
                                    ctrl.isLoadingFeatured.value
                                        ? _shimmerRow()
                                        : ctrl.featured.isEmpty
                                        ? SizedBox.shrink()
                                        : _sectionWidget(
                                          'section_featured_for_you'.tr,
                                          cardBg,
                                          onBg,
                                          txt,
                                          _featuredList(
                                            ctrl.featured,
                                            txt,
                                            sub,
                                          ),
                                          showViewAll: false,
                                        ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── For You tabs (preferred genres) ──────────────────────────────────────
  Widget _forYouTabs() => Obx(() {
    final tabs = ctrl.preferredGenres;
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final tab = tabs[i];
          // Prettify slug label
          final label = tab.toString().replaceAll('-', ' ').capitalize;

          final sel =
              ctrl.selectedForYouTab.value ==
              tab.replaceAll('-', ' ').capitalize;
          return GestureDetector(
            onTap: () {
              ctrl.filterForYou(label);
              setState(() {});
              print("atb ${tab.replaceAll('-', ' ')}");
              print(
                'Filtering For You byx: $tab, ${tabs[i]}; selected: ${ctrl.selectedForYouTab.value}',
              );
              //  setState(() => ctrl.selectedForYouTab.value = tab.toString());
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? depperBlue : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label!,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  });

  // ── Promo banner — PageView (smooth, doesn't steal scrolling) ────────────
  Widget _buildPromoBanner() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 100,
        child: Stack(
          children: [
            PageView.builder(
              controller: _bannerCtrl,
              itemCount:
                  ctrl.promoBanners.isEmpty ? 3 : ctrl.promoBanners.length,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemBuilder: (_, i) {
                List<dynamic> bannerList =
                    ctrl.promoBanners.isEmpty
                        ? ExploreController.defaultBanners
                        : ctrl.promoBanners;
                final banner = bannerList[i];
                return GestureDetector(
                  onTap: () {
                    final slug = banner['slug'] as String;
                    if (slug.isNotEmpty) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => StoryDetailScreen(slug: slug),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _bannerImage(banner),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 12,
                        child: Text(
                          banner['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Dot indicators
            Positioned(
              bottom: 8,
              right: 12,
              child: Row(
                children: List.generate(
                  (ctrl.promoBanners.isEmpty ? 3 : ctrl.promoBanners.length),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 4),
                    width: _bannerIndex == i ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _bannerIndex == i ? depperBlue : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildFeaturedCarousel(Color txt, Color cardbg) {
    return FeaturedCarouselSection(
      stories: ctrl.featured,
      txt: txt,
      cardBg: cardbg,
      carouselController: _featuredCarouselCtrl,
      isLoading: ctrl.isLoadingFeatured.value,
      coverUrlBuilder: (story) => ctrl.getCoverUrl(story),
      onStoryTap: (story) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => StoryDetailScreen(slug: story['slug']),
          ),
        );
      },
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _sectionWidget(
    String title,
    Color cardbg,
    Color onbg,
    Color txt,
    Widget child, {
    VoidCallback? onViewAll,
    bool showViewAll = true,
  }) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withOpacity(0.2)),
      color: cardbg,
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: depperBlue,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: txt,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (showViewAll && onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Row(
                    children: [
                      Text(
                        'btn_view_all'.tr,
                        style: TextStyle(color: txt, fontSize: 12),
                      ),
                      Icon(Icons.chevron_right, color: onbg, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
        child,
        const SizedBox(height: 10),
      ],
    ),
  );

  Widget _tabRow(List<String> tabs, int selected, Function(int) onTap) =>
      SizedBox(
        height: 28,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16),
          itemCount: tabs.length,
          itemBuilder: (_, i) {
            final sel = i == selected;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sel ? depperBlue : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: sel ? Colors.white : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _storyRow(
    RxList stories,
    Color txt, {
    String? badgeLabel,
    String heroSection = 'section',
  }) => SizedBox(
    height: 200,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: stories.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (_, i) {
        final story = stories[i];
        final slug = story['slug'] as String? ?? '';
        final heroTag = 'hero-$heroSection-$slug';
        final coverUrl = ctrl.getCoverUrl(story);
        final tags = (story['tags'] as List? ?? []);
        return GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder:
                      (_) => StoryDetailScreen(slug: slug, heroTag: heroTag),
                ),
              ),
          child: SizedBox(
            width: 100,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 120,
                          width: 100,
                          child:
                              coverUrl.isNotEmpty
                                  ? Hero(
                                    tag: heroTag,
                                    child: CustomImageView(
                                      imagePath: coverUrl,
                                      height: 120,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : _bookPlaceholder(),
                        ),
                      ),
                      if (badgeLabel != null)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeLabel,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story['title'] ?? '',
                    style: TextStyle(
                      color: txt,
                      fontSize: 10,
                      fontFamily: kFontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tags.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: depperBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tags[0]['name'] ?? '',
                        style: TextStyle(
                          color: depperBlue,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _rankingsList(RxList stories, Color txt, Color sub) => SizedBox(
    height: 330,
    child: GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemCount: stories.length > 9 ? 9 : stories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 2.4 / 4.7,
        crossAxisCount: 3,
      ),
      itemBuilder: (_, i) {
        final story = stories[i];
        final coverUrl = ctrl.getCoverUrl(story);
        final tags = (story['tags'] as List? ?? []);
        final rankingsSlug = story['slug'] as String? ?? '';
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder:
                        (_) => StoryDetailScreen(
                          slug: rankingsSlug,
                          heroTag: 'hero-rankings-$rankingsSlug',
                        ),
                  ),
                ),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 75,
                        //height: 130,
                        child:
                            coverUrl.isNotEmpty
                                ? Hero(
                                  tag: 'hero-rankings-$rankingsSlug',
                                  child: CustomImageView(
                                    // height: 130,
                                    // width: 10,
                                    imagePath: coverUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : _bookPlaceholder(),
                      ),
                    ),
                    Positioned(
                      child: Container(
                        width: 16,
                        height: 20,
                        decoration: BoxDecoration(
                          color: i < 3 ? depperBlue : const Color(0xFFA9AA6C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        story['title'] ?? '',
                        style: TextStyle(
                          color: txt,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story['description'] ?? '',
                        style: TextStyle(
                          color: sub,
                          fontSize: 9,
                          fontFamily: kFontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${double.tryParse(story['average_rating'].toString())?.toStringAsFixed(1) ?? '0.0'}',
                            style: TextStyle(color: sub, fontSize: 10),
                          ),
                          const Icon(Icons.star, color: Colors.amber, size: 10),
                          const SizedBox(width: 6),
                          Text(
                            '${story['total_views'] ?? 0} views',
                            style: TextStyle(color: sub, fontSize: 10),
                          ),
                        ],
                      ),
                      if (tags.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: depperBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tags[0]['name'] ?? '',
                            style: TextStyle(
                              color: depperBlue,
                              fontSize: 10,

                              fontWeight: FontWeight.w700,
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
    ),
  );

  Widget _featuredList(RxList stories, txt, sub) => Column(
    children:
        stories.
        //take(6).
        map((story) {
          final coverUrl = ctrl.getCoverUrl(story);
          final featuredSlug = story['slug'] as String? ?? '';
          final tags = (story['tags'] as List? ?? []);
          return GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder:
                        (_) => StoryDetailScreen(
                          slug: featuredSlug,
                          heroTag: 'hero-featured-$featuredSlug',
                        ),
                  ),
                ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 75,
                      height: 100,
                      child:
                          coverUrl.isNotEmpty
                              ? Hero(
                                tag: 'hero-featured-$featuredSlug',
                                child: CustomImageView(
                                  imagePath: coverUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : _bookPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story['title'] ?? '',
                          style: TextStyle(
                            color: txt,
                            fontSize: 14,
                            fontFamily: kFontFamily,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story['description'] ?? '',
                          style: TextStyle(
                            color: sub,
                            fontSize: 12,
                            fontFamily: kFontFamily,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${double.tryParse(story['average_rating'].toString())?.toStringAsFixed(1) ?? '0.0'}',
                              style: TextStyle(color: sub, fontSize: 11),
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${story['total_views'] ?? 0} views',
                              style: TextStyle(color: sub, fontSize: 11),
                            ),
                          ],
                        ),
                        if (tags.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children:
                                tags
                                    .take(2)
                                    .map(
                                      (t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: depperBlue.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                    )
                                    .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
  );

  Widget _bannerImage(dynamic banner) {
    final img = ctrl.getBannerImageUrl(banner as Map);
    if (img.isEmpty) {
      return Container(
        color: const Color(0xFF2a2a2a),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 32),
        ),
      );
    }
    if (img.startsWith('assets/')) {
      return Image.asset(img, fit: BoxFit.cover);
    }
    return CustomImageView(imagePath: img, fit: BoxFit.cover);
  }

  Widget _shimmerRow({double height = 160}) => Shimmer(
    gradient: LinearGradient(
      colors: [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!],
      stops: const [0.1, 0.3, 0.4],
      begin: const Alignment(-1, -0.3),
      end: const Alignment(1, 0.3),
    ),
    child: SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder:
            (_, __) => Container(
              width: 90,
              height: height,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
      ),
    ),
  );

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(
        msg,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    ),
  );

  Widget _bookPlaceholder() =>
  // Container(
  //   color: const Color(0xFF2A2A2A),
  //   child: const Center(child: Icon(Icons.book, color: Colors.grey, size: 30)),
  // );
  CustomImageView(
    imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
    width: 60,
    height: 80,
    fit: BoxFit.cover,
  );

  // ── New Arrivals — featured first card + horizontal scroll ───────────────
  // ── New Arrivals — swipeable carousel ────────────────────────────────────
  Widget _newArrivalsFeatured(RxList stories, Color txt, Color sub) {
    if (stories.isEmpty) return const SizedBox.shrink();
    return _NewArrivalCarousel(
      stories: stories,
      txt: txt,
      sub: sub,
      ctrl: ctrl,
    );
  }

  // ── Free & Discount — gradient banner + story row ─────────────────────────
  Widget _freeDiscountSection(RxList stories, Color txt, Color sub) => Column(
    children: [
      // 24 Hours Free banner
      Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1060), Color(0xFF3d1fa3)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'free_24h'.tr,
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'free_24h_sub'.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _storyRow(stories, txt, heroSection: 'freediscount'),
    ],
  );

  // ── Rankings — cached tabs (Daily / Weekly / Monthly / All Time) ──────────
  Widget _rankingsSection(Color txt, Color sub) => Column(
    children: [
      _tabRow(
        _rankingLabelKeys.map((k) => k.tr).toList(),
        _rankingsSectionIndex,
        (i) {
          setState(() => _rankingsSectionIndex = i);
          ctrl.fetchRankings(_rankingPeriods[i]);
        },
      ),
      const SizedBox(height: 10),
      Obx(() {
        if (ctrl.isLoadingRankings.value) return _shimmerRow(height: 300);
        final list = ctrl.currentRankingsList;
        return list.isEmpty
            ? _emptyState('No rankings yet')
            : _rankingsList(list, txt, sub);
      }),
    ],
  );

  // ── Author Spotlight — author header + their top books ────────────────────
  Widget _authorSpotlightSection(Color txt, Color sub) {
    final data = ctrl.authorSpotlight.value;
    final user = data['user'] as Map? ?? {};
    final headline = data['headline'] as String? ?? '';
    final stories = (data['stories'] as List? ?? []);
    final avatarRaw = user['avatar']?.toString() ?? '';
    final avatarUrl =
        avatarRaw.startsWith('http')
            ? avatarRaw
            : avatarRaw.isNotEmpty
            ? 'http://10.0.2.2:8000$avatarRaw'
            : '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: depperBlue.withOpacity(0.2),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child:
                    avatarUrl.isEmpty
                        ? Text(
                          (user['username'] as String? ?? 'A')[0].toUpperCase(),
                          style: TextStyle(
                            color: depperBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['username'] ?? '',
                          style: TextStyle(
                            color: txt,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: kFontFamily,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.verified, color: depperBlue, size: 14),
                      ],
                    ),
                    if (headline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: sub, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (stories.isNotEmpty)
          _storyRow(RxList.from(stories), txt, heroSection: 'spotlight'),
      ],
    );
  }

  // ── Genre tab bar (top-level page switcher) ──────────────────────────────
  Widget _buildGenreTabBar(bool isDark, Color txt, Color sub) {
    final inactiveBorder =
        isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06);
    return Container(
      height: 48,
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _genreTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = i == _selectedGenreTab;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: sel ? depperBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: sel ? depperBlue : inactiveBorder),
              boxShadow:
                  sel
                      ? [
                        BoxShadow(
                          color: depperBlue.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  if (_selectedGenreTab == i) return;
                  setState(() => _selectedGenreTab = i);
                  _genrePageCtrl.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                  if (i > 0) ctrl.fetchGenreTab(_genreSlugs[i]);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  alignment: Alignment.center,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: sel ? Colors.white : sub,
                      fontSize: sel ? 13.5 : 12.5,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                      fontFamily: kFontFamily,
                    ),
                    child: Text(_genreTabs[i]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Genre page (Werewolf, Billionaire, Short Fics, etc.) ─────────────────
  Widget _buildGenrePage(String slug, String label, bool isDark) {
    final cardBg =
        isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final onBg = !isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);

    // Kick off a fetch the first time this page is built (cached after that)
    ctrl.fetchGenreTab(slug);

    return RefreshIndicator(
      onRefresh: () async {
        ctrl.invalidateGenreTab(slug);
        await ctrl.fetchGenreTab(slug);
      },
      color: depperBlue,
      child: Obx(() {
        final isLoading = ctrl.genreTabLoading.contains(slug);
        final data = ctrl.genreTabCache[slug];

        // ── Loading state ─────────────────────────────────────────────────
        if (isLoading && data == null) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _shimmerRow(height: 220)),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(child: _shimmerRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(child: _shimmerRow()),
            ],
          );
        }

        // ── Empty / error state ───────────────────────────────────────────
        if (data == null) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverFillRemaining(
                child: Center(
                  child: _emptyState('Nothing here yet — pull to refresh'),
                ),
              ),
            ],
          );
        }

        final layout = data['layout'] as String? ?? 'sections';
        final sections = (data['sections'] as List? ?? []).cast<Map>();

        // ── genre-grid layout (Short Fics: grouped by sub-genre) ──────────
        if (layout == 'genre-grid') {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              for (final sec in sections) ...[
                SliverToBoxAdapter(
                  child: _sectionWidget(
                    '${sec['emoji'] ?? ''} ${sec['name'] ?? ''}',
                    cardBg,
                    onBg,
                    txt,
                    Column(
                      children: [
                        if (sec['featured'] != null)
                          _genreHeroCard(sec['featured'], txt, sub),
                        if ((sec['stories'] as List? ?? []).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _storyRowFromList(
                            (sec['stories'] as List).cast<Map>(),
                            txt,
                          ),
                        ],
                      ],
                    ),
                    onViewAll: () {},
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }

        // ── ranking layout (New Releases + Most Read + Short Stories) ────
        if (layout == 'ranking') {
          return _buildRankingPage(data, isDark, txt, sub, cardBg, onBg);
        }

        // ── sections layout (Werewolf, Billionaire, For Her, etc.) ────────
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            for (final sec in sections) ...[
              SliverToBoxAdapter(
                child: _buildGenreSection(sec, slug, cardBg, onBg, txt, sub),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      }),
    );
  }

  // ── Single section card inside a genre/gender tab page ──────────────────
  Widget _buildGenreSection(
    Map sec,
    String tabSlug,
    Color cardBg,
    Color onBg,
    Color txt,
    Color sub,
  ) {
    final name = sec['name'] as String? ?? '';
    final secSlug =
        sec['slug'] as String? ?? name.toLowerCase().replaceAll(' ', '-');
    final display = sec['display'] as String? ?? 'hero';
    final featured = sec['featured'];
    final stories = (sec['stories'] as List? ?? []).cast<Map>();
    final allStories =
        featured != null ? [featured as Map, ...stories] : stories;

    Widget content;
    if (secSlug == 'completed-classics' || secSlug == 'the-ends') {
      // Vertical list with EXCERPT: label
      content = _genreClassicsList(allStories, txt, sub);
    } else if (display == 'row') {
      // Horizontal scroll row only — no hero card (Editor's Picks, Fresh Drops, etc.)
      content =
          stories.isNotEmpty
              ? _storyRowFromList(stories, txt)
              : const SizedBox.shrink();
    } else if (display == 'hero-list') {
      // Vertical list with desc + views + tag (Stars of Tomorrow)
      content = _shortStoriesVerticalList(allStories, txt, sub);
    } else {
      // Default hero layout: hero card + horizontal row
      content = Column(
        children: [
          if (featured != null) _genreHeroCard(featured, txt, sub),
          if (stories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _storyRowFromList(stories, txt),
          ],
        ],
      );
    }

    return _sectionWidget(
      name,
      cardBg,
      onBg,
      txt,
      content,
      onViewAll:
          () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder:
                  (_) => GenreSectionMoreScreen(
                    tab: tabSlug,
                    section: secSlug,
                    title: name,
                    isClassics:
                        secSlug == 'completed-classics' ||
                        secSlug == 'the-ends',
                  ),
            ),
          ),
    );
  }

  // ── Ranking page: New Releases + Most Read + Short Stories ──────────────
  Widget _buildRankingPage(
    Map data,
    bool isDark,
    Color txt,
    Color sub,
    Color cardBg,
    Color onBg,
  ) {
    final newReleases = (data['new_releases'] as Map?) ?? {};
    final mostRead = (data['most_read'] as Map?) ?? {};
    final shortStories = (data['short_stories'] as List?) ?? [];

    // State fields _rankingNrFilter / _rankingMrFilter live on this State object.
    // Reading them here and calling setState() keeps the whole Obx() reactive.
    {
      final nrFilter = _rankingNrFilter;
      final mrFilter = _rankingMrFilter;

      List<Map> nrStories =
          ((newReleases[nrFilter] as List?) ?? []).cast<Map>();
      List<Map> mrStories = ((mostRead[mrFilter] as List?) ?? []).cast<Map>();
      List<Map> shortList = shortStories.cast<Map>();

      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── New Releases ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _rankingSectionWidget(
              title: 'ranking_new_releases'.tr,
              cardBg: cardBg,
              onBg: onBg,
              txt: txt,
              filters: const ['daily', 'rising'],
              filterLabels: ['ranking_daily_releases'.tr, 'ranking_rising'.tr],
              activeFilter: nrFilter,
              onFilterTap: (f) {
                setState(() => _rankingNrFilter = f);
              },
              onMoreTap:
                  () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder:
                          (_) => RankingMoreScreen(
                            section: 'new-releases',
                            filters: const ['daily', 'rising'],
                            filterLabels: [
                              'ranking_daily_releases'.tr,
                              'ranking_rising'.tr,
                            ],
                            initialFilter: _rankingNrFilter,
                          ),
                    ),
                  ),
              child: _rankingList(nrStories, txt, sub),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          // ── Most Read ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _rankingSectionWidget(
              title: 'ranking_most_read'.tr,
              cardBg: cardBg,
              onBg: onBg,
              txt: txt,
              filters: const ['must-read', 'popularity'],
              filterLabels: ['ranking_must_read'.tr, 'ranking_popularity'.tr],
              activeFilter: mrFilter,
              onFilterTap: (f) {
                setState(() => _rankingMrFilter = f);
              },
              onMoreTap:
                  () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder:
                          (_) => RankingMoreScreen(
                            section: 'most-read',
                            filters: const ['must-read', 'popularity'],
                            filterLabels: [
                              'ranking_must_read'.tr,
                              'ranking_popularity'.tr,
                            ],
                            initialFilter: _rankingMrFilter,
                          ),
                    ),
                  ),
              child: _rankingList(mrStories, txt, sub),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          // ── Short Stories ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _sectionWidget(
              'section_short_stories'.tr,
              cardBg,
              onBg,
              txt,
              _shortStoriesVerticalList(shortList, txt, sub),
              showViewAll: false,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }
  }

  // ── Ranking section container (title + filter pills + More >) ───────────
  Widget _rankingSectionWidget({
    required String title,
    required Color cardBg,
    required Color onBg,
    required Color txt,
    required List<String> filters,
    required List<String> filterLabels,
    required String activeFilter,
    required ValueChanged<String> onFilterTap,
    required VoidCallback onMoreTap,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: txt,
                  fontFamily: kFontFamily,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onMoreTap,
                child: Row(
                  children: [
                    Text(
                      'More',
                      style: TextStyle(
                        fontSize: 13,
                        color: txt.withOpacity(0.5),
                        fontFamily: kFontFamily,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: txt.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter pills
          Row(
            children: List.generate(filters.length, (i) {
              final sel = filters[i] == activeFilter;
              return GestureDetector(
                onTap: () => onFilterTap(filters[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? depperBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: sel ? depperBlue : depperBlue.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    filterLabels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : depperBlue,
                      fontFamily: kFontFamily,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── Ranked story list (cover with badge + title + author pill) ───────────
  Widget _rankingList(List<Map> stories, Color txt, Color sub) {
    if (stories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No stories yet',
            style: TextStyle(color: sub, fontFamily: kFontFamily),
          ),
        ),
      );
    }
    return Column(
      children: List.generate(stories.length, (idx) {
        final story = stories[idx];
        final coverUrl = ctrl.getCoverUrl(story);
        final rankingPageSlug = story['slug'] as String? ?? '';
        final author = story['author_name'] ?? story['author'] ?? '';
        return GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder:
                      (_) => StoryDetailScreen(
                        slug: rankingPageSlug,
                        heroTag: 'hero-rankingpage-$rankingPageSlug',
                      ),
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cover with rank badge
                SizedBox(
                  width: 80,
                  height: 110,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Hero(
                          tag: 'hero-rankingpage-$rankingPageSlug',
                          child: CustomImageView(
                            imagePath: coverUrl,
                            width: 80,
                            height: 110,
                            fit: BoxFit.cover,
                            placeHolder:
                                'assets/images/novelux_placeholder_transcpr.jpg',
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: idx < 3 ? depperBlue : Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: kFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: txt,
                          fontFamily: kFontFamily,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (author.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            author,
                            style: TextStyle(
                              fontSize: 12,
                              color: txt.withOpacity(0.7),
                              fontFamily: kFontFamily,
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
      }),
    );
  }

  // ── Short Stories vertical list (cover + title + desc + views + tag) ─────
  Widget _shortStoriesVerticalList(List<Map> stories, Color txt, Color sub) {
    if (stories.isEmpty) return const SizedBox.shrink();
    return Column(
      children:
          stories.map((story) {
            final coverUrl = ctrl.getCoverUrl(story);
            final shortsVertSlug = story['slug'] as String? ?? '';
            final tags = (story['tags'] as List? ?? []);
            final firstTag =
                tags.isNotEmpty
                    ? (tags.first is Map
                        ? tags.first['name']
                        : tags.first.toString())
                    : '';
            return GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder:
                          (_) => StoryDetailScreen(
                            slug: shortsVertSlug,
                            heroTag: 'hero-shortsvert-$shortsVertSlug',
                          ),
                    ),
                  ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Hero(
                        tag: 'hero-shortsvert-$shortsVertSlug',
                        child: CustomImageView(
                          imagePath: coverUrl,
                          width: 90,
                          height: 126,
                          fit: BoxFit.cover,
                          placeHolder:
                              'assets/images/novelux_placeholder_transcpr.jpg',
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
                              fontSize: 14,
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
                            style: TextStyle(
                              fontSize: 12,
                              color: sub,
                              fontFamily: kFontFamily,
                            ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sub.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    firstTag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sub,
                                      fontFamily: kFontFamily,
                                    ),
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
          }).toList(),
    );
  }

  // ── Hero card: large cover left + info right ──────────────────────────────
  Widget _genreHeroCard(dynamic story, Color txt, Color sub) {
    final coverUrl = ctrl.getCoverUrl(story);
    final genreHeroSlug = story['slug'] as String? ?? '';
    final tags = (story['tags'] as List? ?? []);
    final views = story['total_views'] ?? 0;
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder:
                  (_) => StoryDetailScreen(
                    slug: genreHeroSlug,
                    heroTag: 'hero-genrehero-$genreHeroSlug',
                  ),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 120,
                child:
                    coverUrl.isNotEmpty
                        ? Hero(
                          tag: 'hero-genrehero-$genreHeroSlug',
                          child: CustomImageView(
                            imagePath: coverUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                        : _bookPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story['title'] ?? '',
                    style: TextStyle(
                      color: txt,
                      fontSize: 12,
                      fontFamily: kFontFamily,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story['description'] ?? '',
                    style: TextStyle(
                      color: sub,
                      fontSize: 10,
                      fontFamily: kFontFamily,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatViews(views)} Views',
                    style: TextStyle(
                      color: depperBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          tags
                              .take(2)
                              .map<Widget>(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.4),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    t['name'] ?? '',
                                    style: TextStyle(
                                      color: sub,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Completed Classics list (cover + title + EXCERPT: + desc + views + tag)
  Widget _genreClassicsList(List<dynamic> stories, Color txt, Color sub) =>
      Column(
        children:
            stories.map<Widget>((story) {
              final coverUrl = ctrl.getCoverUrl(story);
              final classicsSlug = story['slug'] as String? ?? '';
              final tags = (story['tags'] as List? ?? []);
              final views = story['total_views'] ?? 0;
              final desc = story['description'] as String? ?? '';
              return GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder:
                            (_) => StoryDetailScreen(
                              slug: classicsSlug,
                              heroTag: 'hero-classics-$classicsSlug',
                            ),
                      ),
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          height: 140,
                          child:
                              coverUrl.isNotEmpty
                                  ? Hero(
                                    tag: 'hero-classics-$classicsSlug',
                                    child: CustomImageView(
                                      imagePath: coverUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : _bookPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story['title'] ?? '',
                              style: TextStyle(
                                color: txt,
                                fontSize: 14,
                                fontFamily: kFontFamily,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (desc.isNotEmpty) ...[
                              Text(
                                'EXCERPT:',
                                style: TextStyle(
                                  color: sub.withOpacity(0.7),
                                  fontSize: 11,
                                  fontFamily: kFontFamily,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                desc,
                                style: TextStyle(
                                  color: sub,
                                  fontSize: 12,
                                  fontFamily: kFontFamily,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              '${_formatViews(views)} Views',
                              style: TextStyle(
                                color: depperBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (tags.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children:
                                    tags
                                        .take(2)
                                        .map<Widget>(
                                          (t) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: sub.withOpacity(0.10),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              t is Map
                                                  ? (t['name'] ?? '')
                                                  : t.toString(),
                                              style: TextStyle(
                                                color: sub,
                                                fontSize: 10,
                                                fontFamily: kFontFamily,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      );

  // ── Story row from plain List (for genre pages) ───────────────────────────
  Widget _storyRowFromList(List<dynamic> stories, Color txt) => SizedBox(
    height: 200,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: stories.length,
      itemBuilder: (_, i) {
        final story = stories[i];
        final genreListSlug = story['slug'] as String? ?? '';
        final coverUrl = ctrl.getCoverUrl(story);
        final tags = (story['tags'] as List? ?? []);
        return GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder:
                      (_) => StoryDetailScreen(
                        slug: genreListSlug,
                        heroTag: 'hero-genrelist-$genreListSlug',
                      ),
                ),
              ),
          child: SizedBox(
            width: 100,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 130,
                      width: 100,
                      child:
                          coverUrl.isNotEmpty
                              ? Hero(
                                tag: 'hero-genrelist-$genreListSlug',
                                child: CustomImageView(
                                  imagePath: coverUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : _bookPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story['title'] ?? '',
                    style: TextStyle(
                      color: txt,
                      fontSize: 10,
                      fontFamily: kFontFamily,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tags.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: depperBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tags[0]['name'] ?? '',
                        style: TextStyle(
                          color: depperBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  // ── Format large view counts ──────────────────────────────────────────────
  String _formatViews(dynamic views) {
    final n = views is int ? views : int.tryParse(views.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  void _showSearch(BuildContext context) {
    showSearch(context: context, delegate: _StorySearchDelegate(ctrl));
  }
}

// ── New Arrivals Carousel ──────────────────────────────────────────────────────
class _NewArrivalCarousel extends StatefulWidget {
  final RxList stories;
  final Color txt;
  final Color sub;
  final ExploreController ctrl;
  const _NewArrivalCarousel({
    required this.stories,
    required this.txt,
    required this.sub,
    required this.ctrl,
  });
  @override
  State<_NewArrivalCarousel> createState() => _NewArrivalCarouselState();
}

class _NewArrivalCarouselState extends State<_NewArrivalCarousel> {
  late final PageController _pageCtrl;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.75);
    _pageCtrl.addListener(() {
      final page = _pageCtrl.page?.round() ?? 0;
      if (page != _current && mounted) setState(() => _current = page);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_current] as Map;
    final tags = (story['tags'] as List? ?? []);
    final rating =
        double.tryParse(story['average_rating']?.toString() ?? '0') ?? 0.0;
    final views = story['total_views'] ?? 0;
    final chapters = story['total_chapters'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 230,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.stories.length,
              itemBuilder: (_, i) {
                final s = widget.stories[i] as Map;
                final arrivalsSlug = s['slug'] as String? ?? '';
                final url = widget.ctrl.getCoverUrl(s);
                final isCurrent = i == _current;
                return GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder:
                              (_) => StoryDetailScreen(
                                slug: arrivalsSlug,
                                heroTag: 'hero-arrivals-$arrivalsSlug',
                              ),
                        ),
                      ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: isCurrent ? 0 : 20,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              url.isNotEmpty
                                  ? Hero(
                                    tag: 'hero-arrivals-$arrivalsSlug',
                                    child: CustomImageView(
                                      imagePath: url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  )
                                  : CustomImageView(
                                    imagePath:
                                        'assets/images/novelux_placeholder_transcpr.jpg',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                        ),
                        if (!isCurrent)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        if (isCurrent)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.55],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.stories.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 8,
                  ),
                  width: i == _current ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        i == _current
                            ? depperBlue
                            : Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.txt,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: kFontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  story['synopsis'] ?? story['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.sub,
                    fontSize: 12,
                    fontFamily: kFontFamily,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: widget.sub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.remove_red_eye_outlined,
                      size: 13,
                      color: widget.sub,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$views',
                      style: TextStyle(color: widget.sub, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.menu_book_rounded, size: 13, color: widget.sub),
                    const SizedBox(width: 3),
                    Text(
                      '$chapters ch',
                      style: TextStyle(color: widget.sub, fontSize: 12),
                    ),
                  ],
                ),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          tags
                              .take(4)
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: depperBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: depperBlue.withValues(alpha: 0.25),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    t['name'] ?? '',
                                    style: TextStyle(
                                      color: depperBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search delegate ────────────────────────────────────────────────────────────
class _StorySearchDelegate extends SearchDelegate {
  final ExploreController ctrl;
  _StorySearchDelegate(this.ctrl);

  @override
  ThemeData appBarTheme(BuildContext context) => ThemeData.dark().copyWith(
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1a1a1a)),
  );

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    ctrl.search(query);
    return Obx(
      () => ListView.builder(
        itemCount: ctrl.forYou.length,
        itemBuilder: (_, i) {
          final story = ctrl.forYou[i];
          return ListTile(
            leading: const Icon(Icons.book, color: Colors.grey),
            title: Text(
              story['title'] ?? '',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              story['author']?['username'] ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              close(context, null);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => StoryDetailScreen(slug: story['slug']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
