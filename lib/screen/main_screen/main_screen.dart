import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/screen/explore/explore_screen.dart';
import 'package:novelux/screen/genres/genres_screen.dart';
import 'package:novelux/screen/library/library_screen.dart';
import 'package:novelux/screen/me/me_screen.dart';
import 'package:novelux/screen/reading_interface/controller/continue_reading_controller.dart';
import 'package:novelux/widgets/custom_buttom_nav.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/widgets/custom_image_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  late final ContinueReadingController _crCtrl;

  @override
  void initState() {
    super.initState();
    _crCtrl = Get.put(ContinueReadingController());
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppAlert.register(context);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          LibraryScreen(),
          ExploreScreen(),
          GenresScreen(),
          MeScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _ContinueReadingBanner(ctrl: _crCtrl),
          CustomBottomNav(currentIndex: _currentIndex, onTap: _onTabTapped),
        ],
      ),
    );
  }
}

class _ContinueReadingBanner extends StatelessWidget {
  final ContinueReadingController ctrl;
  const _ContinueReadingBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    // With extendBody:true the body fills the full screen.
    // padding.bottom = system bottom inset only (NOT app nav bar).
    // So: system_inset + 60 (our nav height) + 6 gap = just above the nav bar.
    final bottomOffset = MediaQuery.of(context).padding.bottom + 60 + 6;
    final theme = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1e1e24) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;

        return Obx(() {
          final visible = ctrl.isBannerVisible.value && ctrl.hasData.value;
          // Debug log to help trace banner visibility
          // ignore: avoid_print
          print(
            'ContinueBanner build: hasData=${ctrl.hasData.value} isBannerVisible=${ctrl.isBannerVisible.value} story=${ctrl.storyTitle.value} slug=${ctrl.storySlug.value}',
          );
          return AnimatedSlide(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            offset: visible ? Offset.zero : const Offset(0, 1.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: visible ? 1.0 : 0.0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    // bottom: bottomOffset,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Card — only as tall as content
                        Container(
                          // margin: const EdgeInsets.only(left: 60),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 60),
                              // Text info
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ctrl.storyTitle.value,
                                        style: TextStyle(
                                          color: txt,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Last read: Chapter ${ctrl.chapterNumber.value}'
                                        '${ctrl.chapterTitle.value.isNotEmpty ? ' · ${ctrl.chapterTitle.value}' : ''}',
                                        style: TextStyle(
                                          color: sub,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Continue button
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => StoryDetailScreen(
                                            slug: ctrl.storySlug.value,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: depperBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Dismiss button
                              GestureDetector(
                                onTap: () => ctrl.dismiss(),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: sub,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Cover image — taller than card, overflows upward
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 56,
                              height: 82,
                              child:
                                  ctrl.coverUrl.value.isNotEmpty
                                      ? CustomImageView(
                                        imagePath: ctrl.coverUrl.value,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(
                                        color: const Color(0xFF2a2a30),
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }
}
