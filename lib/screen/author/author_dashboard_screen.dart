// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:get/get.dart';
// import 'package:novelux/config/ThemeController.dart';
// import 'package:novelux/config/api_service.dart';
// import 'package:novelux/config/app_style.dart';
// import 'package:novelux/screen/auth/auth_controller.dart';
// import 'package:novelux/screen/author/author_chapters_screen.dart';
// import 'package:novelux/widgets/custom_image_view.dart';

// class AuthorDashboardController extends GetxController {
//   final RxBool isLoading = false.obs;
//   final RxList myStories = [].obs;
//   final RxList genres = [].obs;

//   // Create story form
//   final titleCtrl = TextEditingController();
//   final descCtrl = TextEditingController();
//   final plotCtrl = TextEditingController();
//   final selectedGenreId = Rx<int?>(null);
//   final selectedStatus = 'draft'.obs;
//   final selectedLang = 'en'.obs;
//   final selectedGender = 'male'.obs;
//   final isExclusive = false.obs;
//   final isCreating = false.obs;
//   final createError = ''.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchMyStories();
//     fetchGenres();
//   }

//   Future<void> fetchMyStories() async {
//     isLoading.value = true;
//     final res = await ApiService.getMyStories();
//     isLoading.value = false;
//     if (res['success']) {
//       final d = res['data'];
//       myStories.value = d is List ? d : (d['results'] ?? []);
//     }
//   }

//   Future<void> fetchGenres() async {
//     final res = await ApiService.getGenres();
//     if (res['success']) {
//       genres.value = res['data'] is List ? res['data'] : [];
//     }
//   }

//   Future<void> createStory() async {
//     if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
//       createError.value = 'Title and description are required';
//       return;
//     }
//     isCreating.value = true;
//     createError.value = '';
//     final body = <String, dynamic>{
//       'title': titleCtrl.text.trim(),
//       'description': descCtrl.text.trim(),
//       'plot_summary': plotCtrl.text.trim(),
//       'status': selectedStatus.value,
//       'language': selectedLang.value,
//       'gender': selectedGender.value,
//       'is_exclusive': isExclusive.value,
//       if (selectedGenreId.value != null) 'genre_id': selectedGenreId.value,
//     };
//     final res = await ApiService.createStory(body);
//     isCreating.value = false;
//     if (res['success']) {
//       Get.back();
//       fetchMyStories();
//       titleCtrl.clear();
//       descCtrl.clear();
//       plotCtrl.clear();
//       Get.snackbar(
//         '🎉 Story Created!',
//         '"${res['data']['title']}" is live!',
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//     } else {
//       createError.value = res['error'] ?? 'Failed to create story';
//     }
//   }

//   String getCoverUrl(Map story) {
//     final c = story['cover_image'];
//     if (c == null || c.toString().isEmpty) {
//       return '';
//     }
//     if (c.toString().startsWith('http')) {
//       return c.toString();
//     }
//     return 'http://10.0.2.2:8000$c';
//   }
// }

// class AuthorDashboardScreen extends StatelessWidget {
//   const AuthorDashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl = Get.put(AuthorDashboardController());
//     final auth = Get.find<AuthController>();
//      final theme = Get.find<ThemeController>();

//     return AnimatedBuilder(
//       animation: theme,
//       builder: (_, __) {
//         final isDark = Theme.of(context).brightness == Brightness.dark;
//         final bg = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
//         final onBg =
//             !isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
//         final cardBg =
//             isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
//         final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
//         final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
//         final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;

//     return Scaffold(
//       backgroundColor: const Color(0xFF1a1a1a),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1a1a1a),
//         leading: IconButton(
//           icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
//           onPressed: () => Get.back(),
//         ),
//         title: const Text(
//           'Author Dashboard',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add_circle_outline, color: depperBlue),
//             onPressed: () => _showCreateStorySheet(context, ctrl),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         final user = auth.currentUser.value;
//         final profile = user?['author_profile'];
//         return RefreshIndicator(
//           onRefresh: ctrl.fetchMyStories,
//           color: depperBlue,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Earnings Card ─────────────────────────────────────────────
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         depperBlue.withOpacity(0.8),
//                         const Color(0xFF003d80),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           _earningsStat(
//                             'Total Earned',
//                             '\$${profile?['total_earnings'] ?? '0.00'}',
//                             Icons.account_balance_wallet,
//                           ),
//                           _earningsStat(
//                             'Pending Payout',
//                             '\$${profile?['pending_payout'] ?? '0.00'}',
//                             Icons.pending,
//                           ),
//                           _earningsStat(
//                             'My Coins',
//                             '${auth.coins}',
//                             Icons.monetization_on,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       if (profile != null &&
//                           double.parse(profile['pending_payout'].toString()) >
//                               0)
//                         SizedBox(
//                           width: double.infinity,
//                           child: OutlinedButton(
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: Colors.white,
//                               side: const BorderSide(color: Colors.white),
//                             ),
//                             onPressed: () => _requestPayout(context),
//                             child: const Text('Request Payout'),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // ── My Stories ────────────────────────────────────────────────
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'My Stories',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Obx(
//                       () => Text(
//                         '${ctrl.myStories.length} stories',
//                         style: const TextStyle(
//                           color: Colors.grey,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 if (ctrl.isLoading.value)
//                    Center(
//                     child: Container(
//                       height: 130,
//                       width: 130,
//                       decoration: BoxDecoration(
//                         color: bg,
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: SpinKitWanderingCubes(
//                         size: 30,
//                         //color: depperBlue,
//                         itemBuilder: (context, index) {
//                           return DecoratedBox(
//                             decoration: BoxDecoration(
//                               color: index.isEven ? depperBlue : Colors.white,
//                               shape: BoxShape.rectangle,
//                             ),
//                           );
//                         },
//                         //size: 50,
//                         duration: const Duration(milliseconds: 1200),
//                       ),
//                     ),
//                     // CircularProgressIndicator(
//                     //   color: Colors.blue,
//                     // ),
//                   )
//                 else if (ctrl.myStories.isEmpty)
//                   _emptyStories(context, ctrl)
//                 else
//                   ...ctrl.myStories.map(
//                     (story) => _StoryCard(
//                       story: story,
//                       coverUrl: ctrl.getCoverUrl(story),
//                       onAddChapter:
//                           () => _showAddChapterSheet(context, story['slug']),
//                       onViewChapters: () => Get.to(
//                         () => AuthorChaptersScreen(
//                           storySlug: story['slug'] ?? '',
//                           storyTitle: story['title'] ?? 'Untitled',
//                         ),
//                       ),
//                     ),
//                   ),
//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),
//         );
//       }),
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: depperBlue,
//         onPressed: () => _showCreateStorySheet(context, ctrl),
//         icon: const Icon(Icons.add, color: Colors.white),
//         label: const Text('New Story', style: TextStyle(color: Colors.white)),
//       ),
//     );
//       });
//   }

//   Widget _earningsStat(String label, String value, IconData icon) => Column(
//     children: [
//       Icon(icon, color: Colors.white70, size: 20),
//       const SizedBox(height: 4),
//       Text(
//         value,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//       ),
//       Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
//     ],
//   );

//   Widget _emptyStories(BuildContext context, AuthorDashboardController ctrl) =>
//       Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 40),
//           child: Column(
//             children: [
//               Icon(Icons.edit_note, color: Colors.grey[700], size: 60),
//               const SizedBox(height: 16),
//               const Text(
//                 'No stories yet',
//                 style: TextStyle(color: Colors.grey, fontSize: 16),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Create your first story and start earning!',
//                 style: TextStyle(color: Colors.grey, fontSize: 13),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: depperBlue),
//                 onPressed: () => _showCreateStorySheet(context, ctrl),
//                 child: const Text(
//                   'Create Story',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );

//   void _showCreateStorySheet(BuildContext ctx, AuthorDashboardController ctrl) {
//     showModalBottomSheet(
//       context: ctx,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF1a1a1a),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (_) => DraggableScrollableSheet(
//             expand: false,
//             initialChildSize: 0.92,
//             maxChildSize: 0.97,
//             builder:
//                 (_, sc) => Padding(
//                   padding: EdgeInsets.only(
//                     bottom: MediaQuery.of(ctx).viewInsets.bottom,
//                   ),
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 8),
//                       Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[700],
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       const Text(
//                         'New Story',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                       const Divider(color: Color(0xFF2a2a2a)),
//                       Expanded(
//                         child: ListView(
//                           controller: sc,
//                           padding: const EdgeInsets.all(20),
//                           children: [
//                             _field(
//                               'Title',
//                               ctrl.titleCtrl,
//                               'Enter story title',
//                             ),
//                             const SizedBox(height: 16),
//                             _field(
//                               'Description',
//                               ctrl.descCtrl,
//                               'Write a compelling description...',
//                               maxLines: 4,
//                             ),
//                             const SizedBox(height: 16),
//                             _field(
//                               'Plot Summary',
//                               ctrl.plotCtrl,
//                               'Brief plot overview...',
//                               maxLines: 3,
//                             ),
//                             const SizedBox(height: 16),

//                             // Genre picker
//                             const Text(
//                               'Genre',
//                               style: TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 13,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Obx(
//                               () => DropdownButtonFormField<int>(
//                                 value: ctrl.selectedGenreId.value,
//                                 dropdownColor: const Color(0xFF2a2a2a),
//                                 style: const TextStyle(color: Colors.white),
//                                 decoration: _inputDec(),
//                                 hint: const Text(
//                                   'Select genre',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                                 items:
//                                     ctrl.genres
//                                         .map<DropdownMenuItem<int>>(
//                                           (g) => DropdownMenuItem(
//                                             value: g['id'],
//                                             child: Text(g['name'] ?? ''),
//                                           ),
//                                         )
//                                         .toList(),
//                                 onChanged:
//                                     (v) => ctrl.selectedGenreId.value = v,
//                               ),
//                             ),
//                             const SizedBox(height: 16),

//                             // Language
//                             const Text(
//                               'Language',
//                               style: TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 13,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Obx(
//                               () => DropdownButtonFormField<String>(
//                                 value: ctrl.selectedLang.value,
//                                 dropdownColor: const Color(0xFF2a2a2a),
//                                 style: const TextStyle(color: Colors.white),
//                                 decoration: _inputDec(),
//                                 items: const [
//                                   DropdownMenuItem(
//                                     value: 'en',
//                                     child: Text('English'),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'fr',
//                                     child: Text('French'),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'yo',
//                                     child: Text('Yoruba'),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'ig',
//                                     child: Text('Igbo'),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'ha',
//                                     child: Text('Hausa'),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'sw',
//                                     child: Text('Swahili'),
//                                   ),
//                                 ],
//                                 onChanged: (v) => ctrl.selectedLang.value = v!,
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             Obx(
//                               () => DropdownButtonFormField<String>(
//                                 value: ctrl.selectedGender.value,
//                                 dropdownColor: const Color(0xFF2a2a2a),
//                                 style: const TextStyle(color: Colors.white),
//                                 decoration: _inputDec(),
//                                 items: const [
//                                   DropdownMenuItem(
//                                     value: 'male',
//                                     child: Text('Male'),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'female',
//                                     child: Text('Female'),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'prefer_not_to_say',
//                                     child: Text('Prefer not to say'),
//                                   ),
//                                   // DropdownMenuItem(
//                                   //   value: 'ig',
//                                   //   child: Text('Igbo'),
//                                   // ),
//                                   // DropdownMenuItem(
//                                   //   value: 'ha',
//                                   //   child: Text('Hausa'),
//                                   // ),
//                                   // DropdownMenuItem(
//                                   //   value: 'sw',
//                                   //   child: Text('Swahili'),
//                                   // ),
//                                 ],
//                                 onChanged:
//                                     (v) => ctrl.selectedGender.value = v!,
//                               ),
//                             ),
//                             const SizedBox(height: 16),

//                             // Exclusive toggle
//                             Obx(
//                               () => SwitchListTile(
//                                 tileColor: const Color(0xFF2a2a2a),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 title: const Text(
//                                   'Exclusive Story',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                                 subtitle: const Text(
//                                   'Higher bonuses, platform exclusive',
//                                   style: TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: 11,
//                                   ),
//                                 ),
//                                 value: ctrl.isExclusive.value,
//                                 onChanged: (v) => ctrl.isExclusive.value = v,
//                                 activeColor: depperBlue,
//                               ),
//                             ),
//                             const SizedBox(height: 24),

//                             // Error
//                             Obx(
//                               () =>
//                                   ctrl.createError.value.isNotEmpty
//                                       ? Padding(
//                                         padding: const EdgeInsets.only(
//                                           bottom: 12,
//                                         ),
//                                         child: Text(
//                                           ctrl.createError.value,
//                                           style: const TextStyle(
//                                             color: Colors.redAccent,
//                                             fontSize: 13,
//                                           ),
//                                         ),
//                                       )
//                                       : const SizedBox.shrink(),
//                             ),

//                             // Submit
//                             Obx(
//                               () => SizedBox(
//                                 width: double.infinity,
//                                 height: 52,
//                                 child: ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: depperBlue,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                   onPressed:
//                                       ctrl.isCreating.value
//                                           ? null
//                                           : ctrl.createStory,
//                                   child:
//                                       ctrl.isCreating.value
//                                           ? const SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               color: Colors.white,
//                                             ),
//                                           )
//                                           : const Text(
//                                             'Publish Story',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//           ),
//     );
//   }

//   void _showAddChapterSheet(BuildContext ctx, String storySlug) {
//     final titleCtrl = TextEditingController();
//     final contentCtrl = TextEditingController();
//     final chNumCtrl = TextEditingController();
//     final coinCtrl = TextEditingController(text: '20');
//     final isLocked = true.obs;
//     final isLoading = false.obs;
//     final error = ''.obs;

//     showModalBottomSheet(
//       context: ctx,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF1a1a1a),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (_) => DraggableScrollableSheet(
//             expand: false,
//             initialChildSize: 0.92,
//             maxChildSize: 0.97,
//             builder:
//                 (_, sc) => Padding(
//                   padding: EdgeInsets.only(
//                     bottom: MediaQuery.of(ctx).viewInsets.bottom,
//                   ),
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 8),
//                       Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[700],
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       const Text(
//                         'Add Chapter',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                       const Divider(color: Color(0xFF2a2a2a)),
//                       Expanded(
//                         child: ListView(
//                           controller: sc,
//                           padding: const EdgeInsets.all(20),
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   flex: 2,
//                                   child: _field(
//                                     'Chapter #',
//                                     chNumCtrl,
//                                     'e.g. 1',
//                                     keyboardType: TextInputType.number,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   flex: 5,
//                                   child: _field(
//                                     'Chapter Title',
//                                     titleCtrl,
//                                     'Enter title',
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             _field(
//                               'Content',
//                               contentCtrl,
//                               'Write your chapter here...',
//                               maxLines: 12,
//                             ),
//                             const SizedBox(height: 16),
//                             Obx(
//                               () => SwitchListTile(
//                                 tileColor: const Color(0xFF2a2a2a),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 title: const Text(
//                                   'Lock this chapter',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                                 subtitle: const Text(
//                                   'Readers pay coins to unlock',
//                                   style: TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: 11,
//                                   ),
//                                 ),
//                                 value: isLocked.value,
//                                 onChanged: (v) => isLocked.value = v,
//                                 activeColor: depperBlue,
//                               ),
//                             ),
//                             Obx(
//                               () =>
//                                   isLocked.value
//                                       ? Padding(
//                                         padding: const EdgeInsets.only(top: 16),
//                                         child: _field(
//                                           'Coin Cost',
//                                           coinCtrl,
//                                           '20',
//                                           keyboardType: TextInputType.number,
//                                         ),
//                                       )
//                                       : const SizedBox.shrink(),
//                             ),
//                             const SizedBox(height: 24),
//                             Obx(
//                               () =>
//                                   error.value.isNotEmpty
//                                       ? Padding(
//                                         padding: const EdgeInsets.only(
//                                           bottom: 12,
//                                         ),
//                                         child: Text(
//                                           error.value,
//                                           style: const TextStyle(
//                                             color: Colors.redAccent,
//                                             fontSize: 13,
//                                           ),
//                                         ),
//                                       )
//                                       : const SizedBox.shrink(),
//                             ),
//                             Obx(
//                               () => SizedBox(
//                                 width: double.infinity,
//                                 height: 52,
//                                 child: ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: depperBlue,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                   onPressed:
//                                       isLoading.value
//                                           ? null
//                                           : () async {
//                                             if (titleCtrl.text.isEmpty ||
//                                                 contentCtrl.text.isEmpty ||
//                                                 chNumCtrl.text.isEmpty) {
//                                               error.value =
//                                                   'All fields are required';
//                                               return;
//                                             }
//                                             isLoading.value = true;
//                                             error.value = '';
//                                             final res =
//                                                 await ApiService.createChapter(
//                                                   storySlug,
//                                                   {
//                                                     'title':
//                                                         titleCtrl.text.trim(),
//                                                     'content':
//                                                         contentCtrl.text.trim(),
//                                                     'chapter_number':
//                                                         int.tryParse(
//                                                           chNumCtrl.text,
//                                                         ) ??
//                                                         1,
//                                                     'is_locked': isLocked.value,
//                                                     'coin_cost':
//                                                         int.tryParse(
//                                                           coinCtrl.text,
//                                                         ) ??
//                                                         20,
//                                                     'is_published': true,
//                                                   },
//                                                 );
//                                             isLoading.value = false;
//                                             if (res['success']) {
//                                               Get.back();
//                                               Get.snackbar(
//                                                 'Chapter Published!',
//                                                 '"${titleCtrl.text}" is now live.',
//                                                 backgroundColor: Colors.green,
//                                                 colorText: Colors.white,
//                                               );
//                                             } else {
//                                               error.value =
//                                                   res['error'] ??
//                                                   'Failed to publish';
//                                             }
//                                           },
//                                   child:
//                                       isLoading.value
//                                           ? const SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               color: Colors.white,
//                                             ),
//                                           )
//                                           : const Text(
//                                             'Publish Chapter',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//           ),
//     );
//   }

//   void _requestPayout(BuildContext context) {
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: const Color(0xFF2a2a2a),
//         title: const Text(
//           'Request Payout',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: const Text(
//           'Request your pending earnings to be paid out?',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: depperBlue),
//             onPressed: () async {
//               Get.back();
//               final res = await ApiService.requestPayout();
//               if (res['success']) {
//                 Get.snackbar(
//                   'Payout Requested!',
//                   'We will process your payout within 3-5 days.',
//                   backgroundColor: Colors.green,
//                   colorText: Colors.white,
//                 );
//               }
//             },
//             child: const Text('Request', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StoryCard extends StatelessWidget {
//   final Map story;
//   final String coverUrl;
//   final VoidCallback onAddChapter;
//   final VoidCallback onViewChapters;
//   const _StoryCard({
//     required this.story,
//     required this.coverUrl,
//     required this.onAddChapter,
//     required this.onViewChapters,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onViewChapters,
//       child: _buildCard(context),
//     );
//   }

//   Widget _buildCard(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF2a2a2a),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child:
//                 coverUrl.isNotEmpty
//                     ? CustomImageView(
//                       imagePath: coverUrl,
//                       width: 60,
//                       height: 80,
//                       fit: BoxFit.cover,
//                     )
//                     : _placeholder(),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   story['title'] ?? '',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     _badge(
//                       story['status'] ?? 'draft',
//                       _statusColor(story['status']),
//                     ),
//                     const SizedBox(width: 6),
//                     _badge(
//                       '${story['total_chapters'] ?? 0} chapters',
//                       Colors.grey,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.visibility_outlined,
//                       color: Colors.grey,
//                       size: 14,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${story['total_views'] ?? 0}',
//                       style: const TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                     const SizedBox(width: 12),
//                     const Icon(
//                       Icons.star_outline,
//                       color: Colors.grey,
//                       size: 14,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${double.tryParse(story['average_rating'].toString())?.toStringAsFixed(1) ?? '0.0'}',
//                       style: const TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             children: [
//               IconButton(
//                 icon: Icon(
//                   Icons.list_alt_outlined,
//                   color: Colors.grey[400],
//                   size: 20,
//                 ),
//                 onPressed: onViewChapters,
//                 tooltip: 'View chapters',
//               ),
//               IconButton(
//                 icon: Icon(
//                   Icons.add_circle_outline,
//                   color: depperBlue,
//                   size: 20,
//                 ),
//                 onPressed: onAddChapter,
//                 tooltip: 'Add chapter',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _placeholder() => Container(
//     width: 60,
//     height: 80,
//     decoration: BoxDecoration(
//       color: Colors.grey[800],
//       borderRadius: BorderRadius.circular(8),
//     ),
//     child: const Icon(Icons.book, color: Colors.grey),
//   );

//   Widget _badge(String text, Color color) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//     decoration: BoxDecoration(
//       color: color.withOpacity(0.2),
//       borderRadius: BorderRadius.circular(4),
//     ),
//     child: Text(
//       text,
//       style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
//     ),
//   );

//   Color _statusColor(String? status) {
//     switch (status) {
//       case 'ongoing':
//         return Colors.blue;
//       case 'completed':
//         return Colors.green;
//       case 'paused':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }
// }

// // ── Shared form helpers ────────────────────────────────────────────────────────
// Widget _field(
//   String label,
//   TextEditingController ctrl,
//   String hint, {
//   int maxLines = 1,
//   TextInputType? keyboardType,
// }) => Column(
//   crossAxisAlignment: CrossAxisAlignment.start,
//   children: [
//     Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
//     const SizedBox(height: 8),
//     TextField(
//       controller: ctrl,
//       maxLines: maxLines,
//       keyboardType: keyboardType,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: const TextStyle(color: Colors.grey),
//         filled: true,
//         fillColor: const Color(0xFF2a2a2a),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide.none,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Color(0xFF3a3a3a)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: depperBlue, width: 1.5),
//         ),
//       ),
//     ),
//   ],
// );

// InputDecoration _inputDec() => InputDecoration(
//   filled: true,
//   fillColor: const Color(0xFF2a2a2a),
//   border: OutlineInputBorder(
//     borderRadius: BorderRadius.circular(10),
//     borderSide: BorderSide.none,
//   ),
//   enabledBorder: OutlineInputBorder(
//     borderRadius: BorderRadius.circular(10),
//     borderSide: const BorderSide(color: Color(0xFF3a3a3a)),
//   ),
// );

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/author/author_chapters_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';

class AuthorDashboardController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList myStories = [].obs;
  final RxList genres = [].obs;

  // Create story form
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final plotCtrl = TextEditingController();
  final selectedGenreId = Rx<int?>(null);
  final selectedStatus = 'draft'.obs;
  final selectedLang = 'en'.obs;
  final selectedGender = 'male'.obs;
  final isCreating = false.obs;
  final createError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyStories();
    fetchGenres();
  }

  Future<void> fetchMyStories() async {
    isLoading.value = true;
    final res = await ApiService.getMyStories();
    isLoading.value = false;
    if (res['success']) {
      final d = res['data'];
      myStories.value = d is List ? d : (d['results'] ?? []);
    }
  }

  Future<void> fetchGenres() async {
    final res = await ApiService.getGenres();
    if (res['success']) {
      genres.value = res['data'] is List ? res['data'] : [];
    }
  }

  Future<void> createStory() async {
    if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
      createError.value = 'Title and description are required';
      return;
    }
    isCreating.value = true;
    createError.value = '';
    final body = <String, dynamic>{
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'plot_summary': plotCtrl.text.trim(),
      'status': selectedStatus.value,
      'language': selectedLang.value,
      'gender': selectedGender.value,
      if (selectedGenreId.value != null) 'genre_id': selectedGenreId.value,
    };
    final res = await ApiService.createStory(body);
    isCreating.value = false;
    if (res['success']) {
      Get.back();
      fetchMyStories();
      titleCtrl.clear();
      descCtrl.clear();
      plotCtrl.clear();
      AppAlert.success('🎉 Story Created! — "${res['data']['title']}" is live!');
    } else {
      createError.value = res['error'] ?? 'Failed to create story';
    }
  }

  String getCoverUrl(Map story) {
    final c = story['cover_image'];
    if (c == null || c.toString().isEmpty) {
      return '';
    }
    if (c.toString().startsWith('http')) {
      return c.toString();
    }
    return 'http://10.0.2.2:8000$c';
  }
}

class AuthorDashboardScreen extends StatelessWidget {
  const AuthorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AuthorDashboardController());
    final auth = Get.find<AuthController>();

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
          appBar: AppBar(
            backgroundColor: bg,
            leading: IconButton(
              icon: Icon(Icons.chevron_left, color: onBg, size: 28),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Author Dashboard',
              style: TextStyle(color: txt, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: depperBlue),
                onPressed: () => _showCreateStorySheet(context, ctrl),
              ),
            ],
          ),
          body: Obx(() {
            final user = auth.currentUser.value;
            final profile = user?['author_profile'];
            return RefreshIndicator(
              onRefresh: ctrl.fetchMyStories,
              color: depperBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Earnings Card ─────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            depperBlue.withOpacity(0.8),
                            const Color(0xFF003d80),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _earningsStat(
                                'Total Earned',
                                '\$${profile?['total_earnings'] ?? '0.00'}',
                                Icons.account_balance_wallet,
                              ),
                              _earningsStat(
                                'Pending Payout',
                                '\$${profile?['pending_payout'] ?? '0.00'}',
                                Icons.pending,
                              ),
                              _earningsStat(
                                'My Coins',
                                '${auth.coins}',
                                Icons.monetization_on,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (profile != null &&
                              double.parse(
                                    profile['pending_payout'].toString(),
                                  ) >
                                  0)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                                onPressed: () => _requestPayout(context),
                                child: const Text('Request Payout'),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── My Stories ────────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Stories',
                          style: TextStyle(
                            color: txt,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${ctrl.myStories.length} stories',
                            style: TextStyle(color: sub, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (ctrl.isLoading.value)
                      Center(
                        child: Center(
                          child: Container(
                            color: bg.withValues(alpha: 0.8),
                            child: Center(
                              child: Container(
                                height: 130,
                                width: 130,
                                decoration: BoxDecoration(
                                  color: onBg,
                                  borderRadius: BorderRadius.circular(16),
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
                              // ),
                            ),
                          ),
                        ),
                      )
                    else if (ctrl.myStories.isEmpty)
                      _emptyStories(context, ctrl)
                    else
                      ...ctrl.myStories.map(
                        (story) => _StoryCard(
                          cardbg: cardBg,
                          txt: txt,
                          sub: sub,
                          onbg: onBg,
                          story: story,
                          coverUrl: ctrl.getCoverUrl(story),
                          onAddChapter:
                              () =>
                                  _showAddChapterSheet(context, story['slug']),
                          onViewChapters:
                              () => Get.to(
                                () => AuthorChaptersScreen(
                                  storySlug: story['slug'] ?? '',
                                  storyTitle: story['title'] ?? 'Untitled',
                                ),
                              ),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          }),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: depperBlue,
            onPressed: () => _showCreateStorySheet(context, ctrl),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'New Story',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _earningsStat(String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );

  Widget _emptyStories(BuildContext context, AuthorDashboardController ctrl) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.edit_note, color: Colors.grey[700], size: 60),
              const SizedBox(height: 16),
              const Text(
                'No stories yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your first story and start earning!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: depperBlue),
                onPressed: () => _showCreateStorySheet(context, ctrl),
                child: const Text(
                  'Create Story',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );

  void _showCreateStorySheet(BuildContext ctx, AuthorDashboardController ctrl) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.92,
            maxChildSize: 0.97,
            builder:
                (_, sc) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'New Story',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(color: Color(0xFF2a2a2a)),
                      Expanded(
                        child: ListView(
                          controller: sc,
                          padding: const EdgeInsets.all(20),
                          children: [
                            _field(
                              'Title',
                              ctrl.titleCtrl,
                              'Enter story title',
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'Description',
                              ctrl.descCtrl,
                              'Write a compelling description...',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'Plot Summary',
                              ctrl.plotCtrl,
                              'Brief plot overview...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),

                            // Genre picker
                            const Text(
                              'Genre',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => DropdownButtonFormField<int>(
                                value: ctrl.selectedGenreId.value,
                                dropdownColor: const Color(0xFF2a2a2a),
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDec(),
                                hint: const Text(
                                  'Select genre',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                items:
                                    ctrl.genres
                                        .map<DropdownMenuItem<int>>(
                                          (g) => DropdownMenuItem(
                                            value: g['id'],
                                            child: Text(g['name'] ?? ''),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) => ctrl.selectedGenreId.value = v,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Language
                            const Text(
                              'Language',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => DropdownButtonFormField<String>(
                                value: ctrl.selectedLang.value,
                                dropdownColor: const Color(0xFF2a2a2a),
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDec(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text('English'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fr',
                                    child: Text('French'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'yo',
                                    child: Text('Yoruba'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ig',
                                    child: Text('Igbo'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ha',
                                    child: Text('Hausa'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sw',
                                    child: Text('Swahili'),
                                  ),
                                ],
                                onChanged: (v) => ctrl.selectedLang.value = v!,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Obx(
                              () => DropdownButtonFormField<String>(
                                value: ctrl.selectedGender.value,
                                dropdownColor: const Color(0xFF2a2a2a),
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDec(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text('Female'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'prefer_not_to_say',
                                    child: Text('Prefer not to say'),
                                  ),
                                  // DropdownMenuItem(
                                  //   value: 'ig',
                                  //   child: Text('Igbo'),
                                  // ),
                                  // DropdownMenuItem(
                                  //   value: 'ha',
                                  //   child: Text('Hausa'),
                                  // ),
                                  // DropdownMenuItem(
                                  //   value: 'sw',
                                  //   child: Text('Swahili'),
                                  // ),
                                ],
                                onChanged:
                                    (v) => ctrl.selectedGender.value = v!,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Note: "exclusive" is not author-selectable —
                            // it is set automatically when an exclusive
                            // contract is signed.

                            // Error
                            Obx(
                              () =>
                                  ctrl.createError.value.isNotEmpty
                                      ? Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Text(
                                          ctrl.createError.value,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13,
                                          ),
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                            ),

                            // Submit
                            Obx(
                              () => SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: depperBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      ctrl.isCreating.value
                                          ? null
                                          : ctrl.createStory,
                                  child:
                                      ctrl.isCreating.value
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            'Publish Story',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                ),
                              ),
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

  void _showAddChapterSheet(BuildContext ctx, String storySlug) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final chNumCtrl = TextEditingController();
    final coinCtrl = TextEditingController(text: '20');
    final isLocked = RxBool(true);
    final isLoading = RxBool(false);
    final error = RxString('');
    final wordCount = RxInt(0);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.92,
            maxChildSize: 0.97,
            builder:
                (_, sc) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Add Chapter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(color: Color(0xFF2a2a2a)),

                      Expanded(
                        child: ListView(
                          controller: sc,
                          padding: const EdgeInsets.all(20),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _field(
                                    'Chapter #',
                                    chNumCtrl,
                                    'e.g. 1',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 5,
                                  child: _field(
                                    'Chapter Title',
                                    titleCtrl,
                                    'Enter title',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _field(
                              'Content',
                              contentCtrl,
                              'Write your chapter here...',
                              maxLines: 12,
                              onChanged: (val) {
                                final trimmed = val.trim();
                                wordCount.value =
                                    trimmed.isEmpty
                                        ? 0
                                        : trimmed.split(RegExp(r'\s+')).length;
                              },
                            ),
                            const SizedBox(height: 6),
                            Obx(
                              () => Text(
                                '${wordCount.value} words',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Obx(
                              () => SwitchListTile(
                                tileColor: const Color(0xFF2a2a2a),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                title: const Text(
                                  'Lock this chapter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Readers pay coins to unlock',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                value: isLocked.value,
                                onChanged: (v) => isLocked.value = v,
                                activeColor: depperBlue,
                              ),
                            ),
                            Obx(
                              () =>
                                  isLocked.value
                                      ? Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: _field(
                                          'Coin Cost',
                                          coinCtrl,
                                          '20',
                                          keyboardType: TextInputType.number,
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 24),
                            Obx(
                              () =>
                                  error.value.isNotEmpty
                                      ? Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Text(
                                          error.value,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13,
                                          ),
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                            ),
                            Obx(
                              () => SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: depperBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      isLoading.value
                                          ? null
                                          : () async {
                                            if (titleCtrl.text.isEmpty ||
                                                contentCtrl.text.isEmpty ||
                                                chNumCtrl.text.isEmpty) {
                                              error.value =
                                                  'All fields are required';
                                              return;
                                            }
                                            isLoading.value = true;
                                            error.value = '';
                                            final res =
                                                await ApiService.createChapter(
                                                  storySlug,
                                                  {
                                                    'title':
                                                        titleCtrl.text.trim(),
                                                    'content':
                                                        contentCtrl.text.trim(),
                                                    'chapter_number':
                                                        int.tryParse(
                                                          chNumCtrl.text,
                                                        ) ??
                                                        1,
                                                    'is_locked': isLocked.value,
                                                    'coin_cost':
                                                        int.tryParse(
                                                          coinCtrl.text,
                                                        ) ??
                                                        20,
                                                    'is_published': true,
                                                  },
                                                );
                                            isLoading.value = false;
                                            if (res['success']) {
                                              Get.back();
                                              AppAlert.success('Chapter Published! — "${titleCtrl.text}" is now live.');
                                            } else {
                                              error.value =
                                                  res['error'] ??
                                                  'Failed to publish';
                                            }
                                          },
                                  child:
                                      isLoading.value
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            'Publish Chapter',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
    // showModalBottomSheet(
    //   context: ctx,
    //   isScrollControlled: true,
    //   backgroundColor: const Color(0xFF1a1a1a),
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    //   ),
    //   builder:
    //       (_) => DraggableScrollableSheet(
    //         expand: false,
    //         initialChildSize: 0.92,
    //         maxChildSize: 0.97,
    //         builder:
    //             (_, sc) => Padding(
    //               padding: EdgeInsets.only(
    //                 bottom: MediaQuery.of(ctx).viewInsets.bottom,
    //               ),
    //               child: Column(
    //                 children: [
    //                   const SizedBox(height: 8),
    //                   Container(
    //                     width: 40,
    //                     height: 4,
    //                     decoration: BoxDecoration(
    //                       color: Colors.grey[700],
    //                       borderRadius: BorderRadius.circular(2),
    //                     ),
    //                   ),
    //                   const SizedBox(height: 12),
    //                   const Text(
    //                     'Add Chapter',
    //                     style: TextStyle(
    //                       color: Colors.white,
    //                       fontWeight: FontWeight.bold,
    //                       fontSize: 18,
    //                     ),
    //                   ),
    //                   const Divider(color: Color(0xFF2a2a2a)),
    //                   Expanded(
    //                     child: ListView(
    //                       controller: sc,
    //                       padding: const EdgeInsets.all(20),
    //                       children: [
    //                         Row(
    //                           children: [
    //                             Expanded(
    //                               flex: 2,
    //                               child: _field(
    //                                 'Chapter #',
    //                                 chNumCtrl,
    //                                 'e.g. 1',
    //                                 keyboardType: TextInputType.number,
    //                               ),
    //                             ),
    //                             const SizedBox(width: 12),
    //                             Expanded(
    //                               flex: 5,
    //                               child: _field(
    //                                 'Chapter Title',
    //                                 titleCtrl,
    //                                 'Enter title',
    //                               ),
    //                             ),
    //                           ],
    //                         ),
    //                         const SizedBox(height: 16),
    //                         _field(
    //                           'Content',
    //                           contentCtrl,
    //                           'Write your chapter here...',
    //                           maxLines: 12,
    //                         ),
    //                         const SizedBox(height: 16),

    //                         Obx(
    //                           () => SwitchListTile(
    //                             tileColor: const Color(0xFF2a2a2a),
    //                             shape: RoundedRectangleBorder(
    //                               borderRadius: BorderRadius.circular(10),
    //                             ),
    //                             title: const Text(
    //                               'Lock this chapter',
    //                               style: TextStyle(
    //                                 color: Colors.white,
    //                                 fontSize: 13,
    //                               ),
    //                             ),
    //                             subtitle: const Text(
    //                               'Readers pay coins to unlock',
    //                               style: TextStyle(
    //                                 color: Colors.grey,
    //                                 fontSize: 11,
    //                               ),
    //                             ),
    //                             value: isLocked.value,
    //                             onChanged: (v) => isLocked.value = v,
    //                             activeColor: depperBlue,
    //                           ),
    //                         ),
    //                         Obx(
    //                           () =>
    //                               isLocked.value
    //                                   ? Padding(
    //                                     padding: const EdgeInsets.only(top: 16),
    //                                     child: _field(
    //                                       'Coin Cost',
    //                                       coinCtrl,
    //                                       '20',
    //                                       keyboardType: TextInputType.number,
    //                                     ),
    //                                   )
    //                                   : const SizedBox.shrink(),
    //                         ),
    //                         const SizedBox(height: 24),
    //                         Obx(
    //                           () =>
    //                               error.value.isNotEmpty
    //                                   ? Padding(
    //                                     padding: const EdgeInsets.only(
    //                                       bottom: 12,
    //                                     ),
    //                                     child: Text(
    //                                       error.value,
    //                                       style: const TextStyle(
    //                                         color: Colors.redAccent,
    //                                         fontSize: 13,
    //                                       ),
    //                                     ),
    //                                   )
    //                                   : const SizedBox.shrink(),
    //                         ),
    //                         Obx(
    //                           () => SizedBox(
    //                             width: double.infinity,
    //                             height: 52,
    //                             child: ElevatedButton(
    //                               style: ElevatedButton.styleFrom(
    //                                 backgroundColor: depperBlue,
    //                                 shape: RoundedRectangleBorder(
    //                                   borderRadius: BorderRadius.circular(12),
    //                                 ),
    //                               ),
    //                               onPressed:
    //                                   isLoading.value
    //                                       ? null
    //                                       : () async {
    //                                         if (titleCtrl.text.isEmpty ||
    //                                             contentCtrl.text.isEmpty ||
    //                                             chNumCtrl.text.isEmpty) {
    //                                           error.value =
    //                                               'All fields are required';
    //                                           return;
    //                                         }
    //                                         isLoading.value = true;
    //                                         error.value = '';
    //                                         final res =
    //                                             await ApiService.createChapter(
    //                                               storySlug,
    //                                               {
    //                                                 'title':
    //                                                     titleCtrl.text.trim(),
    //                                                 'content':
    //                                                     contentCtrl.text.trim(),
    //                                                 'chapter_number':
    //                                                     int.tryParse(
    //                                                       chNumCtrl.text,
    //                                                     ) ??
    //                                                     1,
    //                                                 'is_locked': isLocked.value,
    //                                                 'coin_cost':
    //                                                     int.tryParse(
    //                                                       coinCtrl.text,
    //                                                     ) ??
    //                                                     20,
    //                                                 'is_published': true,
    //                                               },
    //                                             );
    //                                         isLoading.value = false;
    //                                         if (res['success']) {
    //                                           Get.back();
    //                                           Get.snackbar(
    //                                             'Chapter Published!',
    //                                             '"${titleCtrl.text}" is now live.',
    //                                             backgroundColor: Colors.green,
    //                                             colorText: Colors.white,
    //                                           );
    //                                         } else {
    //                                           error.value =
    //                                               res['error'] ??
    //                                               'Failed to publish';
    //                                         }
    //                                       },
    //                               child:
    //                                   isLoading.value
    //                                       ? const SizedBox(
    //                                         width: 20,
    //                                         height: 20,
    //                                         child: CircularProgressIndicator(
    //                                           strokeWidth: 2,
    //                                           color: Colors.white,
    //                                         ),
    //                                       )
    //                                       : const Text(
    //                                         'Publish Chapter',
    //                                         style: TextStyle(
    //                                           color: Colors.white,
    //                                           fontWeight: FontWeight.bold,
    //                                           fontSize: 16,
    //                                         ),
    //                                       ),
    //                             ),
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //       ),
    // );
  }

  void _requestPayout(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Request Payout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Request your pending earnings to be paid out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: depperBlue),
            onPressed: () async {
              Get.back();
              final res = await ApiService.requestPayout();
              if (res['success']) {
                AppAlert.success('Payout Requested! — We will process your payout within 3-5 days.');
              }
            },
            child: const Text('Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Map story;
  final String coverUrl;
  final VoidCallback onAddChapter;
  final VoidCallback onViewChapters;
  final Color cardbg;
  final Color txt;
  final Color sub;
  final Color onbg;
  const _StoryCard({
    required this.story,
    required this.coverUrl,
    required this.onAddChapter,
    required this.onViewChapters,
    required this.cardbg,
    required this.txt,
    required this.sub,
    required this.onbg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onViewChapters, child: _buildCard(context));
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardbg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                coverUrl.isNotEmpty
                    ? CustomImageView(
                      imagePath: coverUrl,
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                    : 
                    CustomImageView(
                      imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    //_placeholder(),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _badge(
                      story['status'] ?? 'draft',
                      _statusColor(story['status']),
                    ),
                    const SizedBox(width: 6),
                    _badge('${story['total_chapters'] ?? 0} chapters', sub),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: sub, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${story['total_views'] ?? 0}',
                      style: TextStyle(color: sub, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.star_outline,
                      color: Colors.grey,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${double.tryParse(story['average_rating'].toString())?.toStringAsFixed(1) ?? '0.0'}',
                      style: TextStyle(color: sub, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(Icons.list_alt_outlined, color: onbg, size: 20),
                onPressed: onViewChapters,
                tooltip: 'View chapters',
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: depperBlue,
                  size: 20,
                ),
                onPressed: onAddChapter,
                tooltip: 'Add chapter',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 60,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.grey[800],
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.book, color: Colors.grey),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );

  Color _statusColor(String? status) {
    switch (status) {
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ── Shared form helpers ────────────────────────────────────────────────────────
Widget _field(
  String label,
  TextEditingController ctrl,
  String hint, {
  int maxLines = 1,
  TextInputType? keyboardType,
  void Function(String)? onChanged,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    const SizedBox(height: 8),
    TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2a2a2a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3a3a3a)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: depperBlue, width: 1.5),
        ),
      ),
    ),
  ],
);

InputDecoration _inputDec() => InputDecoration(
  filled: true,
  fillColor: const Color(0xFF2a2a2a),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF3a3a3a)),
  ),
);
