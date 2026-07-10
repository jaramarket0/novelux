import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ad_service.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/me/vip_screen.dart';
import 'package:novelux/widgets/download_gate_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as myLog;

// ── Models ────────────────────────────────────────────────────────────────────
class DownloadedChapter {
  final int number;
  final String title;
  final String content;
  final int wordCount;

  DownloadedChapter({
    required this.number,
    required this.title,
    required this.content,
  }) : wordCount =
           content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'content': content,
  };

  factory DownloadedChapter.fromJson(Map<String, dynamic> j) =>
      DownloadedChapter(
        number: j['number'] as int? ?? 1,
        title: j['title']?.toString() ?? '',
        content: j['content']?.toString() ?? '',
      );
}

class DownloadedStory {
  final String slug;
  final String title;
  final String author;
  final String coverUrl;
  final List<DownloadedChapter> chapters;
  final DateTime downloadedAt;

  const DownloadedStory({
    required this.slug,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.chapters,
    required this.downloadedAt,
  });

  int get totalWords => chapters.fold(0, (s, c) => s + c.wordCount);
  int get readMinutes => (totalWords / 200).ceil();

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'downloadedAt': downloadedAt.toIso8601String(),
    'chapters': chapters.map((c) => c.toJson()).toList(),
  };

  factory DownloadedStory.fromJson(Map<String, dynamic> j) => DownloadedStory(
    slug: j['slug']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    author: j['author']?.toString() ?? '',
    coverUrl: j['coverUrl']?.toString() ?? '',
    downloadedAt:
        DateTime.tryParse(j['downloadedAt']?.toString() ?? '') ??
        DateTime.now(),
    chapters:
        (j['chapters'] as List? ?? [])
            .map(
              (c) => DownloadedChapter.fromJson(Map<String, dynamic>.from(c)),
            )
            .toList(),
  );
}

// ── Controller ────────────────────────────────────────────────────────────────
class DownloadController extends GetxController {
  final RxBool isMarked = false.obs;
  final RxBool isAllSelected = false.obs;
  final RxList<DownloadedStory> downloads = <DownloadedStory>[].obs;
  final RxSet<String> selected = <String>{}.obs;
  final RxMap<String, double> progress = <String, double>{}.obs;
  final RxMap<String, String> downloadStatus = <String, String>{}.obs;
  // 'idle' | 'downloading' | 'done' | 'error'

  static const _kKey = 'nux_downloads_v2';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  // ── Persistence ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      downloads.value =
          list
              .map(
                (e) => DownloadedStory.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
    } catch (e) {
      downloads.value = [];
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode(downloads.map((d) => d.toJson()).toList()),
    );
  }

  // ── Status helpers ───────────────────────────────────────────────────────
  bool isDownloaded(String slug) => downloads.any((d) => d.slug == slug);

  String statusOf(String slug) =>
      downloadStatus[slug] ?? (isDownloaded(slug) ? 'done' : 'idle');

  DownloadedStory? getOffline(String slug) =>
      downloads.where((d) => d.slug == slug).firstOrNull;

  // ── Download ─────────────────────────────────────────────────────────────
  static const int coinCost = 120;

  /// Entry point for the download buttons: shows the gate dialog
  /// (rewarded ad with countdown / pay coins / cancel), then downloads.
  /// VIP subscribers skip the gate entirely; exclusive stories are
  /// downloadable by VIPs only.
  Future<void> requestDownload({
    required String slug,
    required String title,
    required String author,
    required String coverUrl,
    bool isExclusive = false,
  }) async {
    if (isDownloaded(slug)) {
      AppAlert.info('Already saved — "$title" is already available offline');
      return;
    }
    if (downloadStatus[slug] == 'downloading') return;

    final auth = Get.find<AuthController>();

    // Exclusive stories: offline download is a VIP perk (backend enforces
    // this too — the flag here just gives a nicer prompt)
    if (isExclusive && !auth.isVip) {
      _showVipRequiredDialog(title);
      return;
    }

    // VIP: downloads are included with the subscription — no gate
    if (auth.isVip) {
      await _performDownload(
        slug: slug, title: title, author: author, coverUrl: coverUrl,
        method: 'ad',
      );
      return;
    }

    final method = await Get.dialog<String>(
      DownloadGateDialog(storyTitle: title, coinCost: coinCost),
      barrierDismissible: false,
    );
    if (method == null) return; // cancelled

    if (method == 'ad') {
      final ads = AdService.instance;
      if (!ads.isRewardedReady) {
        AppAlert.error(
          'Ad not available right now — please try again in a moment.',
        );
        return;
      }
      bool earned = false;
      final shown = await ads.showRewarded(onRewarded: (_) => earned = true);
      if (!shown || !earned) {
        AppAlert.info('Watch the full ad to unlock the download.');
        return;
      }
    } else if (method == 'coins') {
      if (auth.coins < coinCost) {
        AppAlert.warning(
          'Not enough coins — you need $coinCost coins for this download.',
        );
        return;
      }
    }

    await _performDownload(
      slug: slug, title: title, author: author, coverUrl: coverUrl,
      method: method,
    );

    // Coin balance changed server-side — refresh the profile
    if (method == 'coins') auth.fetchMe();
  }

  /// Prompt shown when a non-VIP tries to download an exclusive story.
  void _showVipRequiredDialog(String title) {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF232220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium,
                  color: Color(0xFFF5D9A8), size: 42),
              const SizedBox(height: 14),
              const Text(
                'Exclusive story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$title" is a NoveluX exclusive — offline download is '
                'included with a VIP subscription.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5D9A8),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    Get.to(() => const VipScreen());
                  },
                  child: const Text(
                    '👑 Get VIP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              TextButton(
                onPressed: Get.back,
                child: const Text(
                  'Not now',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fetches the full story (every published chapter, full content) in one
  /// call and saves it for offline reading.
  Future<void> _performDownload({
    required String slug,
    required String title,
    required String author,
    required String coverUrl,
    required String method,
  }) async {
    downloadStatus[slug] = 'downloading';
    progress[slug] = 0.1;

    AppAlert.info('⬇ Downloading — Saving "$title" for offline reading...');

    try {
      final res = await ApiService.downloadStoryOffline(slug, method);
      if (res['success'] != true) {
        // Surface the backend's reason (e.g. "exclusive — requires VIP",
        // "Insufficient coins") instead of a generic connection error
        downloadStatus[slug] = 'error';
        progress.remove(slug);
        AppAlert.error(
          res['error']?.toString() ?? 'Download failed — please try again.',
        );
        return;
      }

      progress[slug] = 0.6;

      final chapList = res['data']['chapters'] as List? ?? [];
      if (chapList.isEmpty) throw Exception('No chapters found');

      final downloaded = <DownloadedChapter>[
        for (final ch in chapList)
          DownloadedChapter(
            number: ch['chapter_number'] as int? ?? 1,
            title: ch['title']?.toString() ?? '',
            content: ch['content']?.toString() ?? '',
          ),
      ];
      myLog.log('Downloaded ${downloaded.length} chapters of "$title"');

      final story = DownloadedStory(
        slug: slug,
        title: title,
        author: author,
        coverUrl: coverUrl,
        chapters: downloaded,
        downloadedAt: DateTime.now(),
      );

      downloads.add(story);
      await _persist();

      downloadStatus[slug] = 'done';
      progress.remove(slug);

      AppAlert.success('✅ Download complete! — "$title" — ${downloaded.length} chapters · ${story.readMinutes} min read');
    } catch (e) {
      downloadStatus[slug] = 'error';
      progress.remove(slug);
      myLog.log('Download failed: $e');
      AppAlert.error('Download failed — Could not download "$title". Check your connection.');
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────
  Future<void> deleteDownload(String slug) async {
    downloads.removeWhere((d) => d.slug == slug);
    downloadStatus.remove(slug);
    await _persist();
    AppAlert.info('Deleted — Removed from downloads');
  }

  Future<void> deleteSelected() async {
    for (final slug in selected) {
      downloadStatus.remove(slug);
    }
    downloads.removeWhere((d) => selected.contains(d.slug));
    selected.clear();
    isMarked.value = false;
    await _persist();
  }

  void toggleSelect(String slug) {
    if (selected.contains(slug))
      selected.remove(slug);
    else
      selected.add(slug);
  }

  void selectAll() => selected.addAll(downloads.map((d) => d.slug));

  void clearSelection() {
    selected.clear();
    isMarked.value = false;
  }
}
