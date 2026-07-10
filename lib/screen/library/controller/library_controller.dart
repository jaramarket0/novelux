import 'dart:convert';
import 'dart:developer' as myLog;
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── History entry model ────────────────────────────────────────────────────────
class HistoryEntry {
  final int id; // server-side id (0 if local-only)
  final String slug;
  final String title;
  final String coverUrl;
  final int totalChapters;
  final int lastChapterNumber;
  final String lastChapterTitle;
  final DateTime readAt;
  final String status; // 'completed' | 'ongoing' | ''
  final bool isShort;

  const HistoryEntry({
    required this.id,
    required this.slug,
    required this.title,
    required this.coverUrl,
    required this.totalChapters,
    required this.lastChapterNumber,
    required this.lastChapterTitle,
    required this.readAt,
    this.status = '',
    this.isShort = false,
  });

  factory HistoryEntry.fromApi(Map<String, dynamic> j) {
    final story = j['story'] is Map ? j['story'] as Map : {};
    return HistoryEntry(
      id: j['id'] as int? ?? 0,
      slug: story['slug']?.toString() ?? j['story_slug']?.toString() ?? '',
      title: story['title']?.toString() ?? j['story_title']?.toString() ?? '',
      coverUrl: story['cover_image']?.toString() ?? '',
      totalChapters:
          (story['total_chapters'] ?? story['chapter_count'] ?? 0) as int,
      lastChapterNumber:
          (j['chapter_number'] ?? j['last_chapter_number'] ?? 0) as int,
      lastChapterTitle:
          j['chapter_title']?.toString() ??
          j['last_chapter_title']?.toString() ??
          '',
      readAt:
          DateTime.tryParse(j['read_at']?.toString() ?? '') ?? DateTime.now(),
      status: story['status']?.toString() ?? '',
      isShort: (story['total_chapters'] ?? 0) as int < 20,
    );
  }

  factory HistoryEntry.fromLocal(Map<String, dynamic> j) => HistoryEntry(
    id: 0,
    slug: j['slug']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    coverUrl: j['coverUrl']?.toString() ?? '',
    totalChapters: (j['totalChapters'] ?? 0) as int,
    lastChapterNumber: (j['lastChapterNumber'] ?? 0) as int,
    lastChapterTitle: j['lastChapterTitle']?.toString() ?? '',
    readAt: DateTime.tryParse(j['readAt']?.toString() ?? '') ?? DateTime.now(),
    status: j['status']?.toString() ?? '',
    isShort: j['isShort'] == true,
  );

  Map<String, dynamic> toLocal() => {
    'slug': slug,
    'title': title,
    'coverUrl': coverUrl,
    'totalChapters': totalChapters,
    'lastChapterNumber': lastChapterNumber,
    'lastChapterTitle': lastChapterTitle,
    'readAt': readAt.toIso8601String(),
    'status': status,
    'isShort': isShort,
  };
}

// ── Library + History Controller ───────────────────────────────────────────────
class LibraryController extends GetxController {
  // ── Library banner ─────────────────────────────────────────────────────────
  final RxList bannerStories = [].obs;
  final RxInt  bannerIndex  = 0.obs;
  final RxBool isLoadingBanner = false.obs;

  // ── Library (bookmarks) ────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxList bookmarks = [].obs;
  final RxString activeFilter = 'All'.obs;

  final List<String> filters = ['All', 'Completed', 'Reading', 'Wishlist'];

  // ── History ────────────────────────────────────────────────────────────────
  final RxBool isLoadingHistory = false.obs;
  // Grouped: [ { 'label': 'Today', 'entries': [HistoryEntry] }, ... ]
  final RxList<Map<String, dynamic>> historyGroups =
      <Map<String, dynamic>>[].obs;

  static const _kHistoryKey = 'nux_reading_history_v1';
  static const _kMaxLocal = 100; // keep last 100 entries locally

  @override
  void onInit() {
    super.onInit();
    fetchLibraryBanner();
    if (Get.find<AuthController>().isLoggedIn.value) {
      fetchBookmarks();
      fetchHistory();
    }
  }

  // ── Banner ─────────────────────────────────────────────────────────────────
  Future<void> fetchLibraryBanner() async {
    isLoadingBanner.value = true;
    final res = await ApiService.getLibraryBanner();
    isLoadingBanner.value = false;
    if (res['success']) {
      final d = res['data'];
      bannerStories.value = d is List ? d : (d['results'] ?? []);
    }
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────────
  Future<void> fetchBookmarks() async {
    isLoading.value = true;
    final res = await ApiService.getMyBookmarks();
    isLoading.value = false;
    if (res['success']) {
      final d = res['data'];
      bookmarks.value = d is List ? d : (d['results'] ?? []);
    }
  }

  List get filteredBookmarks {
    if (activeFilter.value == 'All') return bookmarks;
    return bookmarks.where((s) {
      final status = s['status'] ?? '';
      switch (activeFilter.value) {
        case 'Completed':
          return status == 'completed';
        case 'Reading':
          return status == 'ongoing';
        default:
          return true;
      }
    }).toList();
  }

  String getCoverUrl(Map story) {
    final c = story['cover_image'] ?? story['coverUrl'] ?? '';
    if (c.toString().isEmpty) return '';
    if (c.toString().startsWith('http')) return c.toString();
    return 'http://10.0.2.2:8000$c';
  }

  String getCoverUrlEntry(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'http://10.0.2.2:8000$url';
  }

  bool isStorySaved(String slug) =>
      bookmarks.any((b) => b['slug'] == slug);

  Future<void> addBookmark(String slug) async {
    await ApiService.bookmarkStory(slug);
    await fetchBookmarks();
  }

  Future<void> removeBookmark(String slug) async {
    await ApiService.removeBookmark(slug);
    bookmarks.removeWhere((s) => s['slug'] == slug);
  }

  List _extractList(dynamic data) =>
      data is List ? data : ((data as Map?)?['results'] ?? []);

  bool _hasNext(dynamic data) {
    if (data is Map) return data['has_next'] == true;
    return false; // plain list → treat as single page
  }

  // ── History — load ─────────────────────────────────────────────────────────
  Future<void> fetchHistory() async {
    myLog.log('fetching history');
    isLoadingHistory.value = true;

    List<HistoryEntry> entries = [];

    // 1. Try server
    final res = await ApiService.getReadingHistory();
    if (res['success']) {
      final data = res['data'];
      myLog.log(data.toString());
      final list = _extractList(data);
      myLog.log(list.toString());
      //data is List ? data : (data['results'] ?? []);
      entries =
          list
              .map(
                (e) =>
                    HistoryEntry.fromApi(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
      // Also merge with local for offline reads
      // entries already from server — already deduped below
      // hasMoreForYou.value = _hasNext(data);
      // if (hasMoreForYou.value) _forYouPage = 2;
    } else {
      // Fall back to local only
      entries = await _loadLocal();
    }

    // Sort newest first
    entries.sort((a, b) => b.readAt.compareTo(a.readAt));

    // Deduplicate by slug — keep most recent per story
    final seen = <String>{};
    final deduped = <HistoryEntry>[];
    for (final e in entries) {
      if (!seen.contains(e.slug)) {
        seen.add(e.slug);
        deduped.add(e);
      }
    }

    historyGroups.value = _groupByDate(deduped);
    isLoadingHistory.value = false;
  }

  // ── History — log a view (called from reading interface & story detail) ─────
  Future<void> logView({
    required String slug,
    required String title,
    required String coverUrl,
    required int totalChapters,
    required int chapterNumber,
    required String chapterTitle,
    String status = '',
  }) async {
    final entry = HistoryEntry(
      id: 0,
      slug: slug,
      title: title,
      coverUrl: coverUrl,
      totalChapters: totalChapters,
      lastChapterNumber: chapterNumber,
      lastChapterTitle: chapterTitle,
      readAt: DateTime.now(),
      status: status,
      isShort: totalChapters < 20,
    );

    // Save locally immediately
    await _saveLocal(entry);

    // Refresh groups
    // await fetchHistory();
    myLog.log('logged view locally for ${entry.slug} - ${entry.title}');
    // Log to server (fire and forget)
    var res = await ApiService.logReadingHistory(
      storySlug: entry.slug, //slug.replaceAll('-', ' ').capitalize!,
      chapterNumber: chapterNumber,
      chapterTitle: entry.title, //chapterTitle,
    ).catchError((e) {
      myLog.log('error saving history to db: $e');
      return e;
    });
    myLog.log('this is the response body $res');
  }

  // ── History — clear ────────────────────────────────────────────────────────
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
    historyGroups.value = [];
    ApiService.clearReadingHistory().catchError((_) {});
  }

  Future<void> removeHistoryEntry(String slug) async {
    // Remove from local
    final entries = await _loadLocal();
    final updated = entries.where((e) => e.slug != slug).toList();
    await _saveAllLocal(updated);
    await fetchHistory();
  }

  // ── Local persistence ──────────────────────────────────────────────────────
  Future<List<HistoryEntry>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) => HistoryEntry.fromLocal(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal(HistoryEntry entry) async {
    final existing = await _loadLocal();
    // Remove old entry for same story
    final filtered = existing.where((e) => e.slug != entry.slug).toList();
    final updated = [entry, ...filtered].take(_kMaxLocal).toList();
    await _saveAllLocal(updated);
  }

  Future<void> _saveAllLocal(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(entries.map((e) => e.toLocal()).toList()),
    );
  }

  List<HistoryEntry> _mergeWithLocal(List<HistoryEntry> server) {
    // Server is authoritative — just return it; local used as fallback only
    return server;
  }

  // ── Date grouping ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _groupByDate(List<HistoryEntry> entries) {
    if (entries.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<HistoryEntry>>{};

    for (final e in entries) {
      final d = DateTime(e.readAt.year, e.readAt.month, e.readAt.day);
      String label;
      if (d == today)
        label = 'Today';
      else if (d == yesterday)
        label = 'Yesterday';
      else
        label = _formatDate(d);

      groups.putIfAbsent(label, () => []).add(e);
    }

    // Return in insertion order (newest group first)
    return groups.entries
        .map((g) => {'label': g.key, 'entries': g.value})
        .toList();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
