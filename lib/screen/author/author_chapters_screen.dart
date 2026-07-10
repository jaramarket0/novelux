import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';
import 'dart:developer' as myLog;

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class AuthorChaptersController extends GetxController {
  final String storySlug;
  final String storyTitle;
  AuthorChaptersController({required this.storySlug, required this.storyTitle});

  final RxBool isLoading = false.obs;
  final RxList chapters = [].obs;
  final RxString error = ''.obs;
  final RxInt wordCount = 0.obs;
  final RxMap<String, dynamic> chapter = Map<String, dynamic>().obs;

  @override
  void onInit() {
    super.onInit();
    fetchChapters();
  }

  Future<void> fetchChapters() async {
    isLoading.value = true;
    error.value = '';
    final res = await ApiService.getChapters(storySlug);
    myLog.log(res.toString());
    isLoading.value = false;
    if (res['success']) {
      final data = res['data'];
      final list = data is List ? data : (data['results'] ?? []);
      final sorted = List.from(list);
      sorted.sort(
        (a, b) =>
            (a['chapter_number'] ?? 0).compareTo(b['chapter_number'] ?? 0),
      );
      chapters.value = sorted;
    } else {
      error.value = res['error'] ?? 'Failed to load chapters';
    }
  }

  Future<void> fetchChapter(int chapterNum) async {
    isLoading.value = true;
    error.value = '';
    final res = await ApiService.getChapter(storySlug, chapterNum);
    myLog.log(res.toString());
    isLoading.value = false;
    if (res['success']) {
      final data = res['data'];
      myLog.log('$data ================ raw data');
      chapter.value = data as Map<String, dynamic>;
      // Seed word count from existing content
      final content = cleanText(chapter['content'] ?? '');
      wordCount.value =
          content.trim().isEmpty
              ? 0
              : content.trim().split(RegExp(r'\s+')).length;
    } else {
      error.value = res['error'] ?? 'Failed to load chapter';
    }
  }

  Future<void> updateChapter(
    int chapterNumber,
    Map<String, dynamic> data, {
    bool publish = false,
  }) async {
    final payload = {...data, if (publish) 'is_publish': true};
    final res = await ApiService.updateChapter(storySlug, chapterNumber, payload);
    if (res['success']) {
      await fetchChapters();
      Get.back();
      final resData = res['data'] as Map? ?? {};
      final status = resData['status'] as String? ?? '';
      if (status == 'in_review' || status == 'pending_review') {
        AppAlert.success('Submitted for review — Your chapter will go live once the SE approves it.');
      } else if (status == 'published') {
        AppAlert.success('Chapter Published — Now live on the platform.');
      } else {
        AppAlert.success('Chapter Updated — Changes saved successfully.');
      }
    } else {
      AppAlert.error(res['error'] ?? 'Failed to update chapter');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AuthorChaptersScreen extends StatefulWidget {
  final String storySlug;
  final String storyTitle;
  const AuthorChaptersScreen({
    super.key,
    required this.storySlug,
    required this.storyTitle,
  });

  @override
  State<AuthorChaptersScreen> createState() => _AuthorChaptersScreenState();
}

class _AuthorChaptersScreenState extends State<AuthorChaptersScreen> {
  late AuthorChaptersController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(
      AuthorChaptersController(
        storySlug: widget.storySlug,
        storyTitle: widget.storyTitle,
      ),
      tag: widget.storySlug,
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
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;
        
        return Scaffold(
          backgroundColor: const Color(0xFF1a1a1a),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1a1a1a),
            leading: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Get.back(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapters',
                  style: TextStyle(
                    color: txt,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.storyTitle,
                  style: TextStyle(color: sub, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            elevation: 0,
          ),
          body: Obx(() {
            if (ctrl.isLoading.value) {
              return Center(
                child: Container(
                  height: 130,
                  width: 130,
                  decoration: BoxDecoration(
                    color: divClr,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SpinKitWanderingCubes(
                    itemBuilder:
                        (context, index) => DecoratedBox(
                          decoration: BoxDecoration(
                            color: index.isEven ? depperBlue : Colors.white,
                            shape: BoxShape.rectangle,
                          ),
                        ),
                    size: 30,
                    duration: const Duration(milliseconds: 1200),
                  ),
                ),
              );
            }
            if (ctrl.error.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ctrl.error.value,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: ctrl.fetchChapters,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (ctrl.chapters.isEmpty) {
              return const Center(
                child: Text(
                  'No chapters yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: ctrl.fetchChapters,
              color: depperBlue,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: ctrl.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = ctrl.chapters[index] as Map<String, dynamic>;
                  return _ChapterTile(
                    chapter: chapter,
                    onEdit:
                        () => ctrl
                            .fetchChapter(chapter['chapter_number'])
                            .then(
                              (_) =>
                                  _showEditSheet(context, ctrl, ctrl.chapter),
                            ),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }

  void _showEditSheet(
    BuildContext ctx,
    AuthorChaptersController ctrl,
    RxMap<String, dynamic> chapter,
  ) {
    myLog.log('calling the sheet');
    myLog.log(chapter.toString());

    final titleCtrl = TextEditingController(
      text: cleanText(chapter['title'] ?? ''),
    );
    final contentCtrl = TextEditingController(
      text: cleanText(chapter['content'] ?? ''),
    );
    final coinCtrl = TextEditingController(
      text: (chapter['coin_cost'] ?? 20).toString(),
    );
    final isLocked = RxBool(chapter['is_locked'] == true);
    final isSaving = RxBool(false);
    final error = RxString('');

    showModalBottomSheet(
      isDismissible: true,
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.93,
            maxChildSize: 0.97,
            builder:
                (_, sc) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
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
                      Text(
                        'Edit Chapter ${chapter['chapter_number']}',
                        style: const TextStyle(
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
                            _formField(
                              'Chapter Title',
                              titleCtrl,
                              'Enter title',
                            ),
                            const SizedBox(height: 16),
                            // Content field — passes onChanged to update ctrl.wordCount
                            _formField(
                              'Content',
                              contentCtrl,
                              'Write your chapter here...\n\nPress Enter twice to start a new paragraph.',
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              onChanged: (val) {
                                final trimmed = val.trim();
                                ctrl.wordCount.value =
                                    trimmed.isEmpty
                                        ? 0
                                        : trimmed.split(RegExp(r'\s+')).length;
                              },
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Obx(
                                  () => Text(
                                    '${ctrl.wordCount.value} words',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${chapter['estimated_read_minutes']} min read',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Updated: ${formatChapterDate(chapter['updated_at'] ?? '')}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
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
                                        child: _formField(
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
                              () => Column(
                                children: [
                                  SizedBox(
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
                                          isSaving.value
                                              ? null
                                              : () async {
                                                if (titleCtrl.text.trim().isEmpty ||
                                                    contentCtrl.text.trim().isEmpty) {
                                                  error.value = 'Title and content are required';
                                                  return;
                                                }
                                                isSaving.value = true;
                                                error.value = '';
                                                await ctrl.updateChapter(
                                                  chapter['chapter_number'],
                                                  {
                                                    'title': titleCtrl.text.trim(),
                                                    'content': textToHtml(contentCtrl.text),
                                                    'is_locked': isLocked.value,
                                                    'coin_cost': int.tryParse(coinCtrl.text) ?? 20,
                                                  },
                                                );
                                                isSaving.value = false;
                                              },
                                      child:
                                          isSaving.value
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                              : const Text(
                                                'Save Draft',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed:
                                          isSaving.value
                                              ? null
                                              : () async {
                                                if (titleCtrl.text.trim().isEmpty ||
                                                    contentCtrl.text.trim().isEmpty) {
                                                  error.value = 'Title and content are required';
                                                  return;
                                                }
                                                isSaving.value = true;
                                                error.value = '';
                                                await ctrl.updateChapter(
                                                  chapter['chapter_number'],
                                                  {
                                                    'title': titleCtrl.text.trim(),
                                                    'content': textToHtml(contentCtrl.text),
                                                    'is_locked': isLocked.value,
                                                    'coin_cost': int.tryParse(coinCtrl.text) ?? 20,
                                                  },
                                                  publish: true,
                                                );
                                                isSaving.value = false;
                                              },
                                      child: const Text(
                                        'Publish',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  String formatChapterDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString).toLocal();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);
      if (difference.inMinutes < 60) {
        if (difference.inMinutes <= 1) return 'Just now';
        return '${difference.inMinutes} mins ago';
      }
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      if (difference.inDays < 7)
        return DateFormat('E, hh:mm a').format(dateTime);
      return DateFormat.yMMMd().format(dateTime);
    } catch (_) {
      return 'Recently';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterTile extends StatelessWidget {
  final Map chapter;
  final VoidCallback onEdit;
  const _ChapterTile({required this.chapter, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isLocked = chapter['is_locked'] == true;
    final chNum = chapter['chapter_number'] ?? '';
    final title = chapter['title'] ?? 'Chapter $chNum';
    final coinCost = chapter['coin_cost'] ?? 0;
    final isPublished = chapter['is_published'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: depperBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$chNum',
              style: TextStyle(
                color: depperBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (isLocked) ...[
              const Icon(Icons.lock_outline, size: 11, color: Colors.orange),
              const SizedBox(width: 3),
              Text(
                '$coinCost coins',
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isPublished
                        ? Colors.green.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPublished ? 'Published' : 'Draft',
                style: TextStyle(
                  color: isPublished ? Colors.green : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: depperBlue, size: 20),
          tooltip: 'Edit chapter',
          onPressed: onEdit,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Converts stored HTML to plain text for the editor.
/// Paragraph breaks → double newlines; <br> → single newline; other tags stripped.
String cleanText(String html) {
  return html
      .replaceAll(RegExp(r'<p[^>]*>'), '')
      .replaceAll('</p>', '\n\n')
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Converts plain text back to HTML for storage.
/// Double newlines → <p> tags; single newlines within a block → <br>.
String textToHtml(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '';
  return trimmed
      .split(RegExp(r'\n{2,}'))
      .where((p) => p.trim().isNotEmpty)
      .map((p) => '<p>${p.trim().replaceAll('\n', '<br>')}</p>')
      .join('');
}

Widget _formField(
  String label,
  TextEditingController ctrl,
  String hint, {
  int? maxLines = 1,
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
      minLines: maxLines == null ? 14 : null,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.6,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF333333),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  ],
);
