// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:novelux/config/local_storage.dart';
// import 'dart:developer' as myLog;

// class ApiService {
//   static const String baseUrl = 'https://novelux.onrender.com/api';
//   //'http://10.0.2.2:8000/api';
//   // Use http://localhost:8000/api for iOS simulator
//   // Use http://YOUR_PC_IP:8000/api for physical device

//   static final DataBase _db = Get.find<DataBase>();

//   // ── Generic request handler ────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> _request(
//     String method,
//     String endpoint, {
//     Map<String, dynamic>? body,
//     bool requiresAuth = true,
//     bool isFormData = false,
//   }) async {
//     myLog.log(endpoint);
//     final token = await _db.getToken();
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };

//     final uri = Uri.parse('$baseUrl$endpoint');
//     http.Response response;

//     try {
//       switch (method.toUpperCase()) {
//         case 'GET':
//           response = await http.get(uri, headers: headers);
//           break;
//         case 'POST':
//           response = await http.post(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'PATCH':
//           response = await http.patch(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'DELETE':
//           response = await http.delete(uri, headers: headers);
//           break;
//         default:
//           throw Exception('Unsupported HTTP method: $method');
//       }

//       final decoded = jsonDecode(utf8.decode(response.bodyBytes));

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         // myLog.log(decoded);
//         return {
//           'success': true,
//           'data': decoded,
//           'status': response.statusCode,
//         };
//       } else {
//         return {
//           'success': false,
//           'data': decoded,
//           'status': response.statusCode,
//           'error': _extractError(decoded),
//         };
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Network error: $e', 'status': 0};
//     }
//   }

//   void _logResponse(http.Response response) {
//     if (kDebugMode) {
//       print('--- API Response ---');
//       print('Status Code: ${response.statusCode}');
//       print('URL: ${response.request?.url}');
//       try {
//         // Attempt to decode and print if JSON, otherwise print raw body
//         final decodedBody = jsonDecode(response.body);
//         print('Body: ${jsonEncode(decodedBody)}'); // Pretty print JSON
//       } catch (e) {
//         print('Body: ${response.body}'); // Print as is if not JSON
//       }
//       print('--------------------');
//     }
//   }

//   static String _extractError(dynamic decoded) {
//     if (decoded is Map) {
//       if (decoded.containsKey('detail')) {
//         return decoded['detail'].toString();
//       }
//       final firstKey = decoded.keys.first;
//       final firstVal = decoded[firstKey];
//       if (firstVal is List) {
//         return '$firstKey: ${firstVal.first}';
//       }
//       return firstVal.toString();
//     }
//     return decoded.toString();
//   }

//   // Helper function for logging
//   void _logRequest(String method, Uri url, {dynamic body}) {
//     if (kDebugMode) {
//       print('--- API Request ---');
//       print('Method: $method');
//       print('URL: $url');
//       if (body != null) {
//         print('Body: ${jsonEncode(body)}');
//       }
//       print('-------------------');
//     }
//   }

//   // ── Auth ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> register({
//     required String username,
//     required String email,
//     required String password1,
//     required String password2,
//     String role = 'reader',
//   }) => _request(
//     'POST',
//     '/auth/dj/registration/',
//     body: {
//       'username': username,
//       'email': email,
//       'password1': password1,
//       'password2': password2,
//       'role': role,
//     },
//     requiresAuth: false,
//   );

//   /// send fcm token to backend
//   Future<http.Response> sendFcmToken(Map<String, dynamic> replyData) async {
//     final token = await _db.getToken();
//     final url = Uri.parse('$baseUrl/auth/save-fcm-token/');
//     _logRequest('POST', url, body: replyData);
//     final response = await http.post(
//       url,
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Accept': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode(replyData),
//     );
//     _logResponse(response);
//     return response;
//   }

//   static Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) => _request(
//     'POST',
//     '/auth/token/',
//     body: {'email': email, 'password': password},
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> refreshToken(String refresh) => _request(
//     'POST',
//     '/auth/token/refresh/',
//     body: {'refresh': refresh},
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getMe() => _request('GET', '/auth/me/');

//   static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
//       _request('PATCH', '/auth/me/', body: data);

//   static Future<Map<String, dynamic>> becomeAuthor() =>
//       _request('POST', '/auth/become-author/');

//   static Future<Map<String, dynamic>> followUser(String username) =>
//       _request('POST', '/auth/follow/$username/');
//   //TODO: verify purchase endpoint is currently open to all users, but should be restricted to admins only. This is because the app needs to verify purchases before unlocking chapters, and we don't want to expose this functionality to regular users. Once the purchase verification flow is fully implemented and tested, we can update the backend to restrict access to this endpoint.
//   static Future<Map<String, dynamic>> verifyPurchase({
//     required String productId,
//     required String purchaseId,
//     required String receipt,
//     required String platform, // 'android' or 'ios'
//   }) => _request(
//     'POST',
//     '/auth/verify-purchase/',
//     body: {
//       'product_id': productId,
//       'purchase_token': purchaseId,
//       'receipt': receipt,
//       'platform': platform,
//     },
//   );

//   static Future<Map<String, dynamic>> unfollowUser(String username) =>
//       _request('DELETE', '/auth/follow/$username/');

//   // ── Stories ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStories({
//     String? genre,
//     String? tag,
//     String? search,
//     String? language,
//     String? status,
//     String? targetGender, // 'male' | 'female' | 'prefer_not_to_say'
//     int page = 1,
//     int pageSize = 5, // ← added for pagination
//   }) {
//     myLog.log(genre ?? 'N/A');
//     var params = '';
//     if (genre != null)
//       params += '?genre=${genre.replaceAll(' ', '-').toLowerCase()}';
//     if (tag != null) params += '&tag=$tag';
//     if (search != null) params += '&search=$search';
//     if (language != null) params += '&language=$language';
//     if (status != null) params += '&status=$status';
//     // if (targetGender != null && targetGender.isNotEmpty)
//     (genre != null && genre.isNotEmpty)
//         ? params += '&page=$page&page_size=$pageSize'
//         : params += '?page=$page&page_size=$pageSize';

//     // params += '&target_gender=$targetGender';
//     // params += '&page=$page&page_size=$pageSize';
//     return _request('GET', '/stories/$params', requiresAuth: false);
//   }

//   /// Personalised feed — sends preferred genres + gender to backend
//   static Future<Map<String, dynamic>> getPersonalisedFeed({
//     required List<String> genres,
//     String gender = '',
//     String? tab,
//     int page = 1,
//     int pageSize = 5, // ← added for pagination
//   }) {
//     var params = '?page=$page&page_size=$pageSize';
//     if (genres.isNotEmpty) params += "&genres=${genres.join(',')}";
//     if (gender.isNotEmpty) params += '&gender=$gender';
//     if (tab != null && tab != 'All') params += '&genre=$tab';
//     return _request('GET', '/stories/personalised/$params');
//   }

//   static Future<Map<String, dynamic>> getCompletedStories({
//     int page = 1,
//     int pageSize = 5,
//   }) => _request(
//     'GET',
//     '/stories/completed-stories/?page=$page&page_size=$pageSize',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getFreeDownLoad({
//     int page = 1,
//     int pageSize = 5,
//   }) => _request(
//     'GET',
//     '/stories/free-download/?page=$page&page_size=$pageSize',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getWorldFamous({
//     int page = 1,
//     int pageSize = 5,
//   }) => _request(
//     'GET',
//     '/stories/world-Famous/?page=$page&page_size=$pageSize',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getAfricanFolkTale({
//     int page = 1,
//     int pageSize = 5,
//   }) => _request(
//     'GET',
//     '/stories/african-folktale/?page=$page&page_size=$pageSize',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getTrending({
//     int page = 1,
//     int pageSize = 5,
//   }) => _request(
//     'GET',
//     '/stories/trending/?page=$page&page_size=$pageSize',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getFeatured({
//     int page = 1,
//     int pageSize = 5,
//   }) => _request(
//     'GET',
//     '/stories/featured/?page=$page&page_size=$pageSize',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getEditorsPick({
//     int page = 1,
//     int pageSize = 5,
//   }) => _request(
//     'GET',
//     '/stories/editors-pick/?page=$page&page_size=$pageSize',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
//       _request('GET', '/stories/$slug/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getGenres() =>
//       _request('GET', '/stories/genres/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTags() =>
//       _request('GET', '/stories/tags/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getMyBookmarks() =>
//       _request('GET', '/stories/bookmarks/');

//   static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
//       _request('POST', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> removeBookmark(String slug) =>
//       _request('DELETE', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> rateStory(
//     String slug,
//     int score,
//     String review,
//   ) => _request(
//     'POST',
//     '/stories/$slug/rate/',
//     body: {'score': score, 'review': review},
//   );

//   static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
//       _request('POST', '/stories/', body: data);

//   static Future<Map<String, dynamic>> updateStory(
//     String slug,
//     Map<String, dynamic> data,
//   ) => _request('PATCH', '/stories/$slug/', body: data);

//   static Future<Map<String, dynamic>> getMyStories() =>
//       _request('GET', '/stories/mine/');

//   // ── Chapters ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getChapters(String storySlug) =>
//       _request('GET', '/chapters/$storySlug/chapters/', requiresAuth: true);

//   static Future<Map<String, dynamic>> getChapter(
//     String storySlug,
//     int chapterNumber,
//   ) => _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

//   static Future<Map<String, dynamic>> unlockChapter(
//     String storySlug,
//     int chapterNumber,
//   ) => _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

//   static Future<Map<String, dynamic>> createChapter(
//     String storySlug,
//     Map<String, dynamic> data,
//   ) => _request('POST', '/chapters/$storySlug/chapters/', body: data);

//   // ── Coins ──────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getCoinPackages() =>
//       _request('GET', '/coins/packages/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getSubscriptionPlans() =>
//       _request('GET', '/coins/plans/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getCoinBalance() =>
//       _request('GET', '/coins/balance/');

//   static Future<Map<String, dynamic>> createCheckout(
//     String purchaseType, {
//     String? packageId,
//     String? planId,
//   }) => _request(
//     'POST',
//     '/coins/checkout/',
//     body: {
//       'purchase_type': purchaseType,
//       if (packageId != null) 'package_id': packageId,
//       if (planId != null) 'plan_id': planId,
//     },
//   );

//   // ── Comments ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getComments(
//     String storySlug,
//     int chapterNumber,
//   ) => _request(
//     'GET',
//     '/comments/$storySlug/chapters/$chapterNumber/comments/',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> postComment(
//     String storySlug,
//     int chapterNumber,
//     String content, {
//     int? parentId,
//     int? paragraphIndex,
//   }) => _request(
//     'POST',
//     '/comments/$storySlug/chapters/$chapterNumber/comments/',
//     body: {
//       'content': content,
//       if (parentId != null) 'parent': parentId,
//       if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
//     },
//   );

//   static Future<Map<String, dynamic>> likeComment(int commentId) =>
//       _request('POST', '/comments/comment/$commentId/like/');

//   static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
//       _request('DELETE', '/comments/comment/$commentId/like/');

//   // ── Tips ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> sendTip(
//     String storySlug,
//     int coins, {
//     String? message,
//   }) => _request(
//     'POST',
//     '/tips/$storySlug/tip/',
//     body: {
//       'coins_amount':
//           coins.toInt(), // explicit int — prevents string serialisation
//       if (message != null && message.isNotEmpty) 'message': message,
//     },
//   );

//   static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
//       _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

//   // ── Notifications ──────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getNotifications() =>
//       _request('GET', '/notifications/');

//   static Future<Map<String, dynamic>> getUnreadCount() =>
//       _request('GET', '/notifications/unread/');

//   static Future<Map<String, dynamic>> markAllRead() =>
//       _request('POST', '/notifications/mark-all-read/');

//   static Future<Map<String, dynamic>> markRead(int id) =>
//       _request('POST', '/notifications/$id/read/');
//   //}

//   static Future<Map<String, dynamic>> requestPayout() => _request(
//     'POST',
//     '/coins/payout/request/',
//     body: {'payout_method': 'bank_transfer'},
//   );

//   static Future<Map<String, dynamic>> getPublicProfile(String username) =>
//       _request('GET', '/auth/profile/$username/', requiresAuth: false);

//   // ── Reviews ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStoryReviews(
//     String slug, {
//     String type = 'all',
//   }) {
//     final query = type == 'all' ? '' : '?rating=$type';
//     return _request(
//       'GET',
//       '/stories/reviews/$slug/reviews/$query',
//       requiresAuth: false,
//     );
//   }

//   static Future<Map<String, dynamic>> submitReview(
//     String slug, {
//     required String rating,
//     String content = '',
//   }) => _request(
//     'POST',
//     '/stories/reviews/$slug/reviews/',
//     body: {'rating': rating, 'content': content},
//   );
//   // myLog.log(content);
//   // ── Rewards ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> claimDailyReward(int coins) =>
//       _request('POST', '/coins/claim-reward/', body: {'coins': coins});

//   // ── VIP / Subscription ─────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getVipStatus() =>
//       _request('GET', '/coins/vip-status/');

//   static Future<Map<String, dynamic>> cancelSubscription() =>
//       _request('POST', '/coins/subscription/cancel/');

//   // ── Reading Schedule & Sessions ────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getReadingSchedule() =>
//       _request('GET', '/reading/schedule/');

//   static Future<Map<String, dynamic>> saveReadingSchedule(
//     Map<String, dynamic> data,
//   ) => _request('POST', '/reading/schedule/', body: data);

//   static Future<Map<String, dynamic>> logReadingSession({
//     required String storySlug,
//     required int chapter,
//     required int minutes,
//   }) => _request(
//     'POST',
//     '/reading/session/',
//     body: {'story_slug': storySlug, 'chapter': chapter, 'minutes': minutes},
//   );

//   static Future<Map<String, dynamic>> getReadingStats({int goal = 30}) =>
//       _request('GET', '/reading/stats/?goal=$goal');

//   // ── User Preferences ───────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> saveUserPreferences({
//     required List<String> genres,
//     String gender = '',
//   }) => _request(
//     'POST',
//     '/auth/preferences/',
//     body: {'preferred_genres': genres, if (gender.isNotEmpty) 'gender': gender},
//   );

//   static Future<Map<String, dynamic>> getUserPreferences() =>
//       _request('GET', '/auth/preferences/');

//   // ── Promo banners ───────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getPromoBanners() =>
//       _request('GET', '/stories/banners/', requiresAuth: false);

//   // ── Reading History ───────────────────────────────────────────────────────
//   /// GET /api/reading/history/ — server-side reading history (paginated)
//   static Future<Map<String, dynamic>> getReadingHistory({int page = 1}) =>
//       _request('GET', '/reading/history/?page=$page');

//   /// POST /api/reading/history/  — log that user opened a chapter
//   /// Log a reading history entry.
//   /// Endpoint: POST /api/reading/history/
//   /// ⚠️  Do NOT change to '/history/' — the full path is '/reading/history/'
//   static Future<Map<String, dynamic>> logReadingHistory({
//     required String storySlug,
//     required int chapterNumber,
//     required String chapterTitle,
//   }) => _request(
//     'POST',
//     '/reading/history/',
//     body: {
//       'story_slug': storySlug, // backend field: story_slug
//       'chapter_number': chapterNumber,
//       'chapter_title': chapterTitle,
//     },
//   );

//   /// DELETE /api/reading/history/<id>/  — remove single history entry
//   static Future<Map<String, dynamic>> deleteReadingHistory(int id) =>
//       _request('DELETE', '/reading/history/$id/');

//   /// DELETE /api/reading/history/  — clear all history
//   static Future<Map<String, dynamic>> clearReadingHistory() =>
//       _request('DELETE', '/reading/history/');

//   // ── Book request ("not found, please tell us") ────────────────────────────
//   static Future<Map<String, dynamic>> requestBook({
//     required String title,
//     String author = '',
//   }) => _request(
//     'POST',
//     '/stories/request/',
//     body: {'title': title, if (author.isNotEmpty) 'author': author},
//   );

//   // ── Google Sign-In ────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> googleSignIn({
//     required String idToken,
//     required String email,
//     String? displayName,
//     String? photoUrl,
//   }) => _request(
//     'POST',
//     '/auth/google/',
//     body: {
//       'id_token': idToken,
//       'email': email,
//       if (displayName != null) 'display_name': displayName,
//       if (photoUrl != null) 'photo_url': photoUrl,
//     },
//     requiresAuth: false,
//   );
// }

// // > Task :app:signingReport
// // Variant: debug
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------
// // Variant: release
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------
// // Variant: profile
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :device_info_plus:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :file_picker:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :firebase_core:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :firebase_messaging:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :flutter_inappwebview_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :flutter_local_notifications:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :flutter_native_splash:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :flutter_plugin_android_lifecycle:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :flutter_timezone:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :google_sign_in_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :image_picker_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :local_auth_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :open_file_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :package_info_plus:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :path_provider_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :permission_handler_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :screen_brightness_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :share_plus:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :shared_preferences_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :sqflite_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :url_launcher_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :wakelock_plus:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------

// // > Task :webview_flutter_android:signingReport
// // Variant: debugAndroidTest
// // Config: debug
// // Store: /home/daniel/.android/debug.keystore
// // Alias: AndroidDebugKey
// // MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// // SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// // SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// // Valid until: Friday, November 12, 2055
// // ----------
// // w: Detected multiple Kotlin daemon sessions at

// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:novelux/config/local_storage.dart';
// import 'dart:developer' as myLog;

// // class ApiService {
// //   static const String baseUrl = 'https://novelux.onrender.com/api';
// //   //'http://127.0.0.1:8000/api';

// //   //'http://10.0.2.2:8000/api';
// //   // Use http://localhost:8000/api for iOS simulator
// //   // Use http://192.168.222.146:8000/api for physical device

// //   static final DataBase _db = Get.find<DataBase>();

// //   // ── Generic request handler ────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> _request(
// //     String method,
// //     String endpoint, {
// //     Map<String, dynamic>? body,
// //     bool requiresAuth = true,
// //     bool isFormData = false,
// //   }) async {
// //     final token = await _db.getToken();
// //     final headers = <String, String>{
// //       'Content-Type': 'application/json',
// //       'Accept': 'application/json',
// //       if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
// //     };

// //     final uri = Uri.parse('$baseUrl$endpoint');
// //     http.Response response;

// //     try {
// //       switch (method.toUpperCase()) {
// //         case 'GET':
// //           response = await http.get(uri, headers: headers);
// //           break;
// //         case 'POST':
// //           response = await http.post(uri,
// //               headers: headers, body: body != null ? jsonEncode(body) : null);
// //           break;
// //         case 'PATCH':
// //           response = await http.patch(uri,
// //               headers: headers, body: body != null ? jsonEncode(body) : null);
// //           break;
// //         case 'DELETE':
// //           response = await http.delete(uri, headers: headers);
// //           break;
// //         default:
// //           throw Exception('Unsupported HTTP method: $method');
// //       }

// //       final decoded = jsonDecode(utf8.decode(response.bodyBytes));

// //       if (response.statusCode >= 200 && response.statusCode < 300) {
// //         return {'success': true, 'data': decoded, 'status': response.statusCode};
// //       } else {
// //         return {
// //           'success': false,
// //           'data': decoded,
// //           'status': response.statusCode,
// //           'error': _extractError(decoded),
// //         };
// //       }
// //     } catch (e) {
// //       return {'success': false, 'error': 'Network error: $e', 'status': 0};
// //     }
// //   }

// //   static String _extractError(dynamic decoded) {
// //     if (decoded is Map) {
// //       if (decoded.containsKey('detail')) {
// //         return decoded['detail'].toString();
// //       }
// //       final firstKey = decoded.keys.first;
// //       final firstVal = decoded[firstKey];
// //       if (firstVal is List) {
// //         return '$firstKey: ${firstVal.first}';
// //       }
// //       return firstVal.toString();
// //     }
// //     return decoded.toString();
// //   }

// //   // ── Auth ───────────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> register({
// //     required String username,
// //     required String email,
// //     required String password1,
// //     required String password2,
// //     String role = 'reader',
// //   }) =>
// //       _request('POST', '/auth/dj/registration/', body: {
// //         'username': username,
// //         'email': email,
// //         'password1': password1,
// //         'password2': password2,
// //         'role': role,
// //       }, requiresAuth: false);

// //   static Future<Map<String, dynamic>> login({
// //     required String email,
// //     required String password,
// //   }) =>
// //       _request('POST', '/auth/token/', body: {
// //         'email': email,
// //         'password': password,
// //       }, requiresAuth: false);

// //   static Future<Map<String, dynamic>> refreshToken(String refresh) =>
// //       _request('POST', '/auth/token/refresh/', body: {'refresh': refresh},
// //           requiresAuth: false);

// //   static Future<Map<String, dynamic>> getMe() =>
// //       _request('GET', '/auth/me/');

// //   static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
// //       _request('PATCH', '/auth/me/', body: data);

// //   static Future<Map<String, dynamic>> becomeAuthor() =>
// //       _request('POST', '/auth/become-author/');

// //   static Future<Map<String, dynamic>> followUser(String username) =>
// //       _request('POST', '/auth/follow/$username/');

// //   static Future<Map<String, dynamic>> unfollowUser(String username) =>
// //       _request('DELETE', '/auth/follow/$username/');

// //   // ── Stories ────────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getStories({
// //     String? genre,
// //     String? tag,
// //     String? search,
// //     String? language,
// //     String? status,
// //     int page = 1,
// //   }) {
// //     var params = '?page=$page';
// //     if (genre != null) params += '&genre=$genre';
// //     if (tag != null) params += '&tag=$tag';
// //     if (search != null) params += '&search=$search';
// //     if (language != null) params += '&language=$language';
// //     if (status != null) params += '&status=$status';
// //     return _request('GET', '/stories/$params', requiresAuth: false);
// //   }

// //   static Future<Map<String, dynamic>> getTrending() =>
// //       _request('GET', '/stories/trending/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getFeatured() =>
// //       _request('GET', '/stories/featured/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getEditorsPick() =>
// //       _request('GET', '/stories/editors-pick/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
// //       _request('GET', '/stories/$slug/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getGenres() =>
// //       _request('GET', '/stories/genres/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getTags() =>
// //       _request('GET', '/stories/tags/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getMyBookmarks() =>
// //       _request('GET', '/stories/bookmarks/');

// //   static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
// //       _request('POST', '/stories/$slug/bookmark/');

// //   static Future<Map<String, dynamic>> removeBookmark(String slug) =>
// //       _request('DELETE', '/stories/$slug/bookmark/');

// //   static Future<Map<String, dynamic>> rateStory(
// //           String slug, int score, String review) =>
// //       _request('POST', '/stories/$slug/rate/', body: {'score': score, 'review': review});

// //   static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
// //       _request('POST', '/stories/', body: data);

// //   static Future<Map<String, dynamic>> updateStory(
// //           String slug, Map<String, dynamic> data) =>
// //       _request('PATCH', '/stories/$slug/', body: data);

// //   static Future<Map<String, dynamic>> getMyStories() =>
// //       _request('GET', '/stories/mine/');

// //   // ── Chapters ───────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getChapters(String storySlug) =>
// //       _request('GET', '/chapters/$storySlug/chapters/', requiresAuth: true);

// //   static Future<Map<String, dynamic>> getChapter(
// //           String storySlug, int chapterNumber) =>
// //       _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

// //   static Future<Map<String, dynamic>> unlockChapter(
// //           String storySlug, int chapterNumber) =>
// //       _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

// //   static Future<Map<String, dynamic>> createChapter(
// //           String storySlug, Map<String, dynamic> data) =>
// //       _request('POST', '/chapters/$storySlug/chapters/', body: data);

// //   // ── Coins ──────────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getCoinPackages() =>
// //       _request('GET', '/coins/packages/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getSubscriptionPlans() =>
// //       _request('GET', '/coins/plans/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getCoinBalance() =>
// //       _request('GET', '/coins/balance/');

// //   static Future<Map<String, dynamic>> createCheckout(
// //           String purchaseType, {String? packageId, String? planId}) =>
// //       _request('POST', '/coins/checkout/', body: {
// //         'purchase_type': purchaseType,
// //         if (packageId != null) 'package_id': packageId,
// //         if (planId != null) 'plan_id': planId,
// //       });

// //   // ── Comments ───────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getComments(
// //           String storySlug, int chapterNumber) =>
// //       _request('GET', '/comments/$storySlug/chapters/$chapterNumber/comments/',
// //           requiresAuth: false);

// //   static Future<Map<String, dynamic>> postComment(
// //           String storySlug, int chapterNumber, String content,
// //           {int? parentId, int? paragraphIndex}) =>
// //       _request('POST',
// //           '/comments/$storySlug/chapters/$chapterNumber/comments/',
// //           body: {
// //             'content': content,
// //             if (parentId != null) 'parent': parentId,
// //             if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
// //           });

// //   static Future<Map<String, dynamic>> likeComment(int commentId) =>
// //       _request('POST', '/comments/comment/$commentId/like/');

// //   static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
// //       _request('DELETE', '/comments/comment/$commentId/like/');

// //   // ── Tips ───────────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> sendTip(
// //           String storySlug, int coins, {String? message}) =>
// //       _request('POST', '/tips/$storySlug/tip/', body: {
// //         'coins_amount': coins,
// //         if (message != null) 'message': message,
// //       });

// //   static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
// //       _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

// //   // ── Notifications ──────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getNotifications() =>
// //       _request('GET', '/notifications/');

// //   static Future<Map<String, dynamic>> getUnreadCount() =>
// //       _request('GET', '/notifications/unread/');

// //   static Future<Map<String, dynamic>> markAllRead() =>
// //       _request('POST', '/notifications/mark-all-read/');

// //   static Future<Map<String, dynamic>> markRead(int id) =>
// //       _request('POST', '/notifications/$id/read/');
// // //}

// //   static Future<Map<String, dynamic>> requestPayout() =>
// //       _request('POST', '/coins/payout/request/', body: {
// //         'payout_method': 'bank_transfer',
// //       });

// //   static Future<Map<String, dynamic>> getPublicProfile(String username) =>
// //       _request('GET', '/auth/profile/$username/', requiresAuth: false);
// // }

// import 'dart:convert';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:novelux/config/local_storage.dart';

// class ApiService {
//   static const String baseUrl = 'https://novelux.onrender.com/api';
//   //'http://10.0.2.2:8000/api';
//   // Use http://localhost:8000/api for iOS simulator
//   // Use http://YOUR_PC_IP:8000/api for physical device

//   static final DataBase _db = Get.find<DataBase>();

//   // ── Generic request handler ────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> _request(
//     String method,
//     String endpoint, {
//     Map<String, dynamic>? body,
//     bool requiresAuth = true,
//     bool isFormData = false,
//   }) async {
//     final token = await _db.getToken();
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };

//     final uri = Uri.parse('$baseUrl$endpoint');
//     http.Response response;

//     try {
//       switch (method.toUpperCase()) {
//         case 'GET':
//           response = await http.get(uri, headers: headers);
//           break;
//         case 'POST':
//           response = await http.post(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'PATCH':
//           response = await http.patch(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'DELETE':
//           response = await http.delete(uri, headers: headers);
//           break;
//         default:
//           throw Exception('Unsupported HTTP method: $method');
//       }

//       final decoded = jsonDecode(utf8.decode(response.bodyBytes));

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         // myLog.log(decoded);
//         return {
//           'success': true,
//           'data': decoded,
//           'status': response.statusCode,
//         };
//       } else {
//         return {
//           'success': false,
//           'data': decoded,
//           'status': response.statusCode,
//           'error': _extractError(decoded),
//         };
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Network error: $e', 'status': 0};
//     }
//   }

//   void _logResponse(http.Response response) {
//     if (kDebugMode) {
//       print('--- API Response ---');
//       print('Status Code: ${response.statusCode}');
//       print('URL: ${response.request?.url}');
//       try {
//         // Attempt to decode and print if JSON, otherwise print raw body
//         final decodedBody = jsonDecode(response.body);
//         print('Body: ${jsonEncode(decodedBody)}'); // Pretty print JSON
//       } catch (e) {
//         print('Body: ${response.body}'); // Print as is if not JSON
//       }
//       print('--------------------');
//     }
//   }

//   static String _extractError(dynamic decoded) {
//     if (decoded is Map) {
//       if (decoded.containsKey('detail')) {
//         return decoded['detail'].toString();
//       }
//       final firstKey = decoded.keys.first;
//       final firstVal = decoded[firstKey];
//       if (firstVal is List) {
//         return '$firstKey: ${firstVal.first}';
//       }
//       return firstVal.toString();
//     }
//     return decoded.toString();
//   }

// // Helper function for logging
//   void _logRequest(String method, Uri url, {dynamic body}) {
//     if (kDebugMode) {
//       print('--- API Request ---');
//       print('Method: $method');
//       print('URL: $url');
//       if (body != null) {
//         print('Body: ${jsonEncode(body)}');
//       }
//       print('-------------------');
//     }
//   }

//   // ── Auth ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> register({
//     required String username,
//     required String email,
//     required String password1,
//     required String password2,
//     String role = 'reader',
//   }) => _request(
//     'POST',
//     '/auth/dj/registration/',
//     body: {
//       'username': username,
//       'email': email,
//       'password1': password1,
//       'password2': password2,
//       'role': role,
//     },
//     requiresAuth: false,
//   );

//   /// send fcm token to backend
//   Future<http.Response> sendFcmToken(Map<String, dynamic> replyData) async {

//       final token = await _db.getToken();
//       final url = Uri.parse('$baseUrl/auth/save-fcm-token/');
//       _logRequest('POST', url, body: replyData);
//       final response = await http.post(
//         url,
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(replyData),
//       );
//       _logResponse(response);
//       return response;

//   }

//   static Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) => _request(
//     'POST',
//     '/auth/token/',
//     body: {'email': email, 'password': password},
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> refreshToken(String refresh) => _request(
//     'POST',
//     '/auth/token/refresh/',
//     body: {'refresh': refresh},
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getMe() => _request('GET', '/auth/me/');

//   static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
//       _request('PATCH', '/auth/me/', body: data);

//   static Future<Map<String, dynamic>> becomeAuthor() =>
//       _request('POST', '/auth/become-author/');

//   static Future<Map<String, dynamic>> followUser(String username) =>
//       _request('POST', '/auth/follow/$username/');

//   static Future<Map<String, dynamic>> unfollowUser(String username) =>
//       _request('DELETE', '/auth/follow/$username/');

//   // ── Stories ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStories({
//     String? genre,
//     String? tag,
//     String? search,
//     String? language,
//     String? status,
//     int page = 1,
//   }) {
//     var params = '?page=$page';
//     if (genre != null) params += '&genre=$genre';
//     if (tag != null) params += '&tag=$tag';
//     if (search != null) params += '&search=$search';
//     if (language != null) params += '&language=$language';
//     if (status != null) params += '&status=$status';
//     return _request('GET', '/stories/$params', requiresAuth: false);
//   }

//   static Future<Map<String, dynamic>> getCompletedStories() =>
//       _request('GET', '/stories/completed-stories/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getFreeDownLoad() =>
//       _request('GET', '/stories/free-download/', requiresAuth: false);

//    static Future<Map<String, dynamic>> getWorldFamous() =>
//       _request('GET', '/stories/world-Famous/', requiresAuth: false);

//      static Future<Map<String, dynamic>> getAfricanFolkTale() =>
//       _request('GET', '/stories/african-folktale/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTrending() =>
//       _request('GET', '/stories/trending/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getFeatured() =>
//       _request('GET', '/stories/featured/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getEditorsPick() =>
//       _request('GET', '/stories/editors-pick/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
//       _request('GET', '/stories/$slug/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getGenres() =>
//       _request('GET', '/stories/genres/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTags() =>
//       _request('GET', '/stories/tags/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getMyBookmarks() =>
//       _request('GET', '/stories/bookmarks/');

//   static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
//       _request('POST', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> removeBookmark(String slug) =>
//       _request('DELETE', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> rateStory(
//     String slug,
//     int score,
//     String review,
//   ) => _request(
//     'POST',
//     '/stories/$slug/rate/',
//     body: {'score': score, 'review': review},
//   );

//   static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
//       _request('POST', '/stories/', body: data);

//   static Future<Map<String, dynamic>> updateStory(
//     String slug,
//     Map<String, dynamic> data,
//   ) => _request('PATCH', '/stories/$slug/', body: data);

//   static Future<Map<String, dynamic>> getMyStories() =>
//       _request('GET', '/stories/mine/');

//   // ── Chapters ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getChapters(String storySlug) =>
//       _request('GET', '/chapters/$storySlug/chapters/', requiresAuth: true);

//   static Future<Map<String, dynamic>> getChapter(
//     String storySlug,
//     int chapterNumber,
//   ) => _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

//   static Future<Map<String, dynamic>> unlockChapter(
//     String storySlug,
//     int chapterNumber,
//   ) => _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

//   static Future<Map<String, dynamic>> createChapter(
//     String storySlug,
//     Map<String, dynamic> data,
//   ) => _request('POST', '/chapters/$storySlug/chapters/', body: data);

//   // ── Coins ──────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getCoinPackages() =>
//       _request('GET', '/coins/packages/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getSubscriptionPlans() =>
//       _request('GET', '/coins/plans/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getCoinBalance() =>
//       _request('GET', '/coins/balance/');

//   static Future<Map<String, dynamic>> createCheckout(
//     String purchaseType, {
//     String? packageId,
//     String? planId,
//   }) => _request(
//     'POST',
//     '/coins/checkout/',
//     body: {
//       'purchase_type': purchaseType,
//       if (packageId != null) 'package_id': packageId,
//       if (planId != null) 'plan_id': planId,
//     },
//   );

//   // ── Comments ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getComments(
//     String storySlug,
//     int chapterNumber,
//   ) => _request(
//     'GET',
//     '/comments/$storySlug/chapters/$chapterNumber/comments/',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> postComment(
//     String storySlug,
//     int chapterNumber,
//     String content, {
//     int? parentId,
//     int? paragraphIndex,
//   }) => _request(
//     'POST',
//     '/comments/$storySlug/chapters/$chapterNumber/comments/',
//     body: {
//       'content': content,
//       if (parentId != null) 'parent': parentId,
//       if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
//     },
//   );

//   static Future<Map<String, dynamic>> likeComment(int commentId) =>
//       _request('POST', '/comments/comment/$commentId/like/');

//   static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
//       _request('DELETE', '/comments/comment/$commentId/like/');

//   // ── Tips ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> sendTip(
//     String storySlug,
//     int coins, {
//     String? message,
//   }) => _request(
//     'POST',
//     '/tips/$storySlug/tip/',
//     body: {
//       'coins_amount':
//           coins.toInt(), // explicit int — prevents string serialisation
//       if (message != null && message.isNotEmpty) 'message': message,
//     },
//   );

//   static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
//       _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

//   // ── Notifications ──────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getNotifications() =>
//       _request('GET', '/notifications/');

//   static Future<Map<String, dynamic>> getUnreadCount() =>
//       _request('GET', '/notifications/unread/');

//   static Future<Map<String, dynamic>> markAllRead() =>
//       _request('POST', '/notifications/mark-all-read/');

//   static Future<Map<String, dynamic>> markRead(int id) =>
//       _request('POST', '/notifications/$id/read/');
//   //}

//   static Future<Map<String, dynamic>> requestPayout() => _request(
//     'POST',
//     '/coins/payout/request/',
//     body: {'payout_method': 'bank_transfer'},
//   );

//   static Future<Map<String, dynamic>> getPublicProfile(String username) =>
//       _request('GET', '/auth/profile/$username/', requiresAuth: false);

//   // ── Reviews ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStoryReviews(
//     String slug, {
//     String type = 'all',
//   }) {
//     final query = type == 'all' ? '' : '?rating=$type';
//     return _request(
//       'GET',
//       '/stories/reviews/$slug/reviews/$query',
//       requiresAuth: false,
//     );
//   }

//   static Future<Map<String, dynamic>> submitReview(
//     String slug, {
//     required String rating,
//     String content = '',
//   }) => _request(
//     'POST',
//     '/stories/reviews/$slug/reviews/',
//     body: {'rating': rating, 'content': content},
//   );
//  // myLog.log(content);
//   // ── Rewards ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> claimDailyReward(int coins) =>
//       _request('POST', '/coins/claim-reward/', body: {'coins': coins});

//   // ── VIP / Subscription ─────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getVipStatus() =>
//       _request('GET', '/coins/vip-status/');

//   static Future<Map<String, dynamic>> cancelSubscription() =>
//       _request('POST', '/coins/subscription/cancel/');

// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:novelux/config/local_storage.dart';
import 'dart:developer' as myLog;

// class ApiService {
//   static const String baseUrl = 'https://novelux.onrender.com/api';
//   //'http://127.0.0.1:8000/api';

//   //'http://10.0.2.2:8000/api';
//   // Use http://localhost:8000/api for iOS simulator
//   // Use http://192.168.222.146:8000/api for physical device

//   static final DataBase _db = Get.find<DataBase>();

//   // ── Generic request handler ────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> _request(
//     String method,
//     String endpoint, {
//     Map<String, dynamic>? body,
//     bool requiresAuth = true,
//     bool isFormData = false,
//   }) async {
//     final token = await _db.getToken();
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };

//     final uri = Uri.parse('$baseUrl$endpoint');
//     http.Response response;

//     try {
//       switch (method.toUpperCase()) {
//         case 'GET':
//           response = await http.get(uri, headers: headers);
//           break;
//         case 'POST':
//           response = await http.post(uri,
//               headers: headers, body: body != null ? jsonEncode(body) : null);
//           break;
//         case 'PATCH':
//           response = await http.patch(uri,
//               headers: headers, body: body != null ? jsonEncode(body) : null);
//           break;
//         case 'DELETE':
//           response = await http.delete(uri, headers: headers);
//           break;
//         default:
//           throw Exception('Unsupported HTTP method: $method');
//       }

//       final decoded = jsonDecode(utf8.decode(response.bodyBytes));

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         return {'success': true, 'data': decoded, 'status': response.statusCode};
//       } else {
//         return {
//           'success': false,
//           'data': decoded,
//           'status': response.statusCode,
//           'error': _extractError(decoded),
//         };
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Network error: $e', 'status': 0};
//     }
//   }

//   static String _extractError(dynamic decoded) {
//     if (decoded is Map) {
//       if (decoded.containsKey('detail')) {
//         return decoded['detail'].toString();
//       }
//       final firstKey = decoded.keys.first;
//       final firstVal = decoded[firstKey];
//       if (firstVal is List) {
//         return '$firstKey: ${firstVal.first}';
//       }
//       return firstVal.toString();
//     }
//     return decoded.toString();
//   }

//   // ── Auth ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> register({
//     required String username,
//     required String email,
//     required String password1,
//     required String password2,
//     String role = 'reader',
//   }) =>
//       _request('POST', '/auth/dj/registration/', body: {
//         'username': username,
//         'email': email,
//         'password1': password1,
//         'password2': password2,
//         'role': role,
//       }, requiresAuth: false);

//   static Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) =>
//       _request('POST', '/auth/token/', body: {
//         'email': email,
//         'password': password,
//       }, requiresAuth: false);

//   static Future<Map<String, dynamic>> refreshToken(String refresh) =>
//       _request('POST', '/auth/token/refresh/', body: {'refresh': refresh},
//           requiresAuth: false);

//   static Future<Map<String, dynamic>> getMe() =>
//       _request('GET', '/auth/me/');

//   static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
//       _request('PATCH', '/auth/me/', body: data);

//   static Future<Map<String, dynamic>> becomeAuthor() =>
//       _request('POST', '/auth/become-author/');

//   static Future<Map<String, dynamic>> followUser(String username) =>
//       _request('POST', '/auth/follow/$username/');

//   static Future<Map<String, dynamic>> unfollowUser(String username) =>
//       _request('DELETE', '/auth/follow/$username/');

//   // ── Stories ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStories({
//     String? genre,
//     String? tag,
//     String? search,
//     String? language,
//     String? status,
//     int page = 1,
//   }) {
//     var params = '?page=$page';
//     if (genre != null) params += '&genre=$genre';
//     if (tag != null) params += '&tag=$tag';
//     if (search != null) params += '&search=$search';
//     if (language != null) params += '&language=$language';
//     if (status != null) params += '&status=$status';
//     return _request('GET', '/stories/$params', requiresAuth: false);
//   }

//   static Future<Map<String, dynamic>> getTrending() =>
//       _request('GET', '/stories/trending/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getFeatured() =>
//       _request('GET', '/stories/featured/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getEditorsPick() =>
//       _request('GET', '/stories/editors-pick/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
//       _request('GET', '/stories/$slug/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getGenres() =>
//       _request('GET', '/stories/genres/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTags() =>
//       _request('GET', '/stories/tags/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getMyBookmarks() =>
//       _request('GET', '/stories/bookmarks/');

//   static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
//       _request('POST', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> removeBookmark(String slug) =>
//       _request('DELETE', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> rateStory(
//           String slug, int score, String review) =>
//       _request('POST', '/stories/$slug/rate/', body: {'score': score, 'review': review});

//   static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
//       _request('POST', '/stories/', body: data);

//   static Future<Map<String, dynamic>> updateStory(
//           String slug, Map<String, dynamic> data) =>
//       _request('PATCH', '/stories/$slug/', body: data);

//   static Future<Map<String, dynamic>> getMyStories() =>
//       _request('GET', '/stories/mine/');

//   // ── Chapters ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getChapters(String storySlug) =>
//       _request('GET', '/chapters/$storySlug/chapters/', requiresAuth: true);

//   static Future<Map<String, dynamic>> getChapter(
//           String storySlug, int chapterNumber) =>
//       _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

//   static Future<Map<String, dynamic>> unlockChapter(
//           String storySlug, int chapterNumber) =>
//       _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

//   static Future<Map<String, dynamic>> createChapter(
//           String storySlug, Map<String, dynamic> data) =>
//       _request('POST', '/chapters/$storySlug/chapters/', body: data);

//   // ── Coins ──────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getCoinPackages() =>
//       _request('GET', '/coins/packages/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getSubscriptionPlans() =>
//       _request('GET', '/coins/plans/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getCoinBalance() =>
//       _request('GET', '/coins/balance/');

//   static Future<Map<String, dynamic>> createCheckout(
//           String purchaseType, {String? packageId, String? planId}) =>
//       _request('POST', '/coins/checkout/', body: {
//         'purchase_type': purchaseType,
//         if (packageId != null) 'package_id': packageId,
//         if (planId != null) 'plan_id': planId,
//       });

//   // ── Comments ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getComments(
//           String storySlug, int chapterNumber) =>
//       _request('GET', '/comments/$storySlug/chapters/$chapterNumber/comments/',
//           requiresAuth: false);

//   static Future<Map<String, dynamic>> postComment(
//           String storySlug, int chapterNumber, String content,
//           {int? parentId, int? paragraphIndex}) =>
//       _request('POST',
//           '/comments/$storySlug/chapters/$chapterNumber/comments/',
//           body: {
//             'content': content,
//             if (parentId != null) 'parent': parentId,
//             if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
//           });

//   static Future<Map<String, dynamic>> likeComment(int commentId) =>
//       _request('POST', '/comments/comment/$commentId/like/');

//   static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
//       _request('DELETE', '/comments/comment/$commentId/like/');

//   // ── Tips ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> sendTip(
//           String storySlug, int coins, {String? message}) =>
//       _request('POST', '/tips/$storySlug/tip/', body: {
//         'coins_amount': coins,
//         if (message != null) 'message': message,
//       });

//   static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
//       _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

//   // ── Notifications ──────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getNotifications() =>
//       _request('GET', '/notifications/');

//   static Future<Map<String, dynamic>> getUnreadCount() =>
//       _request('GET', '/notifications/unread/');

//   static Future<Map<String, dynamic>> markAllRead() =>
//       _request('POST', '/notifications/mark-all-read/');

//   static Future<Map<String, dynamic>> markRead(int id) =>
//       _request('POST', '/notifications/$id/read/');
// //}

//   static Future<Map<String, dynamic>> requestPayout() =>
//       _request('POST', '/coins/payout/request/', body: {
//         'payout_method': 'bank_transfer',
//       });

//   static Future<Map<String, dynamic>> getPublicProfile(String username) =>
//       _request('GET', '/auth/profile/$username/', requiresAuth: false);
// }

// import 'dart:convert';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:novelux/config/local_storage.dart';

// class ApiService {
//   static const String baseUrl = 'https://novelux.onrender.com/api';
//   //'http://10.0.2.2:8000/api';
//   // Use http://localhost:8000/api for iOS simulator
//   // Use http://YOUR_PC_IP:8000/api for physical device

//   static final DataBase _db = Get.find<DataBase>();

//   // ── Generic request handler ────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> _request(
//     String method,
//     String endpoint, {
//     Map<String, dynamic>? body,
//     bool requiresAuth = true,
//     bool isFormData = false,
//   }) async {
//     final token = await _db.getToken();
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };

//     final uri = Uri.parse('$baseUrl$endpoint');
//     http.Response response;

//     try {
//       switch (method.toUpperCase()) {
//         case 'GET':
//           response = await http.get(uri, headers: headers);
//           break;
//         case 'POST':
//           response = await http.post(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'PATCH':
//           response = await http.patch(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'DELETE':
//           response = await http.delete(uri, headers: headers);
//           break;
//         default:
//           throw Exception('Unsupported HTTP method: $method');
//       }

//       final decoded = jsonDecode(utf8.decode(response.bodyBytes));

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         // myLog.log(decoded);
//         return {
//           'success': true,
//           'data': decoded,
//           'status': response.statusCode,
//         };
//       } else {
//         return {
//           'success': false,
//           'data': decoded,
//           'status': response.statusCode,
//           'error': _extractError(decoded),
//         };
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Network error: $e', 'status': 0};
//     }
//   }

//   void _logResponse(http.Response response) {
//     if (kDebugMode) {
//       print('--- API Response ---');
//       print('Status Code: ${response.statusCode}');
//       print('URL: ${response.request?.url}');
//       try {
//         // Attempt to decode and print if JSON, otherwise print raw body
//         final decodedBody = jsonDecode(response.body);
//         print('Body: ${jsonEncode(decodedBody)}'); // Pretty print JSON
//       } catch (e) {
//         print('Body: ${response.body}'); // Print as is if not JSON
//       }
//       print('--------------------');
//     }
//   }

//   static String _extractError(dynamic decoded) {
//     if (decoded is Map) {
//       if (decoded.containsKey('detail')) {
//         return decoded['detail'].toString();
//       }
//       final firstKey = decoded.keys.first;
//       final firstVal = decoded[firstKey];
//       if (firstVal is List) {
//         return '$firstKey: ${firstVal.first}';
//       }
//       return firstVal.toString();
//     }
//     return decoded.toString();
//   }

//   // Helper function for logging
//   void _logRequest(String method, Uri url, {dynamic body}) {
//     if (kDebugMode) {
//       print('--- API Request ---');
//       print('Method: $method');
//       print('URL: $url');
//       if (body != null) {
//         print('Body: ${jsonEncode(body)}');
//       }
//       print('-------------------');
//     }
//   }

//   // ── Auth ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> register({
//     required String username,
//     required String email,
//     required String password1,
//     required String password2,
//     String role = 'reader',
//   }) => _request(
//     'POST',
//     '/auth/dj/registration/',
//     body: {
//       'username': username,
//       'email': email,
//       'password1': password1,
//       'password2': password2,
//       'role': role,
//     },
//     requiresAuth: false,
//   );

//   /// send fcm token to backend
//   Future<http.Response> sendFcmToken(Map<String, dynamic> replyData) async {
//     final token = await _db.getToken();
//     final url = Uri.parse('$baseUrl/auth/save-fcm-token/');
//     _logRequest('POST', url, body: replyData);
//     final response = await http.post(
//       url,
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Accept': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode(replyData),
//     );
//     _logResponse(response);
//     return response;
//   }

//   static Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) => _request(
//     'POST',
//     '/auth/token/',
//     body: {'email': email, 'password': password},
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> refreshToken(String refresh) => _request(
//     'POST',
//     '/auth/token/refresh/',
//     body: {'refresh': refresh},
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getMe() => _request('GET', '/auth/me/');

//   static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
//       _request('PATCH', '/auth/me/', body: data);

//   static Future<Map<String, dynamic>> becomeAuthor() =>
//       _request('POST', '/auth/become-author/');

//   static Future<Map<String, dynamic>> followUser(String username) =>
//       _request('POST', '/auth/follow/$username/');

//   static Future<Map<String, dynamic>> unfollowUser(String username) =>
//       _request('DELETE', '/auth/follow/$username/');

//   // ── Stories ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStories({
//     String? genre,
//     String? tag,
//     String? search,
//     String? language,
//     String? status,
//     String? targetGender, // 'male' | 'female' | 'prefer_not_to_say'
//     int page = 1,
//   }) {
//     var params = '?page=$page';
//     if (genre != null) params += '&genre=$genre';
//     if (tag != null) params += '&tag=$tag';
//     if (search != null) params += '&search=$search';
//     if (language != null) params += '&language=$language';
//     if (status != null) params += '&status=$status';
//     if (targetGender != null && targetGender.isNotEmpty)
//       params += '&target_gender=$targetGender';
//     return _request('GET', '/stories/$params', requiresAuth: false);
//   }

//   /// Personalised feed — sends preferred genres + gender to backend
//   static Future<Map<String, dynamic>> getPersonalisedFeed({
//     required List<String> genres,
//     String gender = '',
//     String? tab, // specific genre slug to filter by
//     int page = 1,
//   }) {
//     var params = '?page=$page';
//     if (genres.isNotEmpty) params += '&genres=${genres.join(',')}';
//     if (gender.isNotEmpty) params += '&gender=$gender';
//     if (tab != null && tab != 'All') params += '&genre=$tab';
//     return _request('GET', '/stories/personalised/$params');
//   }

//   static Future<Map<String, dynamic>> getCompletedStories() =>
//       _request('GET', '/stories/completed-stories/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getFreeDownLoad() =>
//       _request('GET', '/stories/free-download/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getWorldFamous() =>
//       _request('GET', '/stories/world-Famous/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getAfricanFolkTale() =>
//       _request('GET', '/stories/african-folktale/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTrending() =>
//       _request('GET', '/stories/trending/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getFeatured() =>
//       _request('GET', '/stories/featured/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getEditorsPick() =>
//       _request('GET', '/stories/editors-pick/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
//       _request('GET', '/stories/$slug/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getGenres() =>
//       _request('GET', '/stories/genres/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTags() =>
//       _request('GET', '/stories/tags/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getMyBookmarks() =>
//       _request('GET', '/stories/bookmarks/');

//   static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
//       _request('POST', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> removeBookmark(String slug) =>
//       _request('DELETE', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> rateStory(
//     String slug,
//     int score,
//     String review,
//   ) => _request(
//     'POST',
//     '/stories/$slug/rate/',
//     body: {'score': score, 'review': review},
//   );

//   static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
//       _request('POST', '/stories/', body: data);

//   static Future<Map<String, dynamic>> updateStory(
//     String slug,
//     Map<String, dynamic> data,
//   ) => _request('PATCH', '/stories/$slug/', body: data);

//   static Future<Map<String, dynamic>> getMyStories() =>
//       _request('GET', '/stories/mine/');

//   // ── Chapters ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getChapters(String storySlug) =>
//       _request('GET', '/chapters/$storySlug/chapters/', requiresAuth: true);

//   static Future<Map<String, dynamic>> getChapter(
//     String storySlug,
//     int chapterNumber,
//   ) => _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

//   static Future<Map<String, dynamic>> unlockChapter(
//     String storySlug,
//     int chapterNumber,
//   ) => _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

//   static Future<Map<String, dynamic>> createChapter(
//     String storySlug,
//     Map<String, dynamic> data,
//   ) => _request('POST', '/chapters/$storySlug/chapters/', body: data);

//   // ── Coins ──────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getCoinPackages() =>
//       _request('GET', '/coins/packages/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getSubscriptionPlans() =>
//       _request('GET', '/coins/plans/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getCoinBalance() =>
//       _request('GET', '/coins/balance/');

//   static Future<Map<String, dynamic>> createCheckout(
//     String purchaseType, {
//     String? packageId,
//     String? planId,
//   }) => _request(
//     'POST',
//     '/coins/checkout/',
//     body: {
//       'purchase_type': purchaseType,
//       if (packageId != null) 'package_id': packageId,
//       if (planId != null) 'plan_id': planId,
//     },
//   );

//   // ── Comments ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getComments(
//     String storySlug,
//     int chapterNumber,
//   ) => _request(
//     'GET',
//     '/comments/$storySlug/chapters/$chapterNumber/comments/',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> postComment(
//     String storySlug,
//     int chapterNumber,
//     String content, {
//     int? parentId,
//     int? paragraphIndex,
//   }) => _request(
//     'POST',
//     '/comments/$storySlug/chapters/$chapterNumber/comments/',
//     body: {
//       'content': content,
//       if (parentId != null) 'parent': parentId,
//       if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
//     },
//   );

//   static Future<Map<String, dynamic>> likeComment(int commentId) =>
//       _request('POST', '/comments/comment/$commentId/like/');

//   static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
//       _request('DELETE', '/comments/comment/$commentId/like/');

//   // ── Tips ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> sendTip(
//     String storySlug,
//     int coins, {
//     String? message,
//   }) => _request(
//     'POST',
//     '/tips/$storySlug/tip/',
//     body: {
//       'coins_amount':
//           coins.toInt(), // explicit int — prevents string serialisation
//       if (message != null && message.isNotEmpty) 'message': message,
//     },
//   );

//   static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
//       _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

//   // ── Notifications ──────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getNotifications() =>
//       _request('GET', '/notifications/');

//   static Future<Map<String, dynamic>> getUnreadCount() =>
//       _request('GET', '/notifications/unread/');

//   static Future<Map<String, dynamic>> markAllRead() =>
//       _request('POST', '/notifications/mark-all-read/');

//   static Future<Map<String, dynamic>> markRead(int id) =>
//       _request('POST', '/notifications/$id/read/');
//   //}

//   static Future<Map<String, dynamic>> requestPayout() => _request(
//     'POST',
//     '/coins/payout/request/',
//     body: {'payout_method': 'bank_transfer'},
//   );

//   static Future<Map<String, dynamic>> getPublicProfile(String username) =>
//       _request('GET', '/auth/profile/$username/', requiresAuth: false);

//   // ── Reviews ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStoryReviews(
//     String slug, {
//     String type = 'all',
//   }) {
//     final query = type == 'all' ? '' : '?rating=$type';
//     return _request(
//       'GET',
//       '/stories/reviews/$slug/reviews/$query',
//       requiresAuth: false,
//     );
//   }

//   static Future<Map<String, dynamic>> submitReview(
//     String slug, {
//     required String rating,
//     String content = '',
//   }) => _request(
//     'POST',
//     '/stories/reviews/$slug/reviews/',
//     body: {'rating': rating, 'content': content},
//   );
//   // myLog.log(content);
//   // ── Rewards ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> claimDailyReward(int coins) =>
//       _request('POST', '/coins/claim-reward/', body: {'coins': coins});

//   // ── VIP / Subscription ─────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getVipStatus() =>
//       _request('GET', '/coins/vip-status/');

//   static Future<Map<String, dynamic>> cancelSubscription() =>
//       _request('POST', '/coins/subscription/cancel/');

//   // ── Reading Schedule & Sessions ────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getReadingSchedule() =>
//       _request('GET', '/reading/schedule/');

//   static Future<Map<String, dynamic>> saveReadingSchedule(
//     Map<String, dynamic> data,
//   ) => _request('POST', '/reading/schedule/', body: data);

//   static Future<Map<String, dynamic>> logReadingSession({
//     required String storySlug,
//     required int chapter,
//     required int minutes,
//   }) => _request(
//     'POST',
//     '/reading/session/',
//     body: {'story_slug': storySlug, 'chapter': chapter, 'minutes': minutes},
//   );

//   static Future<Map<String, dynamic>> getReadingStats({int goal = 30}) =>
//       _request('GET', '/reading/stats/?goal=$goal');

//   // ── User Preferences ───────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> saveUserPreferences({
//     required List<String> genres,
//     String gender = '',
//   }) => _request(
//     'POST',
//     '/auth/preferences/',
//     body: {'preferred_genres': genres, if (gender.isNotEmpty) 'gender': gender},
//   );

//   static Future<Map<String, dynamic>> getUserPreferences() =>
//       _request('GET', '/auth/preferences/');

//   // ── Promo banners ───────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getPromoBanners() =>
//       _request('GET', '/stories/banners/', requiresAuth: false);

//   // ── Reading History ───────────────────────────────────────────────────────
//   /// GET /api/reading/history/ — server-side reading history (paginated)
//   static Future<Map<String, dynamic>> getReadingHistory({int page = 1}) =>
//       _request('GET', '/reading/history/?page=$page');

//   /// POST /api/reading/history/  — log that user opened a chapter
//   static Future<Map<String, dynamic>> logReadingHistory({
//     required String storySlug,
//     required int chapterNumber,
//     required String chapterTitle,
//   }) => _request(
//     'POST',
//     '/reading/history/',
//     // '/history/',
//     body: {
//       'story': storySlug,
//       'chapter_number': chapterNumber,
//       'chapter_title': chapterTitle,

//     },
//     requiresAuth: true
//   );

//   /// DELETE /api/reading/history/<id>/  — remove single history entry
//   static Future<Map<String, dynamic>> deleteReadingHistory(int id) =>
//       _request('DELETE', '/reading/history/$id/');

//   /// DELETE /api/reading/history/  — clear all history
//   static Future<Map<String, dynamic>> clearReadingHistory() =>
//       _request('DELETE', '/reading/history/');
// }

// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:novelux/config/local_storage.dart';
// import 'dart:developer' as myLog;

// // class ApiService {
// //   static const String baseUrl = 'https://novelux.onrender.com/api';
// //   //'http://127.0.0.1:8000/api';

// //   //'http://10.0.2.2:8000/api';
// //   // Use http://localhost:8000/api for iOS simulator
// //   // Use http://192.168.222.146:8000/api for physical device

// //   static final DataBase _db = Get.find<DataBase>();

// //   // ── Generic request handler ────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> _request(
// //     String method,
// //     String endpoint, {
// //     Map<String, dynamic>? body,
// //     bool requiresAuth = true,
// //     bool isFormData = false,
// //   }) async {
// //     final token = await _db.getToken();
// //     final headers = <String, String>{
// //       'Content-Type': 'application/json',
// //       'Accept': 'application/json',
// //       if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
// //     };

// //     final uri = Uri.parse('$baseUrl$endpoint');
// //     http.Response response;

// //     try {
// //       switch (method.toUpperCase()) {
// //         case 'GET':
// //           response = await http.get(uri, headers: headers);
// //           break;
// //         case 'POST':
// //           response = await http.post(uri,
// //               headers: headers, body: body != null ? jsonEncode(body) : null);
// //           break;
// //         case 'PATCH':
// //           response = await http.patch(uri,
// //               headers: headers, body: body != null ? jsonEncode(body) : null);
// //           break;
// //         case 'DELETE':
// //           response = await http.delete(uri, headers: headers);
// //           break;
// //         default:
// //           throw Exception('Unsupported HTTP method: $method');
// //       }

// //       final decoded = jsonDecode(utf8.decode(response.bodyBytes));

// //       if (response.statusCode >= 200 && response.statusCode < 300) {
// //         return {'success': true, 'data': decoded, 'status': response.statusCode};
// //       } else {
// //         return {
// //           'success': false,
// //           'data': decoded,
// //           'status': response.statusCode,
// //           'error': _extractError(decoded),
// //         };
// //       }
// //     } catch (e) {
// //       return {'success': false, 'error': 'Network error: $e', 'status': 0};
// //     }
// //   }

// //   static String _extractError(dynamic decoded) {
// //     if (decoded is Map) {
// //       if (decoded.containsKey('detail')) {
// //         return decoded['detail'].toString();
// //       }
// //       final firstKey = decoded.keys.first;
// //       final firstVal = decoded[firstKey];
// //       if (firstVal is List) {
// //         return '$firstKey: ${firstVal.first}';
// //       }
// //       return firstVal.toString();
// //     }
// //     return decoded.toString();
// //   }

// //   // ── Auth ───────────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> register({
// //     required String username,
// //     required String email,
// //     required String password1,
// //     required String password2,
// //     String role = 'reader',
// //   }) =>
// //       _request('POST', '/auth/dj/registration/', body: {
// //         'username': username,
// //         'email': email,
// //         'password1': password1,
// //         'password2': password2,
// //         'role': role,
// //       }, requiresAuth: false);

// //   static Future<Map<String, dynamic>> login({
// //     required String email,
// //     required String password,
// //   }) =>
// //       _request('POST', '/auth/token/', body: {
// //         'email': email,
// //         'password': password,
// //       }, requiresAuth: false);

// //   static Future<Map<String, dynamic>> refreshToken(String refresh) =>
// //       _request('POST', '/auth/token/refresh/', body: {'refresh': refresh},
// //           requiresAuth: false);

// //   static Future<Map<String, dynamic>> getMe() =>
// //       _request('GET', '/auth/me/');

// //   static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
// //       _request('PATCH', '/auth/me/', body: data);

// //   static Future<Map<String, dynamic>> becomeAuthor() =>
// //       _request('POST', '/auth/become-author/');

// //   static Future<Map<String, dynamic>> followUser(String username) =>
// //       _request('POST', '/auth/follow/$username/');

// //   static Future<Map<String, dynamic>> unfollowUser(String username) =>
// //       _request('DELETE', '/auth/follow/$username/');

// //   // ── Stories ────────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getStories({
// //     String? genre,
// //     String? tag,
// //     String? search,
// //     String? language,
// //     String? status,
// //     int page = 1,
// //   }) {
// //     var params = '?page=$page';
// //     if (genre != null) params += '&genre=$genre';
// //     if (tag != null) params += '&tag=$tag';
// //     if (search != null) params += '&search=$search';
// //     if (language != null) params += '&language=$language';
// //     if (status != null) params += '&status=$status';
// //     return _request('GET', '/stories/$params', requiresAuth: false);
// //   }

// //   static Future<Map<String, dynamic>> getTrending() =>
// //       _request('GET', '/stories/trending/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getFeatured() =>
// //       _request('GET', '/stories/featured/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getEditorsPick() =>
// //       _request('GET', '/stories/editors-pick/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
// //       _request('GET', '/stories/$slug/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getGenres() =>
// //       _request('GET', '/stories/genres/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getTags() =>
// //       _request('GET', '/stories/tags/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getMyBookmarks() =>
// //       _request('GET', '/stories/bookmarks/');

// //   static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
// //       _request('POST', '/stories/$slug/bookmark/');

// //   static Future<Map<String, dynamic>> removeBookmark(String slug) =>
// //       _request('DELETE', '/stories/$slug/bookmark/');

// //   static Future<Map<String, dynamic>> rateStory(
// //           String slug, int score, String review) =>
// //       _request('POST', '/stories/$slug/rate/', body: {'score': score, 'review': review});

// //   static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
// //       _request('POST', '/stories/', body: data);

// //   static Future<Map<String, dynamic>> updateStory(
// //           String slug, Map<String, dynamic> data) =>
// //       _request('PATCH', '/stories/$slug/', body: data);

// //   static Future<Map<String, dynamic>> getMyStories() =>
// //       _request('GET', '/stories/mine/');

// //   // ── Chapters ───────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getChapters(String storySlug) =>
// //       _request('GET', '/chapters/$storySlug/chapters/', requiresAuth: true);

// //   static Future<Map<String, dynamic>> getChapter(
// //           String storySlug, int chapterNumber) =>
// //       _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

// //   static Future<Map<String, dynamic>> unlockChapter(
// //           String storySlug, int chapterNumber) =>
// //       _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

// //   static Future<Map<String, dynamic>> createChapter(
// //           String storySlug, Map<String, dynamic> data) =>
// //       _request('POST', '/chapters/$storySlug/chapters/', body: data);

// //   // ── Coins ──────────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getCoinPackages() =>
// //       _request('GET', '/coins/packages/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getSubscriptionPlans() =>
// //       _request('GET', '/coins/plans/', requiresAuth: false);

// //   static Future<Map<String, dynamic>> getCoinBalance() =>
// //       _request('GET', '/coins/balance/');

// //   static Future<Map<String, dynamic>> createCheckout(
// //           String purchaseType, {String? packageId, String? planId}) =>
// //       _request('POST', '/coins/checkout/', body: {
// //         'purchase_type': purchaseType,
// //         if (packageId != null) 'package_id': packageId,
// //         if (planId != null) 'plan_id': planId,
// //       });

// //   // ── Comments ───────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getComments(
// //           String storySlug, int chapterNumber) =>
// //       _request('GET', '/comments/$storySlug/chapters/$chapterNumber/comments/',
// //           requiresAuth: false);

// //   static Future<Map<String, dynamic>> postComment(
// //           String storySlug, int chapterNumber, String content,
// //           {int? parentId, int? paragraphIndex}) =>
// //       _request('POST',
// //           '/comments/$storySlug/chapters/$chapterNumber/comments/',
// //           body: {
// //             'content': content,
// //             if (parentId != null) 'parent': parentId,
// //             if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
// //           });

// //   static Future<Map<String, dynamic>> likeComment(int commentId) =>
// //       _request('POST', '/comments/comment/$commentId/like/');

// //   static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
// //       _request('DELETE', '/comments/comment/$commentId/like/');

// //   // ── Tips ───────────────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> sendTip(
// //           String storySlug, int coins, {String? message}) =>
// //       _request('POST', '/tips/$storySlug/tip/', body: {
// //         'coins_amount': coins,
// //         if (message != null) 'message': message,
// //       });

// //   static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
// //       _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

// //   // ── Notifications ──────────────────────────────────────────────────────────
// //   static Future<Map<String, dynamic>> getNotifications() =>
// //       _request('GET', '/notifications/');

// //   static Future<Map<String, dynamic>> getUnreadCount() =>
// //       _request('GET', '/notifications/unread/');

// //   static Future<Map<String, dynamic>> markAllRead() =>
// //       _request('POST', '/notifications/mark-all-read/');

// //   static Future<Map<String, dynamic>> markRead(int id) =>
// //       _request('POST', '/notifications/$id/read/');
// // //}

// //   static Future<Map<String, dynamic>> requestPayout() =>
// //       _request('POST', '/coins/payout/request/', body: {
// //         'payout_method': 'bank_transfer',
// //       });

// //   static Future<Map<String, dynamic>> getPublicProfile(String username) =>
// //       _request('GET', '/auth/profile/$username/', requiresAuth: false);
// // }

// import 'dart:convert';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:novelux/config/local_storage.dart';

// class ApiService {
//   static const String baseUrl = 'https://novelux.onrender.com/api';
//   //'http://10.0.2.2:8000/api';
//   // Use http://localhost:8000/api for iOS simulator
//   // Use http://YOUR_PC_IP:8000/api for physical device

//   static final DataBase _db = Get.find<DataBase>();

//   // ── Generic request handler ────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> _request(
//     String method,
//     String endpoint, {
//     Map<String, dynamic>? body,
//     bool requiresAuth = true,
//     bool isFormData = false,
//   }) async {
//     final token = await _db.getToken();
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };

//     final uri = Uri.parse('$baseUrl$endpoint');
//     http.Response response;

//     try {
//       switch (method.toUpperCase()) {
//         case 'GET':
//           response = await http.get(uri, headers: headers);
//           break;
//         case 'POST':
//           response = await http.post(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'PATCH':
//           response = await http.patch(
//             uri,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'DELETE':
//           response = await http.delete(uri, headers: headers);
//           break;
//         default:
//           throw Exception('Unsupported HTTP method: $method');
//       }

//       final decoded = jsonDecode(utf8.decode(response.bodyBytes));

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         // myLog.log(decoded);
//         return {
//           'success': true,
//           'data': decoded,
//           'status': response.statusCode,
//         };
//       } else {
//         return {
//           'success': false,
//           'data': decoded,
//           'status': response.statusCode,
//           'error': _extractError(decoded),
//         };
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Network error: $e', 'status': 0};
//     }
//   }

//   void _logResponse(http.Response response) {
//     if (kDebugMode) {
//       print('--- API Response ---');
//       print('Status Code: ${response.statusCode}');
//       print('URL: ${response.request?.url}');
//       try {
//         // Attempt to decode and print if JSON, otherwise print raw body
//         final decodedBody = jsonDecode(response.body);
//         print('Body: ${jsonEncode(decodedBody)}'); // Pretty print JSON
//       } catch (e) {
//         print('Body: ${response.body}'); // Print as is if not JSON
//       }
//       print('--------------------');
//     }
//   }

//   static String _extractError(dynamic decoded) {
//     if (decoded is Map) {
//       if (decoded.containsKey('detail')) {
//         return decoded['detail'].toString();
//       }
//       final firstKey = decoded.keys.first;
//       final firstVal = decoded[firstKey];
//       if (firstVal is List) {
//         return '$firstKey: ${firstVal.first}';
//       }
//       return firstVal.toString();
//     }
//     return decoded.toString();
//   }

// // Helper function for logging
//   void _logRequest(String method, Uri url, {dynamic body}) {
//     if (kDebugMode) {
//       print('--- API Request ---');
//       print('Method: $method');
//       print('URL: $url');
//       if (body != null) {
//         print('Body: ${jsonEncode(body)}');
//       }
//       print('-------------------');
//     }
//   }

//   // ── Auth ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> register({
//     required String username,
//     required String email,
//     required String password1,
//     required String password2,
//     String role = 'reader',
//   }) => _request(
//     'POST',
//     '/auth/dj/registration/',
//     body: {
//       'username': username,
//       'email': email,
//       'password1': password1,
//       'password2': password2,
//       'role': role,
//     },
//     requiresAuth: false,
//   );

//   /// send fcm token to backend
//   Future<http.Response> sendFcmToken(Map<String, dynamic> replyData) async {

//       final token = await _db.getToken();
//       final url = Uri.parse('$baseUrl/auth/save-fcm-token/');
//       _logRequest('POST', url, body: replyData);
//       final response = await http.post(
//         url,
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(replyData),
//       );
//       _logResponse(response);
//       return response;

//   }

//   static Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) => _request(
//     'POST',
//     '/auth/token/',
//     body: {'email': email, 'password': password},
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> refreshToken(String refresh) => _request(
//     'POST',
//     '/auth/token/refresh/',
//     body: {'refresh': refresh},
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> getMe() => _request('GET', '/auth/me/');

//   static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
//       _request('PATCH', '/auth/me/', body: data);

//   static Future<Map<String, dynamic>> becomeAuthor() =>
//       _request('POST', '/auth/become-author/');

//   static Future<Map<String, dynamic>> followUser(String username) =>
//       _request('POST', '/auth/follow/$username/');

//   static Future<Map<String, dynamic>> unfollowUser(String username) =>
//       _request('DELETE', '/auth/follow/$username/');

//   // ── Stories ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStories({
//     String? genre,
//     String? tag,
//     String? search,
//     String? language,
//     String? status,
//     int page = 1,
//   }) {
//     var params = '?page=$page';
//     if (genre != null) params += '&genre=$genre';
//     if (tag != null) params += '&tag=$tag';
//     if (search != null) params += '&search=$search';
//     if (language != null) params += '&language=$language';
//     if (status != null) params += '&status=$status';
//     return _request('GET', '/stories/$params', requiresAuth: false);
//   }

//   static Future<Map<String, dynamic>> getCompletedStories() =>
//       _request('GET', '/stories/completed-stories/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getFreeDownLoad() =>
//       _request('GET', '/stories/free-download/', requiresAuth: false);

//    static Future<Map<String, dynamic>> getWorldFamous() =>
//       _request('GET', '/stories/world-Famous/', requiresAuth: false);

//      static Future<Map<String, dynamic>> getAfricanFolkTale() =>
//       _request('GET', '/stories/african-folktale/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTrending() =>
//       _request('GET', '/stories/trending/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getFeatured() =>
//       _request('GET', '/stories/featured/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getEditorsPick() =>
//       _request('GET', '/stories/editors-pick/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
//       _request('GET', '/stories/$slug/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getGenres() =>
//       _request('GET', '/stories/genres/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTags() =>
//       _request('GET', '/stories/tags/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getMyBookmarks() =>
//       _request('GET', '/stories/bookmarks/');

//   static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
//       _request('POST', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> removeBookmark(String slug) =>
//       _request('DELETE', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> rateStory(
//     String slug,
//     int score,
//     String review,
//   ) => _request(
//     'POST',
//     '/stories/$slug/rate/',
//     body: {'score': score, 'review': review},
//   );

//   static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
//       _request('POST', '/stories/', body: data);

//   static Future<Map<String, dynamic>> updateStory(
//     String slug,
//     Map<String, dynamic> data,
//   ) => _request('PATCH', '/stories/$slug/', body: data);

//   static Future<Map<String, dynamic>> getMyStories() =>
//       _request('GET', '/stories/mine/');

//   // ── Chapters ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getChapters(String storySlug) =>
//       _request('GET', '/chapters/$storySlug/chapters/', requiresAuth: true);

//   static Future<Map<String, dynamic>> getChapter(
//     String storySlug,
//     int chapterNumber,
//   ) => _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

//   static Future<Map<String, dynamic>> unlockChapter(
//     String storySlug,
//     int chapterNumber,
//   ) => _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

//   static Future<Map<String, dynamic>> createChapter(
//     String storySlug,
//     Map<String, dynamic> data,
//   ) => _request('POST', '/chapters/$storySlug/chapters/', body: data);

//   // ── Coins ──────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getCoinPackages() =>
//       _request('GET', '/coins/packages/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getSubscriptionPlans() =>
//       _request('GET', '/coins/plans/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getCoinBalance() =>
//       _request('GET', '/coins/balance/');

//   static Future<Map<String, dynamic>> createCheckout(
//     String purchaseType, {
//     String? packageId,
//     String? planId,
//   }) => _request(
//     'POST',
//     '/coins/checkout/',
//     body: {
//       'purchase_type': purchaseType,
//       if (packageId != null) 'package_id': packageId,
//       if (planId != null) 'plan_id': planId,
//     },
//   );

//   // ── Comments ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getComments(
//     String storySlug,
//     int chapterNumber,
//   ) => _request(
//     'GET',
//     '/comments/$storySlug/chapters/$chapterNumber/comments/',
//     requiresAuth: false,
//   );

//   static Future<Map<String, dynamic>> postComment(
//     String storySlug,
//     int chapterNumber,
//     String content, {
//     int? parentId,
//     int? paragraphIndex,
//   }) => _request(
//     'POST',
//     '/comments/$storySlug/chapters/$chapterNumber/comments/',
//     body: {
//       'content': content,
//       if (parentId != null) 'parent': parentId,
//       if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
//     },
//   );

//   static Future<Map<String, dynamic>> likeComment(int commentId) =>
//       _request('POST', '/comments/comment/$commentId/like/');

//   static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
//       _request('DELETE', '/comments/comment/$commentId/like/');

//   // ── Tips ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> sendTip(
//     String storySlug,
//     int coins, {
//     String? message,
//   }) => _request(
//     'POST',
//     '/tips/$storySlug/tip/',
//     body: {
//       'coins_amount':
//           coins.toInt(), // explicit int — prevents string serialisation
//       if (message != null && message.isNotEmpty) 'message': message,
//     },
//   );

//   static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
//       _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

//   // ── Notifications ──────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getNotifications() =>
//       _request('GET', '/notifications/');

//   static Future<Map<String, dynamic>> getUnreadCount() =>
//       _request('GET', '/notifications/unread/');

//   static Future<Map<String, dynamic>> markAllRead() =>
//       _request('POST', '/notifications/mark-all-read/');

//   static Future<Map<String, dynamic>> markRead(int id) =>
//       _request('POST', '/notifications/$id/read/');
//   //}

//   static Future<Map<String, dynamic>> requestPayout() => _request(
//     'POST',
//     '/coins/payout/request/',
//     body: {'payout_method': 'bank_transfer'},
//   );

//   static Future<Map<String, dynamic>> getPublicProfile(String username) =>
//       _request('GET', '/auth/profile/$username/', requiresAuth: false);

//   // ── Reviews ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStoryReviews(
//     String slug, {
//     String type = 'all',
//   }) {
//     final query = type == 'all' ? '' : '?rating=$type';
//     return _request(
//       'GET',
//       '/stories/reviews/$slug/reviews/$query',
//       requiresAuth: false,
//     );
//   }

//   static Future<Map<String, dynamic>> submitReview(
//     String slug, {
//     required String rating,
//     String content = '',
//   }) => _request(
//     'POST',
//     '/stories/reviews/$slug/reviews/',
//     body: {'rating': rating, 'content': content},
//   );
//  // myLog.log(content);
//   // ── Rewards ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> claimDailyReward(int coins) =>
//       _request('POST', '/coins/claim-reward/', body: {'coins': coins});

//   // ── VIP / Subscription ─────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getVipStatus() =>
//       _request('GET', '/coins/vip-status/');

//   static Future<Map<String, dynamic>> cancelSubscription() =>
//       _request('POST', '/coins/subscription/cancel/');

// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:novelux/config/local_storage.dart';
import 'dart:developer' as myLog;

// class ApiService {
//   static const String baseUrl = 'https://novelux.onrender.com/api';
//   //'http://127.0.0.1:8000/api';

//   //'http://10.0.2.2:8000/api';
//   // Use http://localhost:8000/api for iOS simulator
//   // Use http://192.168.222.146:8000/api for physical device

//   static final DataBase _db = Get.find<DataBase>();

//   // ── Generic request handler ────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> _request(
//     String method,
//     String endpoint, {
//     Map<String, dynamic>? body,
//     bool requiresAuth = true,
//     bool isFormData = false,
//   }) async {
//     final token = await _db.getToken();
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };

//     final uri = Uri.parse('$baseUrl$endpoint');
//     http.Response response;

//     try {
//       switch (method.toUpperCase()) {
//         case 'GET':
//           response = await http.get(uri, headers: headers);
//           break;
//         case 'POST':
//           response = await http.post(uri,
//               headers: headers, body: body != null ? jsonEncode(body) : null);
//           break;
//         case 'PATCH':
//           response = await http.patch(uri,
//               headers: headers, body: body != null ? jsonEncode(body) : null);
//           break;
//         case 'DELETE':
//           response = await http.delete(uri, headers: headers);
//           break;
//         default:
//           throw Exception('Unsupported HTTP method: $method');
//       }

//       final decoded = jsonDecode(utf8.decode(response.bodyBytes));

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         return {'success': true, 'data': decoded, 'status': response.statusCode};
//       } else {
//         return {
//           'success': false,
//           'data': decoded,
//           'status': response.statusCode,
//           'error': _extractError(decoded),
//         };
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Network error: $e', 'status': 0};
//     }
//   }

//   static String _extractError(dynamic decoded) {
//     if (decoded is Map) {
//       if (decoded.containsKey('detail')) {
//         return decoded['detail'].toString();
//       }
//       final firstKey = decoded.keys.first;
//       final firstVal = decoded[firstKey];
//       if (firstVal is List) {
//         return '$firstKey: ${firstVal.first}';
//       }
//       return firstVal.toString();
//     }
//     return decoded.toString();
//   }

//   // ── Auth ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> register({
//     required String username,
//     required String email,
//     required String password1,
//     required String password2,
//     String role = 'reader',
//   }) =>
//       _request('POST', '/auth/dj/registration/', body: {
//         'username': username,
//         'email': email,
//         'password1': password1,
//         'password2': password2,
//         'role': role,
//       }, requiresAuth: false);

//   static Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) =>
//       _request('POST', '/auth/token/', body: {
//         'email': email,
//         'password': password,
//       }, requiresAuth: false);

//   static Future<Map<String, dynamic>> refreshToken(String refresh) =>
//       _request('POST', '/auth/token/refresh/', body: {'refresh': refresh},
//           requiresAuth: false);

//   static Future<Map<String, dynamic>> getMe() =>
//       _request('GET', '/auth/me/');

//   static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
//       _request('PATCH', '/auth/me/', body: data);

//   static Future<Map<String, dynamic>> becomeAuthor() =>
//       _request('POST', '/auth/become-author/');

//   static Future<Map<String, dynamic>> followUser(String username) =>
//       _request('POST', '/auth/follow/$username/');

//   static Future<Map<String, dynamic>> unfollowUser(String username) =>
//       _request('DELETE', '/auth/follow/$username/');

//   // ── Stories ────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getStories({
//     String? genre,
//     String? tag,
//     String? search,
//     String? language,
//     String? status,
//     int page = 1,
//   }) {
//     var params = '?page=$page';
//     if (genre != null) params += '&genre=$genre';
//     if (tag != null) params += '&tag=$tag';
//     if (search != null) params += '&search=$search';
//     if (language != null) params += '&language=$language';
//     if (status != null) params += '&status=$status';
//     return _request('GET', '/stories/$params', requiresAuth: false);
//   }

//   static Future<Map<String, dynamic>> getTrending() =>
//       _request('GET', '/stories/trending/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getFeatured() =>
//       _request('GET', '/stories/featured/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getEditorsPick() =>
//       _request('GET', '/stories/editors-pick/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
//       _request('GET', '/stories/$slug/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getGenres() =>
//       _request('GET', '/stories/genres/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getTags() =>
//       _request('GET', '/stories/tags/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getMyBookmarks() =>
//       _request('GET', '/stories/bookmarks/');

//   static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
//       _request('POST', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> removeBookmark(String slug) =>
//       _request('DELETE', '/stories/$slug/bookmark/');

//   static Future<Map<String, dynamic>> rateStory(
//           String slug, int score, String review) =>
//       _request('POST', '/stories/$slug/rate/', body: {'score': score, 'review': review});

//   static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
//       _request('POST', '/stories/', body: data);

//   static Future<Map<String, dynamic>> updateStory(
//           String slug, Map<String, dynamic> data) =>
//       _request('PATCH', '/stories/$slug/', body: data);

//   static Future<Map<String, dynamic>> getMyStories() =>
//       _request('GET', '/stories/mine/');

//   // ── Chapters ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getChapters(String storySlug) =>
//       _request('GET', '/chapters/$storySlug/chapters/', requiresAuth: true);

//   static Future<Map<String, dynamic>> getChapter(
//           String storySlug, int chapterNumber) =>
//       _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

//   static Future<Map<String, dynamic>> unlockChapter(
//           String storySlug, int chapterNumber) =>
//       _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

//   static Future<Map<String, dynamic>> createChapter(
//           String storySlug, Map<String, dynamic> data) =>
//       _request('POST', '/chapters/$storySlug/chapters/', body: data);

//   // ── Coins ──────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getCoinPackages() =>
//       _request('GET', '/coins/packages/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getSubscriptionPlans() =>
//       _request('GET', '/coins/plans/', requiresAuth: false);

//   static Future<Map<String, dynamic>> getCoinBalance() =>
//       _request('GET', '/coins/balance/');

//   static Future<Map<String, dynamic>> createCheckout(
//           String purchaseType, {String? packageId, String? planId}) =>
//       _request('POST', '/coins/checkout/', body: {
//         'purchase_type': purchaseType,
//         if (packageId != null) 'package_id': packageId,
//         if (planId != null) 'plan_id': planId,
//       });

//   // ── Comments ───────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getComments(
//           String storySlug, int chapterNumber) =>
//       _request('GET', '/comments/$storySlug/chapters/$chapterNumber/comments/',
//           requiresAuth: false);

//   static Future<Map<String, dynamic>> postComment(
//           String storySlug, int chapterNumber, String content,
//           {int? parentId, int? paragraphIndex}) =>
//       _request('POST',
//           '/comments/$storySlug/chapters/$chapterNumber/comments/',
//           body: {
//             'content': content,
//             if (parentId != null) 'parent': parentId,
//             if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
//           });

//   static Future<Map<String, dynamic>> likeComment(int commentId) =>
//       _request('POST', '/comments/comment/$commentId/like/');

//   static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
//       _request('DELETE', '/comments/comment/$commentId/like/');

//   // ── Tips ───────────────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> sendTip(
//           String storySlug, int coins, {String? message}) =>
//       _request('POST', '/tips/$storySlug/tip/', body: {
//         'coins_amount': coins,
//         if (message != null) 'message': message,
//       });

//   static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
//       _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

//   // ── Notifications ──────────────────────────────────────────────────────────
//   static Future<Map<String, dynamic>> getNotifications() =>
//       _request('GET', '/notifications/');

//   static Future<Map<String, dynamic>> getUnreadCount() =>
//       _request('GET', '/notifications/unread/');

//   static Future<Map<String, dynamic>> markAllRead() =>
//       _request('POST', '/notifications/mark-all-read/');

//   static Future<Map<String, dynamic>> markRead(int id) =>
//       _request('POST', '/notifications/$id/read/');
// //}

//   static Future<Map<String, dynamic>> requestPayout() =>
//       _request('POST', '/coins/payout/request/', body: {
//         'payout_method': 'bank_transfer',
//       });

//   static Future<Map<String, dynamic>> getPublicProfile(String username) =>
//       _request('GET', '/auth/profile/$username/', requiresAuth: false);
// }

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:novelux/config/local_storage.dart';

class ApiService {
  static const String baseUrl = 'https://novelux.onrender.com/api';
  //'http://10.0.2.2:8000/api';
  // Use http://localhost:8000/api for iOS simulator
  // Use http://YOUR_PC_IP:8000/api for physical device

  static final DataBase _db = Get.find<DataBase>();

  // ── Generic request handler ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool isFormData = false,
  }) async {
    myLog.log(endpoint);
    final token = await _db.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$baseUrl$endpoint');
    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final bodyStr = utf8.decode(response.bodyBytes).trim();
      final decoded = bodyStr.isEmpty ? <String, dynamic>{} : jsonDecode(bodyStr);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': decoded,
          'status': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'data': decoded,
          'status': response.statusCode,
          'error': _extractError(decoded),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e', 'status': 0};
    }
  }

  void _logResponse(http.Response response) {
    if (kDebugMode) {
      print('--- API Response ---');
      print('Status Code: ${response.statusCode}');
      print('URL: ${response.request?.url}');
      try {
        // Attempt to decode and print if JSON, otherwise print raw body
        final decodedBody = jsonDecode(response.body);
        print('Body: ${jsonEncode(decodedBody)}'); // Pretty print JSON
      } catch (e) {
        print('Body: ${response.body}'); // Print as is if not JSON
      }
      print('--------------------');
    }
  }

  static String _extractError(dynamic decoded) {
    if (decoded is Map) {
      if (decoded.containsKey('detail')) {
        return decoded['detail'].toString();
      }
      final firstKey = decoded.keys.first;
      final firstVal = decoded[firstKey];
      if (firstVal is List) {
        return '$firstKey: ${firstVal.first}';
      }
      return firstVal.toString();
    }
    return decoded.toString();
  }

  // Helper function for logging
  void _logRequest(String method, Uri url, {dynamic body}) {
    if (kDebugMode) {
      print('--- API Request ---');
      print('Method: $method');
      print('URL: $url');
      if (body != null) {
        print('Body: ${jsonEncode(body)}');
      }
      print('-------------------');
    }
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password1,
    required String password2,
    String role = 'reader',
    String? deviceId,
    String? platform,
  }) => _request(
    'POST',
    '/auth/dj/registration/',
    body: {
      'username': username,
      'email': email,
      'password1': password1,
      'password2': password2,
      'role': role,
      if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      if (platform != null && platform.isNotEmpty) 'platform': platform,
    },
    requiresAuth: false,
  );

  /// send fcm token to backend
  Future<http.Response> sendFcmToken(Map<String, dynamic> replyData) async {
    final token = await _db.getToken();
    final url = Uri.parse('$baseUrl/auth/save-fcm-token/');
    _logRequest('POST', url, body: replyData);
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(replyData),
    );
    _logResponse(response);
    return response;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceId,
    String? platform,
  }) => _request(
    'POST',
    '/auth/token/',
    body: {
      'email': email,
      'password': password,
      if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      if (platform != null && platform.isNotEmpty) 'platform': platform,
    },
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> refreshToken(String refresh) => _request(
    'POST',
    '/auth/token/refresh/',
    body: {'refresh': refresh},
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getMe() => _request('GET', '/auth/me/');

  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
      _request('PATCH', '/auth/me/', body: data);

  static Future<Map<String, dynamic>> becomeAuthor() =>
      _request('POST', '/auth/become-author/');

  static Future<Map<String, dynamic>> followUser(String username) =>
      _request('POST', '/auth/follow/$username/');
  //TODO: verify purchase endpoint is currently open to all users, but should be restricted to admins only. This is because the app needs to verify purchases before unlocking chapters, and we don't want to expose this functionality to regular users. Once the purchase verification flow is fully implemented and tested, we can update the backend to restrict access to this endpoint.
  static Future<Map<String, dynamic>> verifyPurchase({
    required String productId,
    required String purchaseId,
    required String receipt,
    required String platform, // 'android' or 'ios'
  }) => _request(
    'POST',
    '/coins/verify-purchases/',
    body: {
      'product_id': productId,
      'purchase_token': receipt,   // Android: serverVerificationData token
      'receipt': receipt,          // iOS: base64 receipt data
      'platform': platform,
    },
  );

  static Future<Map<String, dynamic>> unfollowUser(String username) =>
      _request('DELETE', '/auth/follow/$username/');

  // ── Stories ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStories({
    String? genre,
    String? tag,
    String? search,
    String? language,
    String? status,
    String? targetGender,
    int page = 1,
    int pageSize = 20,
  }) {
    myLog.log(genre ?? 'N/A');
    final parts = <String>[];
    if (genre != null && genre.isNotEmpty)
      parts.add('genre=${genre.replaceAll(' ', '-').toLowerCase()}');
    if (tag != null) parts.add('tag=$tag');
    if (search != null) parts.add('search=${Uri.encodeQueryComponent(search)}');
    if (language != null) parts.add('language=$language');
    if (status != null) parts.add('status=$status');
    parts.add('page=$page');
    parts.add('page_size=$pageSize');
    final query = '?${parts.join('&')}';
    return _request('GET', '/stories/$query', requiresAuth: false);
  }

  /// Personalised feed — sends preferred genres + gender to backend
  static Future<Map<String, dynamic>> getPersonalisedFeed({
    required List<String> genres,
    String gender = '',
    String? tab,
    int page = 1,
    int pageSize = 5, // ← added for pagination
  }) {
    var params = '?page=$page&page_size=$pageSize';
    if (genres.isNotEmpty) params += "&genres=${genres.join(',')}";
    if (gender.isNotEmpty) params += '&gender=$gender';
    if (tab != null && tab != 'All') params += '&genre=$tab';
    return _request('GET', '/stories/personalised/$params');
  }

  static Future<Map<String, dynamic>> getCompletedStories({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/completed-stories/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getFreeDownLoad({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/free-download/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getWorldFamous({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/world-Famous/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getAfricanFolkTale({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/african-folktale/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getNewArrivals({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/new-arrivals/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getRecommended({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/recommended/?page=$page&page_size=$pageSize',
    requiresAuth: true,
  );

  static Future<Map<String, dynamic>> getFreeDiscount({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/free-discount/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getRankings({
    String period = 'all-time',
    int page = 1,
    int pageSize = 20,
  }) => _request(
    'GET',
    '/stories/rankings/?period=$period&page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getAuthorSpotlight() => _request(
    'GET',
    '/stories/author-spotlight/',
    requiresAuth: false,
  );

  /// GET /api/stories/explore-tab/<tab>/
  /// Returns structured sections for Werewolf, Billionaire, Short Fics, etc.
  /// [tab] one of: werewolf | billionaire | suspense | for-her | for-him |
  ///               short-fics | ranking
  /// [period] only used for ranking tab: all-time | monthly | weekly | daily
  static Future<Map<String, dynamic>> getExploreTab(
    String tab, {
    String period = 'all-time',
  }) => _request(
    'GET',
    '/stories/explore-tab/$tab/${tab == 'ranking' ? '?period=$period' : ''}',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getShortStories({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/short-stories/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  /// GET /api/stories/genre-section/?tab=for-her&section=picks-for-you&page=1
  /// Paginated "More" list for any section inside a genre/gender explore tab.
  static Future<Map<String, dynamic>> getGenreSection({
    required String tab,
    required String section,
    int page = 1,
  }) => _request(
    'GET',
    '/stories/genre-section/?tab=$tab&section=$section&page=$page',
    requiresAuth: false,
  );

  /// GET /api/stories/ranking-section/?section=new-releases&filter=daily&page=1
  /// Paginated list for Ranking tab "More" screens.
  /// [section] new-releases | most-read
  /// [filter]  daily | rising  (new-releases);  must-read | popularity  (most-read)
  static Future<Map<String, dynamic>> getRankingSection({
    required String section,
    required String filter,
    int page = 1,
  }) => _request(
    'GET',
    '/stories/ranking-section/?section=$section&filter=$filter&page=$page',
    requiresAuth: false,
  );

  // static Future<Map<String, dynamic>> getBestNovels({
  //   int page = 1,
  //   int pageSize = 5,
  // }) => _request(
  //   'GET',
  //   '/stories/african-folktale/?page=$page&page_size=$pageSize',
  //   requiresAuth: false,
  // );

  static Future<Map<String, dynamic>> getTrending({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/trending/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  // sortBy: 'views' | 'comments' | 'ratings' | 'status' | 'topBuzz' | 'tips'
  static Future<Map<String, dynamic>> getBestNovels({
    required String sortBy,
    int page = 1,
    int pageSize = 9,
  }) {
    const orderingMap = {
      'views': '-total_views',
      'comments': '-total_comments',
      'ratings': '-average_rating',
      'status': '-status',
      'topBuzz': '-word_count',
      'tips': '-total_tips',
    };
    final ordering = orderingMap[sortBy] ?? '-total_views';
    // 'status' filters for completed stories via the status query param.
    final statusFilter = sortBy == 'status' ? '&status=completed' : '';
    return _request(
      'GET',
      '/stories/?ordering=$ordering$statusFilter&page=$page&page_size=$pageSize',
      requiresAuth: false,
    );
  }

  static Future<Map<String, dynamic>> getFeatured({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/featured/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getEditorsPick({
    int page = 1,
    int pageSize = 5,
  }) => _request(
    'GET',
    '/stories/editors-pick/?page=$page&page_size=$pageSize',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> getStoryDetail(String slug) =>
      _request('GET', '/stories/$slug/', requiresAuth: false);

  static Future<Map<String, dynamic>> getGenres() =>
      _request('GET', '/stories/genres/', requiresAuth: false);

  static Future<Map<String, dynamic>> getTags() =>
      _request('GET', '/stories/tags/', requiresAuth: false);

  static Future<Map<String, dynamic>> getMyBookmarks() =>
      _request('GET', '/stories/bookmarks/');

  static Future<Map<String, dynamic>> bookmarkStory(String slug) =>
      _request('POST', '/stories/$slug/bookmark/');

  static Future<Map<String, dynamic>> removeBookmark(String slug) =>
      _request('DELETE', '/stories/$slug/bookmark/');

  /// Report a story for policy-violating content.
  /// [reason] must be one of: sexual, violence, hate, copyright, spam, other.
  static Future<Map<String, dynamic>> reportStory(
    String slug, {
    required String reason,
    String details = '',
    int? chapterNumber,
  }) => _request(
    'POST',
    '/stories/$slug/report/',
    body: {
      'reason': reason,
      'details': details,
      if (chapterNumber != null) 'chapter_number': chapterNumber,
    },
  );

  static Future<Map<String, dynamic>> rateStory(
    String slug,
    int score,
    String review,
  ) => _request(
    'POST',
    '/stories/$slug/rate/',
    body: {'score': score, 'review': review},
  );

  static Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) =>
      _request('POST', '/stories/', body: data);

  static Future<Map<String, dynamic>> updateStory(
    String slug,
    Map<String, dynamic> data,
  ) => _request('PATCH', '/stories/$slug/', body: data);

  static Future<Map<String, dynamic>> getMyStories() =>
      _request('GET', '/stories/mine/');

  // ── Chapters ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getChapters(
    String storySlug, {
    int page = 1,
    int pageSize = 500,
  }) => _request(
    'GET',
    '/chapters/$storySlug/chapters/?page=$page&page_size=$pageSize',
    requiresAuth: true,
  );

  static Future<Map<String, dynamic>> getChapter(
    String storySlug,
    int chapterNumber,
  ) => _request('GET', '/chapters/$storySlug/chapters/$chapterNumber/');

  /// Full story for offline reading — gated by rewarded ad ('ad') or a
  /// 120-coin charge ('coins'); free for VIP subscribers.
  static Future<Map<String, dynamic>> downloadStoryOffline(
    String storySlug,
    String method,
  ) => _request(
    'POST',
    '/chapters/$storySlug/chapters/download/',
    body: {'method': method},
  );

  static Future<Map<String, dynamic>> unlockChapter(
    String storySlug,
    int chapterNumber,
  ) => _request('POST', '/chapters/$storySlug/chapters/$chapterNumber/unlock/');

  static Future<Map<String, dynamic>> updateChapter(
    String storySlug,
    int chapterNumber,
    Map<String, dynamic> data,
  ) => _request(
    'PATCH',
    '/chapters/$storySlug/chapters/$chapterNumber/',
    body: data,
  );

  static Future<Map<String, dynamic>> createChapter(
    String storySlug,
    Map<String, dynamic> data,
  ) => _request('POST', '/chapters/$storySlug/chapters/', body: data);

  // ── Coins ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCoinPackages() =>
      _request('GET', '/coins/packages/', requiresAuth: false);

  static Future<Map<String, dynamic>> getSubscriptionPlans() =>
      _request('GET', '/coins/plans/', requiresAuth: false);

  static Future<Map<String, dynamic>> getCoinBalance() =>
      _request('GET', '/coins/balance/');

  static Future<Map<String, dynamic>> createCheckout(
    String purchaseType, {
    String? packageId,
    String? planId,
  }) => _request(
    'POST',
    '/coins/checkout/',
    body: {
      'purchase_type': purchaseType,
      if (packageId != null) 'package_id': packageId,
      if (planId != null) 'plan_id': planId,
    },
  );

  // ── Comments ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getComments(
    String storySlug,
    int chapterNumber,
  ) => _request(
    'GET',
    '/comments/$storySlug/chapters/$chapterNumber/comments/',
    requiresAuth: false,
  );

  static Future<Map<String, dynamic>> postComment(
    String storySlug,
    int chapterNumber,
    String content, {
    int? parentId,
    int? paragraphIndex,
  }) => _request(
    'POST',
    '/comments/$storySlug/chapters/$chapterNumber/comments/',
    body: {
      'content': content,
      if (parentId != null) 'parent': parentId,
      if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
    },
  );

  static Future<Map<String, dynamic>> likeComment(int commentId) =>
      _request('POST', '/comments/comment/$commentId/like/');

  static Future<Map<String, dynamic>> unlikeComment(int commentId) =>
      _request('DELETE', '/comments/comment/$commentId/like/');

  // ── Tips ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendTip(
    String storySlug,
    int coins, {
    String? message,
  }) => _request(
    'POST',
    '/tips/$storySlug/tip/',
    body: {
      'coins_amount':
          coins.toInt(), // explicit int — prevents string serialisation
      if (message != null && message.isNotEmpty) 'message': message,
    },
  );

  static Future<Map<String, dynamic>> getTopTippers(String storySlug) =>
      _request('GET', '/tips/$storySlug/top-tippers/', requiresAuth: false);

  // ── Notifications ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getNotifications() =>
      _request('GET', '/notifications/');

  static Future<Map<String, dynamic>> getUnreadCount() =>
      _request('GET', '/notifications/unread/');

  static Future<Map<String, dynamic>> markAllRead() =>
      _request('POST', '/notifications/mark-all-read/');

  static Future<Map<String, dynamic>> markRead(int id) =>
      _request('POST', '/notifications/$id/read/');
  //}

  static Future<Map<String, dynamic>> requestPayout() => _request(
    'POST',
    '/coins/payout/request/',
    body: {'payout_method': 'bank_transfer'},
  );

  static Future<Map<String, dynamic>> getPublicProfile(String username) =>
      _request('GET', '/auth/profile/$username/', requiresAuth: false);

  // ── Reviews ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStoryReviews(
    String slug, {
    String type = 'all',
  }) {
    final query = type == 'all' ? '' : '?rating=$type';
    return _request(
      'GET',
      '/stories/reviews/$slug/reviews/$query',
      requiresAuth: false,
    );
  }

  static Future<Map<String, dynamic>> submitReview(
    String slug, {
    required String rating,
    String content = '',
  }) => _request(
    'POST',
    '/stories/reviews/$slug/reviews/',
    body: {'rating': rating, 'content': content},
  );
  // myLog.log(content);
  // ── Rewards ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> claimDailyReward(int coins) =>
      _request('POST', '/coins/claim-reward/', body: {'coins': coins});

  // ── VIP / Subscription ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getVipStatus() =>
      _request('GET', '/coins/vip-status/');

  static Future<Map<String, dynamic>> cancelSubscription() =>
      _request('POST', '/coins/subscription/cancel/');

  // ── Reading Schedule & Sessions ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getReadingSchedule() =>
      _request('GET', '/reading/schedule/');

  static Future<Map<String, dynamic>> saveReadingSchedule(
    Map<String, dynamic> data,
  ) => _request('POST', '/reading/schedule/', body: data);

  static Future<Map<String, dynamic>> logReadingSession({
    required String storySlug,
    required int chapter,
    required int minutes,
  }) => _request(
    'POST',
    '/reading/session/',
    body: {'story_slug': storySlug, 'chapter': chapter, 'minutes': minutes},
  );

  static Future<Map<String, dynamic>> getReadingStats({int goal = 30}) =>
      _request('GET', '/reading/stats/?goal=$goal');

  // ── User Preferences ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> saveUserPreferences({
    required List<String> genres,
    String gender = '',
  }) => _request(
    'POST',
    '/auth/preferences/',
    body: {'preferred_genres': genres, if (gender.isNotEmpty) 'gender': gender},
  );

  static Future<Map<String, dynamic>> getUserPreferences() =>
      _request('GET', '/auth/preferences/');

  // ── Promo banners ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPromoBanners() =>
      _request('GET', '/stories/banners/', requiresAuth: false);

  // ── Library banner ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getLibraryBanner() =>
      _request('GET', '/stories/library-banner/', requiresAuth: false);

  // ── CE Story Management ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCeBooks({
    String status = '',
    String search = '',
    int page = 1,
  }) =>
      _request('GET',
          '/editorial/ce/books/?status=$status&search=$search&page=$page');

  static Future<Map<String, dynamic>> ceEditStory(
          String slug, Map<String, dynamic> data) =>
      _request('PATCH', '/editorial/ce-story-queue/$slug/edit/', body: data);

  static Future<Map<String, dynamic>> ceRemoveStory(String slug,
          {String reason = ''}) =>
      _request('POST', '/editorial/ce/books/$slug/remove/',
          body: {'reason': reason});

  static Future<Map<String, dynamic>> ceRestoreStory(String slug) =>
      _request('POST', '/editorial/ce/books/$slug/restore/');

  // ── Reading History ───────────────────────────────────────────────────────
  /// GET /api/reading/history/ — server-side reading history (paginated)
  static Future<Map<String, dynamic>> getReadingHistory({int page = 1}) =>
      _request('GET', '/reading/history/?page=$page');

  /// POST /api/reading/history/  — log that user opened a chapter
  /// Log a reading history entry.
  /// Endpoint: POST /api/reading/history/
  /// ⚠️  Do NOT change to '/history/' — the full path is '/reading/history/'
  static Future<Map<String, dynamic>> logReadingHistory({
    required String storySlug,
    required int chapterNumber,
    required String chapterTitle,
  }) => _request(
    'POST',
    '/reading/history/',
    body: {
      'story_slug': storySlug, // backend field: story_slug
      'chapter_number': chapterNumber,
      'chapter_title': chapterTitle,
    },
  );

  /// DELETE /api/reading/history/<id>/  — remove single history entry
  static Future<Map<String, dynamic>> deleteReadingHistory(int id) =>
      _request('DELETE', '/reading/history/$id/');

  /// DELETE /api/reading/history/  — clear all history
  static Future<Map<String, dynamic>> clearReadingHistory() =>
      _request('DELETE', '/reading/history/');

  // ── Book request ("not found, please tell us") ────────────────────────────
  static Future<Map<String, dynamic>> requestBook({
    required String title,
    String author = '',
  }) => _request(
    'POST',
    '/stories/request/',
    body: {'title': title, if (author.isNotEmpty) 'author': author},
  );

  // ── Google Sign-In ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
    required String email,
    String? displayName,
    String? photoUrl,
  }) => _request(
    'POST',
    '/auth/google/',
    body: {
      'id_token': idToken,
      'email': email,
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
    },
    requiresAuth: false,
  );

  // ── Check-in streak ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCheckinStatus() =>
      _request('GET', '/coins/checkin/status/');

  static Future<Map<String, dynamic>> claimCheckin() =>
      _request('POST', '/coins/checkin/');

  // ── Tasks ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTasks() =>
      _request('GET', '/coins/tasks/');

  static Future<Map<String, dynamic>> getCoinHistory() =>
      _request('GET', '/coins/transactions/');

  static Future<Map<String, dynamic>> completeTask(
    int taskId, {
    String? response,
  }) => _request(
    'POST',
    '/coins/tasks/$taskId/complete/',
    body: {
      if (response != null && response.isNotEmpty) 'response': response,
    },
  );

  // ── Redeem ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getRedeemPackages() =>
      _request('GET', '/coins/redeem/');

  static Future<Map<String, dynamic>> redeemPackage(String packageKey) =>
      _request('POST', '/coins/redeem/', body: {'package': packageKey});
}



// > Task :app:signingReport
// Variant: debug
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------
// Variant: release
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------
// Variant: profile
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :device_info_plus:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :file_picker:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :firebase_core:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :firebase_messaging:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :flutter_inappwebview_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :flutter_local_notifications:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :flutter_native_splash:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :flutter_plugin_android_lifecycle:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :flutter_timezone:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :google_sign_in_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :image_picker_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :local_auth_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :open_file_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :package_info_plus:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :path_provider_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :permission_handler_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :screen_brightness_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :share_plus:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :shared_preferences_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :sqflite_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :url_launcher_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :wakelock_plus:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------

// > Task :webview_flutter_android:signingReport
// Variant: debugAndroidTest
// Config: debug
// Store: /home/daniel/.android/debug.keystore
// Alias: AndroidDebugKey
// MD5: 66:61:D4:8F:68:D5:02:EB:5D:A5:81:7D:DC:40:6F:45
// SHA1: 89:BC:65:36:82:53:1D:DF:64:1C:3D:E8:F7:FA:06:55:DD:1B:6C:DA
// SHA-256: 9F:9E:8F:7A:8F:F9:B1:0E:9C:A5:6D:B6:86:CB:D1:95:A3:C5:68:0E:22:77:C4:F9:42:D9:E7:CC:B6:73:C5:2C
// Valid until: Friday, November 12, 2055
// ----------
// w: Detected multiple Kotlin daemon sessions at