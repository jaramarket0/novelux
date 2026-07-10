import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/me/ReadingScheduleScreen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

class ReadingInterfaceController extends GetxController {
  Rx<List> comments = Rx([]);

  // ── UI visibility ─────────────────────────────────────────────────────────
  final RxBool _showTopBar = false.obs;
  final RxBool _showBottomBar = false.obs;
  final RxBool _showSettings = false.obs;
  final RxBool _showContents = false.obs;
  final RxBool _showListenButton = false.obs;

  // ── Reading settings ──────────────────────────────────────────────────────
  final RxDouble _brightness = 0.5.obs;
  final RxDouble _fontSize = 18.0.obs;
  final RxString _selectedFont = 'Lora'.obs;
  final RxInt _selectedLineSpacing = 2.obs;
  final RxInt _selectedBackground = 4.obs; // default dark
  final RxString _pageFlipEffect = 'Flip'.obs;
  final RxBool _volumeKeyTurning = true.obs;

  // ── Content ───────────────────────────────────────────────────────────────
  final RxString _bookTitle = ''.obs;
  final RxString _currentChapter = 'Chapter 1'.obs;
  final RxInt _coins = 0.obs;
  final RxDouble _readingProgress = 0.0.obs;
  final RxString chapterContent = ''.obs;
  final RxBool isLoadingChapter = false.obs;

  // ── Navigation ────────────────────────────────────────────────────────────
  final RxInt currentChapterNumber = 1.obs;
  final RxInt totalChapters = 0.obs;
  final RxList chapterList = [].obs;
  String? currentStorySlug;

  // ── Offline ───────────────────────────────────────────────────────────────
  Map<int, String>? _offlineContent;
  bool get isOffline => _offlineContent != null && _offlineContent!.isNotEmpty;

  void setOfflineContent(Map<int, String> content) {
    _offlineContent = content;
    if (content.isNotEmpty) {
      totalChapters.value = content.keys.reduce((a, b) => a > b ? a : b);
    }
  }

  // ── Lock state ────────────────────────────────────────────────────────────
  final RxBool isNextChapterLocked = false.obs;
  final RxBool isCurrentChapterLocked = false.obs;
  final RxInt lockedChapterCoinCost = 0.obs;
  final RxBool isUnlocking = false.obs;

  late ScrollController scrollController;

  // ── Reading time tracker ──────────────────────────────────────────────────
  Timer? _readingTimer;
  DateTime? _timerLastFlushed;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get showTopBar => _showTopBar.value;
  bool get showBottomBar => _showBottomBar.value;
  bool get showSettings => _showSettings.value;
  bool get showContents => _showContents.value;
  bool get showListenButton => _showListenButton.value;
  double get brightness => _brightness.value;
  double get fontSize => _fontSize.value;
  String get selectedFont => _selectedFont.value;
  int get selectedLineSpacing => _selectedLineSpacing.value;
  int get selectedBackground => _selectedBackground.value;
  String get pageFlipEffect => _pageFlipEffect.value;
  bool get volumeKeyTurning => _volumeKeyTurning.value;
  String get bookTitle => _bookTitle.value;
  String get currentChapter => _currentChapter.value;
  int get coins => _coins.value;
  double get readingProgress => _readingProgress.value;

  // ── Navigation helpers ────────────────────────────────────────────────────
  bool get hasPrevChapter {
    if (isOffline) return _offlineContent!.containsKey(currentChapterNumber.value - 1);
    return currentChapterNumber.value > 1;
  }

  bool get hasNextChapter {
    if (isOffline) return _offlineContent!.containsKey(currentChapterNumber.value + 1);
    if (totalChapters.value > 0) {
      return currentChapterNumber.value < totalChapters.value;
    }
    return chapterList.isNotEmpty &&
        currentChapterNumber.value < chapterList.length;
  }

  String get nextChapterTitle {
    final nextNum = currentChapterNumber.value + 1;
    try {
      final match = chapterList.firstWhere(
        (c) => c['chapter_number'] == nextNum,
      );
      return match['title'] ?? 'Chapter $nextNum';
    } catch (_) {
      return 'Chapter $nextNum';
    }
  }

  String get prevChapterTitle {
    final prevNum = currentChapterNumber.value - 1;
    try {
      final match = chapterList.firstWhere(
        (c) => c['chapter_number'] == prevNum,
      );
      return match['title'] ?? 'Chapter $prevNum';
    } catch (_) {
      return 'Chapter $prevNum';
    }
  }

  // ── Static options ────────────────────────────────────────────────────────
  final List<String> fonts = ['System', 'Modern', 'Assistant', 'Lora'];
  final List<String> pageFlipEffects = [
    'Scroll ↔',
    'Scroll ↕',
    'Flip',
    'Animate',
  ];

  final List<Color> backgroundColors = [
    const Color(0xFFFFF2D4), // 0 Sepia
    const Color(0xFFFFFFFF), // 1 White
    const Color(0xFFE8F5E8), // 2 Green
    const Color(0xFFE3F2FD), // 3 Blue
    const Color(0xFF1a1a1a), // 4 Dark (default)
    const Color(0xFFFFE4EC), // 5 Pink
  ];

  final RxList<Chapter> chapters = <Chapter>[].obs;


  @override
  void onInit() {
    super.onInit();
    // Keep screen awake while reading
    WakelockPlus.enable().catchError((_) {});
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    // Release wakelock and restore system brightness
    WakelockPlus.disable().catchError((_) {});
    ScreenBrightness().resetScreenBrightness().catchError((_) {});
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }
    final max = scrollController.position.maxScrollExtent;
    final cur = scrollController.offset;
    _readingProgress.value = max > 0 ? cur / max : 0.0;
  }

  // ── Volume key page turn ──────────────────────────────────────────────────
  void handleVolumeKey(RawKeyEvent event) {
    if (!_volumeKeyTurning.value) {
      return;
    }
    if (event is! RawKeyDownEvent) {
      return;
    }
    if (!scrollController.hasClients) {
      return;
    }
    final viewport = scrollController.position.viewportDimension;
    final max = scrollController.position.maxScrollExtent;
    final cur = scrollController.offset;
    if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
      scrollController.animateTo(
        (cur + viewport * 0.85).clamp(0.0, max),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
      scrollController.animateTo(
        (cur - viewport * 0.85).clamp(0.0, max),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Load chapter list ─────────────────────────────────────────────────────
  Future<void> loadChapterList(String storySlug) async {
    final all = <dynamic>[];
    int page = 1;
    while (true) {
      final res = await ApiService.getChapters(storySlug, page: page);
      if (!res['success']) break;
      final data = res['data'];
      final list = data is List ? data : (data['results'] ?? []);
      all.addAll(list as List);
      // stop if no more pages
      final hasNext = data is Map &&
          (data['has_next'] == true ||
              (data['next'] != null &&
                  data['next'].toString().isNotEmpty));
      if (!hasNext) break;
      page++;
    }
    chapterList.value = all;
    totalChapters.value = all.length;
    chapters.clear();
    for (final c in all) {
      chapters.add(Chapter(c['title'] ?? 'Chapter ${c['chapter_number']}'));
    }
  }

  // ── Load a specific chapter ───────────────────────────────────────────────
  Future<void> loadChapter(
    String storySlug,
    int chapterNum,
    String? title,
  ) async {
    currentStorySlug = storySlug;
    currentChapterNumber.value = chapterNum;
    _currentChapter.value = title ?? 'Chapter $chapterNum';
    isLoadingChapter.value = true;
    chapterContent.value = '';

    // Use cached offline content when available — no network needed
    if (isOffline) {
      final content = _offlineContent![chapterNum];
      chapterContent.value = content ?? 'Chapter not available offline.';
      isCurrentChapterLocked.value = false;
      isLoadingChapter.value = false;
      if (scrollController.hasClients) scrollController.jumpTo(0);
      _readingProgress.value = 0.0;
      return;
    }

    if (chapterList.isEmpty) {
      await loadChapterList(storySlug);
    }

    final res = await ApiService.getChapter(storySlug, chapterNum);
    isLoadingChapter.value = false;

    if (res['success']) {
      final data = res['data'];
      final locked = data['is_locked'] == true && data['is_unlocked'] != true;
      isCurrentChapterLocked.value = locked;
      if (locked) {
        lockedChapterCoinCost.value = data['coin_cost'] ?? 0;
        chapterContent.value = '';
      } else {
        chapterContent.value = data['content'] ?? '';
      }
      _currentChapter.value = data['title'] ?? title ?? 'Chapter $chapterNum';
      if (data['story'] is Map) {
        _bookTitle.value = data['story']['title'] ?? _bookTitle.value;
      }
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      _readingProgress.value = 0.0;
    } else {
      isCurrentChapterLocked.value = false;
      chapterContent.value = res['error'] ?? 'Failed to load chapter.';
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  Future<void> goNextChapter() async {
    if (!hasNextChapter || currentStorySlug == null) {
      return;
    }
    final nextNum = currentChapterNumber.value + 1;
    if (!isOffline) {
      final nextChapterData = _getChapterData(nextNum);
      if (nextChapterData != null &&
          nextChapterData['is_locked'] == true &&
          nextChapterData['is_unlocked'] != true) {
        isNextChapterLocked.value = true;
        lockedChapterCoinCost.value = nextChapterData['coin_cost'] ?? 0;
        return;
      }
      isNextChapterLocked.value = false;
    }
    await loadChapter(currentStorySlug!, nextNum, nextChapterTitle);
  }

  Map? _getChapterData(int chapterNum) {
    try {
      return chapterList.firstWhere(
        (c) => c['chapter_number'] == chapterNum,
      ) as Map;
    } catch (_) {
      return null;
    }
  }

  /// Spend coins to unlock the next chapter then load it.
  Future<bool> unlockAndLoadNextChapter() async {
    if (currentStorySlug == null) return false;
    isUnlocking.value = true;
    final nextNum = currentChapterNumber.value + 1;
    final res = await ApiService.unlockChapter(currentStorySlug!, nextNum);
    isUnlocking.value = false;
    if (res['success']) {
      // Mark chapter as unlocked in local list so we don't prompt again
      final idx = chapterList.indexWhere(
        (c) => c['chapter_number'] == nextNum,
      );
      if (idx != -1) {
        final updated = Map.from(chapterList[idx] as Map);
        updated['is_locked'] = false;
        chapterList[idx] = updated;
      }
      isNextChapterLocked.value = false;
      Get.find<AuthController>().refreshCoins();
      await loadChapter(currentStorySlug!, nextNum, nextChapterTitle);
      return true;
    }
    return false;
  }

  /// Spend coins to unlock the current (locked) chapter then reload it.
  Future<bool> unlockCurrentChapter() async {
    if (currentStorySlug == null) return false;
    isUnlocking.value = true;
    final num = currentChapterNumber.value;
    final res = await ApiService.unlockChapter(currentStorySlug!, num);
    isUnlocking.value = false;
    if (res['success']) {
      final idx = chapterList.indexWhere((c) => c['chapter_number'] == num);
      if (idx != -1) {
        final updated = Map.from(chapterList[idx] as Map);
        updated['is_locked'] = false;
        chapterList[idx] = updated;
      }
      isCurrentChapterLocked.value = false;
      Get.find<AuthController>().refreshCoins();
      await loadChapter(currentStorySlug!, num, _currentChapter.value);
      return true;
    }
    return false;
  }

  Future<void> goPrevChapter() async {
    if (!hasPrevChapter || currentStorySlug == null) {
      return;
    }    await loadChapter(
      currentStorySlug!,
      currentChapterNumber.value - 1,
      prevChapterTitle,
    );
  }

  // ── UI controls ───────────────────────────────────────────────────────────
  void onScreenTap() {
    if (_showTopBar.value || _showBottomBar.value) {
      hideAllControls();
      return;
    }
    _showTopBar.value = true;
    _showBottomBar.value = true;
    _showListenButton.value = true;
  }

  void hideAllControls() {
    _showTopBar.value = false;
    _showBottomBar.value = false;
    _showSettings.value = false;
    _showContents.value = false;
    _showListenButton.value = false;
  }

  void resetUiState() {
    hideAllControls();
    chapterContent.value = '';
    _readingProgress.value = 0.0;
  }

  void toggleSettings() {
    _showSettings.value = !_showSettings.value;
    if (_showSettings.value) {
      _showContents.value = false;
    }
  }

  void toggleContents() {
    _showContents.value = !_showContents.value;
    if (_showContents.value) {
      _showSettings.value = false;
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  void setBrightness(double v) {
    _brightness.value = v;
    // Apply to actual device screen
    ScreenBrightness().setScreenBrightness(v).catchError((_) {});
  }
  void setFontSize(double v) => _fontSize.value = v;
  void setFont(String f) => _selectedFont.value = f;
  void setLineSpacing(int s) => _selectedLineSpacing.value = s;
  void setBackground(int i) => _selectedBackground.value = i;
  void setPageFlipEffect(String e) => _pageFlipEffect.value = e;
  void toggleVolumeKeyTurning() =>
      _volumeKeyTurning.value = !_volumeKeyTurning.value;

  // ── Theme ─────────────────────────────────────────────────────────────────
  Color get currentBackgroundColor => backgroundColors[selectedBackground];

  Color get currentTextColor {
    switch (selectedBackground) {
      case 0:
        return const Color(0xFF5C3317); // sepia brown
      case 4:
        return const Color(0xFFE8E8E8); // dark mode
      default:
        return const Color(0xFF1a1a1a); // light bgs
    }
  }

  double get currentLineHeight {
    switch (selectedLineSpacing) {
      case 0:
        return 1.2;
      case 1:
        return 1.5;
      case 2:
        return 1.8;
      case 3:
        return 2.2;
      default:
        return 1.8;
    }
  }

  String get progressPercent =>
      '${(_readingProgress.value * 100).toStringAsFixed(0)}%';


  void startReadingTimer() {
    _readingTimer?.cancel();
    _timerLastFlushed = DateTime.now();
    _readingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (Get.isRegistered<ReadingScheduleController>()) {
        Get.find<ReadingScheduleController>().addReadingMinutes(1);
      }
      _timerLastFlushed = DateTime.now();
    });
  }

  void stopReadingTimer() {
    _readingTimer?.cancel();
    _readingTimer = null;
    // Flush partial minute — counts if ≥ 30 s have elapsed since last full tick
    if (_timerLastFlushed != null) {
      final secs = DateTime.now().difference(_timerLastFlushed!).inSeconds;
      if (secs >= 30 && Get.isRegistered<ReadingScheduleController>()) {
        Get.find<ReadingScheduleController>().addReadingMinutes(1);
      }
      _timerLastFlushed = null;
    }
  }
}

class Chapter {
  final String title;
  final bool isRead;
  Chapter(this.title, {this.isRead = false});
}