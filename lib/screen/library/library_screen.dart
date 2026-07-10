// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:get/get.dart';
// import 'package:get/get_connect/http/src/utils/utils.dart';
// import 'package:novelux/config/app_style.dart';
// import 'package:novelux/config/size_config.dart';
// import 'package:novelux/screen/auth/auth_controller.dart';
// import 'package:novelux/screen/auth/auth_screens.dart';
// import 'package:novelux/screen/book_preview/story_detail_screen.dart';
// import 'package:novelux/screen/library/controller/library_controller.dart';
// import 'package:novelux/widgets/custom_image_view.dart';

// class LibraryScreen extends StatefulWidget {
//   const LibraryScreen({super.key});

//   @override
//   State<LibraryScreen> createState() => _LibraryScreenState();
// }

// class _LibraryScreenState extends State<LibraryScreen> {
//   int initialIndex = 0;
//   bool isProfile = false;

//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments;
//     if (args != null) {
//       initialIndex = args['value'] ?? 0;
//       isProfile = args['isProfile'] ?? false;
//     }

//     SizeConfig().init(context);
//     final ctrl = Get.put(LibraryController());
//     final auth = Get.find<AuthController>();

//     return SafeArea(
//       bottom: false,
//       child: Scaffold(
//         extendBody: true,
//         backgroundColor: background,
//         body: DefaultTabController(
//           initialIndex: initialIndex,
//           length: 2,
//           child: Column(
//             children: [
//               // ── Header ──────────────────────────────────────────────────────
//               Container(
//                 decoration: const BoxDecoration(color: background),
//                 child: Row(
//                   children: [
//                     if (isProfile)
//                       IconButton(
//                         onPressed: () => Get.back(),
//                         icon: const Icon(
//                           Icons.chevron_left_rounded,
//                           size: 30,
//                           color: kWhite,
//                         ),
//                       )
//                     else
//                       const SizedBox(width: 10),
//                     const Spacer(),
//                     TabBar(
//                       dividerColor: Colors.transparent,
//                       labelColor: Colors.white,
//                       unselectedLabelColor: Colors.grey,
//                       indicator: UnderlineTabIndicator(
//                         borderSide: BorderSide(color: depperBlue, width: 2),
//                       ),
//                       isScrollable: true,
//                       labelPadding: const EdgeInsets.symmetric(horizontal: 20),
//                       tabAlignment: TabAlignment.center,
//                       labelStyle: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       tabs: const [Tab(text: 'Library'), Tab(text: 'History')],
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       onPressed: ctrl.fetchBookmarks,
//                       icon: const Icon(
//                         Icons.refresh_rounded,
//                         size: 26,
//                         color: kWhite,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                   ],
//                 ),
//               ),

//               // ── Tab Views ───────────────────────────────────────────────────
//               Expanded(
//                 child: TabBarView(
//                   children: [
//                     // ── Library Tab ────────────────────────────────────────────
//                     Obx(() {
//                       if (!auth.isLoggedIn.value) {
//                         return _notLoggedIn();
//                       }
//                       return Column(
//                         children: [
//                           // Filter chips
//                           SizedBox(
//                             height: 36,
//                             child: ListView.builder(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 4,
//                               ),
//                               scrollDirection: Axis.horizontal,
//                               itemCount: ctrl.filters.length,
//                               itemBuilder: (_, i) {
//                                 final isActive =
//                                     ctrl.activeFilter.value == ctrl.filters[i];
//                                 return GestureDetector(
//                                   onTap:
//                                       () =>
//                                           ctrl.activeFilter.value =
//                                               ctrl.filters[i],
//                                   child: Container(
//                                     margin: const EdgeInsets.only(right: 8),
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: isActive ? depperBlue : kBrown,
//                                       borderRadius: BorderRadius.circular(24),
//                                     ),
//                                     child: Center(
//                                       child: Text(
//                                         ctrl.filters[i],
//                                         style: TextStyle(
//                                           color:
//                                               isActive ? Colors.white : kWhite,
//                                           fontSize: 12,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                           const SizedBox(height: 8),

// if (ctrl.isLoading.value)
//   Expanded(
//     child: Center(
//       child: Container(
//         height: 130,
//         width: 130,
//         decoration: BoxDecoration(
//           color: const Color.fromARGB(31, 100, 100, 100),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: SpinKitWanderingCubes(
//           size: 30,
//           //color: depperBlue,
//           itemBuilder: (context, index) {
//             return DecoratedBox(
//               decoration: BoxDecoration(
//                 color:
//                     index.isEven
//                         ? depperBlue
//                         : Colors.white,
//                 shape: BoxShape.rectangle,
//               ),
//             );
//           },
//           //size: 50,
//           duration: const Duration(
//             milliseconds: 1200,
//           ),
//         ),
//       ),
//       // CircularProgressIndicator(
//       //   color: Colors.blue,
//       // ),
//     ),
//   )
//                           else if (ctrl.filteredBookmarks.isEmpty)
//                             Expanded(
//                               child: Center(
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.bookmark_border,
//                                       color: Colors.grey[700],
//                                       size: 60,
//                                     ),
//                                     const SizedBox(height: 16),
//                                     const Text(
//                                       'No bookmarks yet',
//                                       style: TextStyle(
//                                         color: Colors.grey,
//                                         fontSize: 16,
//                                         fontFamily: kFontFamily,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     const Text(
//                                       'Browse stories and tap the bookmark icon',
//                                       style: TextStyle(
//                                         color: Colors.grey,
//                                         fontWeight: FontWeight.w500,
//                                         fontFamily: kFontFamily,
//                                         fontSize: 13,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             )
//                           else
//                             Expanded(
//                               child: GridView.builder(
//                                 padding: const EdgeInsets.all(10),
//                                 gridDelegate:
//                                     const SliverGridDelegateWithFixedCrossAxisCount(
//                                       crossAxisCount: 3,
//                                       mainAxisSpacing: 10,
//                                       crossAxisSpacing: 8,
//                                       childAspectRatio: 0.52,
//                                     ),
//                                 itemCount: ctrl.filteredBookmarks.length,
//                                 itemBuilder: (_, i) {
//                                   final story = ctrl.filteredBookmarks[i];
//                                   final coverUrl = ctrl.getCoverUrl(story);
//                                   return GestureDetector(
//                                     onLongPress:
//                                         () => _showRemoveDialog(
//                                           ctrl,
//                                           story['slug'],
//                                         ),
//                                     onTap:
//                                         () => Navigator.push(
//                                           context,
//                                           CupertinoPageRoute(
//                                             builder:
//                                                 (_) => StoryDetailScreen(
//                                                   slug: story['slug'],
//                                                 ),
//                                           ),
//                                         ),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Stack(
//                                           children: [
//                                             ClipRRect(
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                               child: SizedBox(
//                                                 height:
//                                                     SizeConfig
//                                                         .blockSizeVertical! *
//                                                     20,
//                                                 width: double.infinity,
//                                                 child:
//                                                     coverUrl.isNotEmpty
//                                                         ? CustomImageView(
//                                                           imagePath: coverUrl,
//                                                           fit: BoxFit.cover,
//                                                           //
//                                                         )
//                                                         : _coverPlaceholder(),
//                                               ),
//                                             ),
//                                             if (story['status'] == 'completed')
//                                               Positioned(
//                                                 top: 4,
//                                                 left: 4,
//                                                 child: Container(
//                                                   padding:
//                                                       const EdgeInsets.symmetric(
//                                                         horizontal: 5,
//                                                         vertical: 2,
//                                                       ),
//                                                   decoration: BoxDecoration(
//                                                     color: Colors.green
//                                                         .withOpacity(0.85),
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           4,
//                                                         ),
//                                                   ),
//                                                   child: const Text(
//                                                     'Done',
//                                                     style: TextStyle(
//                                                       color: Colors.white,
//                                                       fontSize: 9,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 6),
//                                         Text(
//                                           story['title'] ?? '',
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.white,
//                                             fontFamily: kFontFamily,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                         ],
//                       );
//                     }),

//                     // ── History Tab ───────────────────────────────────────────
//                     Obx(() {
//                       if (!auth.isLoggedIn.value) {
//                         return _notLoggedIn();
//                       }
//                       if (ctrl.isLoading.value) {
//                         return Center(
//                           child: Container(
//                             height: 130,
//                             width: 130,
//                             decoration: BoxDecoration(
//                               color: const Color.fromARGB(31, 100, 100, 100),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: SpinKitWanderingCubes(
//                               size: 30,
//                               //color: depperBlue,
//                               itemBuilder: (context, index) {
//                                 return DecoratedBox(
//                                   decoration: BoxDecoration(
//                                     color:
//                                         index.isEven
//                                             ? depperBlue
//                                             : Colors.white,
//                                     shape: BoxShape.rectangle,
//                                   ),
//                                 );
//                               },
//                               //size: 50,
//                               duration: const Duration(milliseconds: 1200),
//                             ),
//                           ),
//                           // CircularProgressIndicator(
//                           //   color: Colors.blue,
//                           // ),
//                         );
//                       }
//                       if (ctrl.bookmarks.isEmpty) {
//                         return Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.history,
//                                 color: Colors.grey[700],
//                                 size: 60,
//                               ),
//                               const SizedBox(height: 16),
//                               const Text(
//                                 'No reading history yet',
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }
//                       return ListView.builder(
//                         padding: const EdgeInsets.all(10),
//                         itemCount: ctrl.bookmarks.length,
//                         itemBuilder: (_, i) {
//                           final story = ctrl.bookmarks[i];
//                           final coverUrl = ctrl.getCoverUrl(story);
//                           return GestureDetector(
//                             onTap:
//                                 () => Navigator.push(
//                                   context,
//                                   CupertinoPageRoute(
//                                     builder:
//                                         (_) => StoryDetailScreen(
//                                           slug: story['slug'],
//                                         ),
//                                   ),
//                                 ),
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                               child: Row(
//                                 children: [
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(6),
//                                     child: SizedBox(
//                                       height:
//                                           SizeConfig.blockSizeVertical! * 11,
//                                       width:
//                                           SizeConfig.blockSizeHorizontal! * 13,
//                                       child:
//                                           coverUrl.isNotEmpty
//                                               ? CustomImageView(
//                                                 imagePath: coverUrl,
//                                                 fit: BoxFit.cover,
//                                               )
//                                               : _coverPlaceholder(),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           story['title'] ?? '',
//                                           style: const TextStyle(
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.white,
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           '${story['total_chapters'] ?? 0} chapters',
//                                           style: const TextStyle(
//                                             fontSize: 11,
//                                             color: Colors.white54,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           story['description'] ?? '',
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.white70,
//                                           ),
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     }),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _notLoggedIn() => Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(Icons.lock_outline, color: Colors.grey[700], size: 60),
//         const SizedBox(height: 16),
//         const Text(
//           'Sign in to view your library',
//           style: TextStyle(color: Colors.grey, fontSize: 16),
//         ),
//         const SizedBox(height: 20),
//         ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: depperBlue,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed: () => Get.to(() => const LoginScreen()),
//           child: const Text('Sign In', style: TextStyle(color: Colors.white)),
//         ),
//       ],
//     ),
//   );

//   Widget _coverPlaceholder() => Container(
//     color: Colors.grey[800],
//     child: const Center(child: Icon(Icons.book, color: Colors.grey)),
//   );

//   void _showRemoveDialog(LibraryController ctrl, String slug) {
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: const Color(0xFF2a2a2a),
//         title: const Text(
//           'Remove Bookmark',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: const Text(
//           'Remove this story from your library?',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () {
//               Get.back();
//               ctrl.removeBookmark(slug);
//             },
//             child: const Text('Remove', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/size_config.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/auth/auth_screens.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/screen/library/controller/library_controller.dart';
import 'package:novelux/screen/reward_screen/reward_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  int initialIndex = 0;
  bool isProfile = false;
  final ctrl = Get.put(LibraryController());
  @override
  void initState() {
    super.initState();
    // Only fetch if not already loaded; controller's onInit handles first load
    if (ctrl.bookmarks.isEmpty && !ctrl.isLoading.value) ctrl.fetchBookmarks();
    if (ctrl.historyGroups.isEmpty && !ctrl.isLoadingHistory.value)
      ctrl.fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args != null) {
      initialIndex = args['value'] ?? 0;
      isProfile = args['isProfile'] ?? false;
    }

    SizeConfig().init(context);

    final auth = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? background : const Color(0xFFF2F2F7);
    final cardBg = isDark ? const Color(0xFF1e1e22) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;
    return SafeArea(
      bottom: false,
      child: Scaffold(
        extendBody: true,
        backgroundColor: bg,
        body: DefaultTabController(
          initialIndex: initialIndex,
          length: 2,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                color: isDark ? background : Colors.white,
                //padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    if (isProfile)
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          size: 30,
                          color: txt,
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    const Spacer(),

                    TabBar(
                      dividerColor: Colors.transparent,
                      labelColor: txt,
                      unselectedLabelColor: sub,
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(color: depperBlue, width: 2.5),
                      ),
                      isScrollable: true,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                      tabAlignment: TabAlignment.center,
                      labelStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 18),
                      tabs: const [Tab(text: 'Library'), Tab(text: 'History')],
                    ),

                    const Spacer(),

                    // Rewards pill
                    GestureDetector(
                      onTap: () => Get.to(() => const RewardsScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3d2800),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('⭐', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 4),
                            Text(
                              'Rewards',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Filter/sort icon
                    IconButton(
                      icon: Icon(Icons.tune_rounded, size: 22, color: sub),
                      onPressed: () => ctrl.fetchBookmarks(),
                    ),
                    const SizedBox(width: 2),
                  ],
                ),
              ),

              // ── Tab Views ─────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: [
                    // ── Library tab ───────────────────────────────────────────
                    Obx(() {
                      if (!auth.isLoggedIn.value) return _notLoggedIn(txt);
                      return Column(
                        children: [
                          // ── Featured banner ─────────────────────────────────
                          _LibraryBanner(ctrl: ctrl, isDark: isDark),

                          // Filter chips
                          Container(
                            height: 38,
                            color: isDark ? background : Colors.white,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                              scrollDirection: Axis.horizontal,
                              itemCount: ctrl.filters.length,
                              itemBuilder: (_, i) {
                                final active =
                                    ctrl.activeFilter.value == ctrl.filters[i];
                                return GestureDetector(
                                  onTap:
                                      () =>
                                          ctrl.activeFilter.value =
                                              ctrl.filters[i],
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          active
                                              ? depperBlue
                                              : (isDark
                                                  ? kBrown
                                                  : Colors.grey[100]!),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Center(
                                      child: Text(
                                        ctrl.filters[i],
                                        style: TextStyle(
                                          color:
                                              active
                                                  ? Colors.white
                                                  : (isDark
                                                      ? Colors.white70
                                                      : Colors.grey[700]!),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 4),

                          if (ctrl.isLoading.value)
                            Expanded(
                              child: Center(
                                child: Container(
                                  height: 130,
                                  width: 130,
                                  decoration: BoxDecoration(
                                    color: divClr,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SpinKitWanderingCubes(
                                    size: 30,
                                    //color: depperBlue,
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
                                    //size: 50,
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
                                  ),
                                ),
                                // CircularProgressIndicator(
                                //   color: Colors.blue,
                                // ),
                              ),
                            )
                          else if (ctrl.filteredBookmarks.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 250),
                                child: _emptyState(
                                  Icons.bookmark_border,
                                  'No bookmarks yet',
                                  'Browse stories and tap the bookmark icon',
                                  txt,
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(10),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.52,
                                    ),
                                itemCount: ctrl.filteredBookmarks.length,
                                itemBuilder: (_, i) {
                                  final story = ctrl.filteredBookmarks[i];
                                  final coverUrl = ctrl.getCoverUrl(story);
                                  return GestureDetector(
                                    onLongPress:
                                        () => _showRemoveDialog(
                                          ctrl,
                                          story['slug'],
                                        ),
                                    onTap:
                                        () => Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder:
                                                (_) => StoryDetailScreen(
                                                  slug: story['slug'],
                                                  heroTag:
                                                      'hero-library-${story['slug']}',
                                                ),
                                          ),
                                        ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: SizedBox(
                                                height:
                                                    SizeConfig
                                                        .blockSizeVertical! *
                                                    20,
                                                width: double.infinity,
                                                child:
                                                    coverUrl.isNotEmpty
                                                        ? Hero(
                                                          tag:
                                                              'hero-library-${story['slug']}',
                                                          child:
                                                              CustomImageView(
                                                                imagePath:
                                                                    coverUrl,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              ),
                                                        )
                                                        : _coverPlaceholder(),
                                              ),
                                            ),
                                            if (story['status'] == 'completed')
                                              Positioned(
                                                top: 4,
                                                left: 4,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withValues(
                                                          alpha: 0.85,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Done',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
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
                                            fontSize: 12,
                                            color: txt,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    }),

                    // ── History tab ───────────────────────────────────────────
                    Obx(() {
                      if (!auth.isLoggedIn.value) return _notLoggedIn(txt);
                      if (ctrl.isLoadingHistory.value) {
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
                              //color: depperBlue,
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
                              //size: 50,
                              duration: const Duration(milliseconds: 1200),
                            ),
                          ),
                          // CircularProgressIndicator(
                          //   color: Colors.blue,
                        );
                      }
                      if (ctrl.historyGroups.isEmpty) {
                        return _emptyState(
                          Icons.history_rounded,
                          'No reading history yet',
                          'Stories you open will appear here',
                          txt,
                        );
                      }

                      return Column(
                        children: [
                          // Clear all button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reading history',
                                  style: TextStyle(color: sub, fontSize: 12),
                                ),
                                GestureDetector(
                                  onTap: () => _showClearDialog(ctrl),
                                  child: Text(
                                    'Clear all',
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
                          const SizedBox(height: 6),

                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                              itemCount: ctrl.historyGroups.length,
                              itemBuilder: (_, gi) {
                                final group = ctrl.historyGroups[gi];
                                final label = group['label'] as String;
                                final entries =
                                    group['entries'] as List<HistoryEntry>;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date header
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        10,
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: txt,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    // Story rows
                                    ...entries.map(
                                      (e) => _HistoryRow(
                                        entry: e,
                                        ctrl: ctrl,
                                        isDark: isDark,
                                        cardBg: cardBg,
                                        txt: txt,
                                        sub: sub,
                                        onTap:
                                            () => Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                builder:
                                                    (_) => StoryDetailScreen(
                                                      slug: e.slug,
                                                    ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notLoggedIn(Color txt) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, color: Colors.grey[700], size: 60),
        const SizedBox(height: 16),
        Text(
          'Sign in to view your library',
          style: TextStyle(color: txt.withOpacity(0.5), fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: depperBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Get.to(() => const LoginScreen()),
          child: const Text('Sign In', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _emptyState(IconData icon, String title, String sub, Color txt) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[700], size: 60),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: txt,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );

  Widget _coverPlaceholder() =>
  // Container(
  //   color: Colors.grey[800],
  //   child: const Center(child: Icon(Icons.book, color: Colors.grey)),
  // );
  CustomImageView(
    imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
    width: 60,
    height: 80,
    fit: BoxFit.cover,
  );

  void _showRemoveDialog(LibraryController ctrl, String slug) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Remove Bookmark',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Remove this story from your library?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              ctrl.removeBookmark(slug);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(LibraryController ctrl) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Clear history',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Remove all reading history?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              ctrl.clearHistory();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── History row widget ────────────────────────────────────────────────────────
class _HistoryRow extends StatelessWidget {
  final HistoryEntry entry;
  final LibraryController ctrl;
  final bool isDark;
  final Color cardBg, txt, sub;
  final VoidCallback onTap;

  const _HistoryRow({
    required this.entry,
    required this.ctrl,
    required this.isDark,
    required this.cardBg,
    required this.txt,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = ctrl.getCoverUrlEntry(entry.coverUrl);

    return Dismissible(
      key: ValueKey(entry.slug + entry.readAt.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        Timer? deleteTimer;
        deleteTimer = Timer(const Duration(seconds: 4), () {
          ctrl.removeHistoryEntry(entry.slug);
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF2a2a2a),
            content: Text(
              '"${entry.title}" removed from history',
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: depperBlue,
              onPressed: () {
                deleteTimer?.cancel();
                ctrl.fetchHistory();
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1e1e22) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDark
                      ? const Color(0xFF2a2a30)
                      : Colors.grey.withOpacity(0.12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 76,
                      height: 104,
                      child:
                          coverUrl.isNotEmpty
                              ? CustomImageView(
                                imagePath: coverUrl,
                                fit: BoxFit.cover,
                              )
                              :
                              // Container(
                              //   color: Colors.grey[800],
                              //   child: const Center(
                              //     child: Icon(Icons.book, color: Colors.grey),
                              //   ),
                              // ),
                              CustomImageView(
                                imagePath:
                                    'assets/images/novelux_placeholder_transcpr.jpg',
                                width: 60,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                  // Short badge (like the "Short" label in the screenshot)
                  if (entry.isShort)
                    Positioned(
                      top: 4,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFAA00),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Short',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entry.totalChapters} chapters',
                      style: TextStyle(color: sub, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    // "Read up to: Chapter N Title" — matches the screenshot
                    if (entry.lastChapterNumber > 0)
                      Text(
                        'Read up to: Chapter ${entry.lastChapterNumber}'
                        '${entry.lastChapterTitle.isNotEmpty ? '  ${entry.lastChapterTitle}' : ''}',
                        style: TextStyle(color: sub, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Bookmark toggle button
              Obx(() {
                final saved = ctrl.isStorySaved(entry.slug);
                return GestureDetector(
                  onTap: () async {
                    if (saved) {
                      await ctrl.removeBookmark(entry.slug);
                    } else {
                      await ctrl.addBookmark(entry.slug);
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          saved
                              ? depperBlue.withValues(alpha: 0.15)
                              : isDark
                              ? const Color(0xFF2a2a30)
                              : Colors.grey[100]!,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_add_outlined,
                      color:
                          saved
                              ? depperBlue
                              : isDark
                              ? Colors.white70
                              : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Library banner carousel
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryBanner extends StatefulWidget {
  final LibraryController ctrl;
  final bool isDark;
  const _LibraryBanner({required this.ctrl, required this.isDark});

  @override
  State<_LibraryBanner> createState() => _LibraryBannerState();
}

class _LibraryBannerState extends State<_LibraryBanner> {
  late final PageController _pageCtrl;
  Timer? _autoTimer;

  // Virtual count so PageView never physically ends — enables infinite looping.
  static const int _kVirtualCount = 99999;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      if (widget.ctrl.bannerStories.length <= 1) return;
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  String _coverUrl(dynamic story) {
    final c = (story as Map)['cover_image']?.toString() ?? '';
    if (c.isEmpty) return '';
    if (c.startsWith('http')) return c;
    return 'http://10.0.2.2:8000$c';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stories = widget.ctrl.bannerStories;
      final isDark = widget.isDark;

      if (widget.ctrl.isLoadingBanner.value) {
        return Container(
          height: 80,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1e1e22) : Colors.grey[200],
            borderRadius: BorderRadius.circular(14),
          ),
        );
      }

      if (stories.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: stories.length > 1 ? _kVirtualCount : stories.length,
              onPageChanged: (page) {
                widget.ctrl.bannerIndex.value = page % stories.length;
              },
              itemBuilder: (_, i) {
                final story = stories[i % stories.length] as Map;
                final coverUrl = _coverUrl(story);
                final title = story['title']?.toString() ?? '';
                final synopsis =
                    story['synopsis']?.toString() ??
                    story['description']?.toString() ??
                    '';

                return GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder:
                              (_) => StoryDetailScreen(
                                slug: story['slug']?.toString() ?? '',
                                heroTag: 'hero-banner-${story['slug']}',
                              ),
                        ),
                      ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF1e1e22)
                              : const Color(0xFFFCEEEE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        // Cover
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                          child: SizedBox(
                            width: 66,
                            height: 80,
                            child:
                                coverUrl.isNotEmpty
                                    ? Hero(
                                      tag: 'hero-banner-${story['slug']}',
                                      child: Image.network(
                                        coverUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                _bannerPlaceholder(),
                                      ),
                                    )
                                    : _bannerPlaceholder(),
                          ),
                        ),
                        // Text
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF1a1a1a),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  synopsis,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color:
                                        isDark
                                            ? Colors.white60
                                            : Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
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
          // Dot indicators
          if (stories.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(stories.length, (i) {
                  final active = widget.ctrl.bannerIndex.value == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          active
                              ? depperBlue
                              : (isDark ? Colors.white30 : Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      );
    });
  }

  Widget _bannerPlaceholder() => Container(
    color: depperBlue.withValues(alpha: 0.15),
    child: const Icon(Icons.book_rounded, color: Colors.white54, size: 32),
  );
}
