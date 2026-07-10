import 'dart:convert';
import 'dart:developer' as myLog;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContinueReadingController extends GetxController {
  static ContinueReadingController get to => Get.find();

  final RxString storyTitle = ''.obs;
  final RxString storySlug = ''.obs;
  final RxString coverUrl = ''.obs;
  final RxInt chapterNumber = 0.obs;
  final RxString chapterTitle = ''.obs;

  final RxBool hasData = false.obs;
  final RxBool isBannerVisible = false.obs;

  static const _prefKey = 'continue_reading_v1';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      storyTitle.value = m['title']?.toString() ?? '';
      storySlug.value = m['slug']?.toString() ?? '';
      coverUrl.value = m['cover']?.toString() ?? '';
      chapterNumber.value = (m['chapter'] as num?)?.toInt() ?? 0;
      chapterTitle.value = m['chapterTitle']?.toString() ?? '';
      if (storySlug.value.isNotEmpty) {
        hasData.value = true;
        isBannerVisible.value = true;
        myLog.log(
          'ContinueReadingController: loaded saved state: '
          '${storyTitle.value} / ${storySlug.value} ch:${chapterNumber.value} banner:${isBannerVisible.value}',
        );
      }
    } catch (_) {}
  }

  Future<void> saveLastRead({
    required String title,
    required String slug,
    required String cover,
    required int chapter,
    required String chapterTitle,
  }) async {
    storyTitle.value = title;
    storySlug.value = slug;
    coverUrl.value = cover;
    chapterNumber.value = chapter;
    this.chapterTitle.value = chapterTitle;
    hasData.value = true;
    isBannerVisible.value = true;
    myLog.log(
      'ContinueReadingController: saveLastRead -> '
      '${storyTitle.value} / ${storySlug.value} ch:${chapterNumber.value} banner:${isBannerVisible.value}',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode({
        'title': title,
        'slug': slug,
        'cover': cover,
        'chapter': chapter,
        'chapterTitle': chapterTitle,
      }),
    );
  }

  Future<void> dismiss() async {
    hasData.value = false;
    isBannerVisible.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    myLog.log('ContinueReadingController: dismiss called');
  }

  void showBanner() {
    if (hasData.value) isBannerVisible.value = true;
    myLog.log(
      'ContinueReadingController: showBanner -> ${isBannerVisible.value}',
    );
  }

  void hideBanner() {
    isBannerVisible.value = false;
    myLog.log(
      'ContinueReadingController: hideBanner -> ${isBannerVisible.value}',
    );
  }
}
