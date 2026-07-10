import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/download_screen/controller/download_controller.dart';
import 'package:novelux/screen/reading_interface/reading_interface.dart';
import 'package:novelux/widgets/custom_image_view.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(DownloadController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F7);
    final card = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Obx(
          () =>
              ctrl.isMarked.value
                  ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: ctrl.clearSelection,
                  )
                  : IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: txt,
                      size: 28,
                    ),
                    onPressed: () => Get.back(),
                  ),
        ),
        title: Obx(
          () =>
              ctrl.isMarked.value
                  ? Text(
                    '${ctrl.selected.length} selected',
                    style: TextStyle(color: txt, fontSize: 16),
                  )
                  : Text(
                    'Downloads',
                    style: TextStyle(
                      color: txt,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
        actions: [
          Obx(
            () =>
                ctrl.isMarked.value
                    ? Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.select_all,
                            color: Colors.grey,
                          ),
                          onPressed: ctrl.selectAll,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmDelete(context, ctrl),
                        ),
                      ],
                    )
                    : IconButton(
                      icon: Icon(
                        Icons.playlist_add_check_rounded,
                        color: txt,
                        size: 26,
                      ),
                      onPressed: () => ctrl.isMarked.value = true,
                    ),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.downloads.isEmpty) {
          return _emptyState(isDark, txt);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: ctrl.downloads.length,
          itemBuilder:
              (_, i) => _DownloadCard(
                story: ctrl.downloads[i],
                ctrl: ctrl,
                card: card,
                txt: txt,
                isDark: isDark,
              ),
        );
      }),
    );
  }

  Widget _emptyState(bool isDark, Color txt) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.download_for_offline_outlined,
          color: Colors.grey[600],
          size: 72,
        ),
        const SizedBox(height: 20),
        Text(
          'No downloads yet',
          style: TextStyle(
            color: txt,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Save stories to read offline anytime',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Text(
          'Tap ⬇ on any story to download it',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    ),
  );

  void _confirmDelete(BuildContext context, DownloadController ctrl) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF2a2a2a),
            title: const Text(
              'Delete downloads?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Remove ${ctrl.selected.length} story(ies) from offline storage?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Get.back();
                  ctrl.deleteSelected();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadedStory story;
  final DownloadController ctrl;
  final Color card, txt;
  final bool isDark;
  const _DownloadCard({
    required this.story,
    required this.ctrl,
    required this.card,
    required this.txt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => ctrl.isMarked.value = true,
      onTap: () {
        if (ctrl.isMarked.value) {
          ctrl.toggleSelect(story.slug);
        } else if (story.chapters.isNotEmpty) {
          final ch = story.chapters.first;
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder:
                  (_) => NovelUpReadingInterface(
                    storySlug: story.slug,
                    storyTitle: story.title,
                    chapterNumber: ch.number,
                    chapterTitle: ch.title,
                    coverUrl: story.coverUrl,
                    offlineContent: Map.fromEntries(
                      story.chapters.map((c) => MapEntry(c.number, c.content)),
                    ),
                  ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Obx(
              () =>
                  ctrl.isMarked.value
                      ? GestureDetector(
                        onTap: () => ctrl.toggleSelect(story.slug),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10, top: 6),
                          child: Obx(
                            () => Icon(
                              ctrl.selected.contains(story.slug)
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: depperBlue,
                              size: 22,
                            ),
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),

            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 76,
                height: 104,
                child:
                    story.coverUrl.isNotEmpty
                        ? CustomImageView(
                          imagePath: story.coverUrl,
                          fit: BoxFit.cover,
                        )
                        : 
                        // Container(
                        //   color: const Color(0xFF2A2A2A),
                        //   child: const Center(
                        //     child: Icon(
                        //       Icons.book,
                        //       color: Colors.grey,
                        //       size: 32,
                        //     ),
                        //   ),
                        // ),
                        CustomImageView(
                      imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    story.title,
                    style: TextStyle(
                      color: txt,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (story.author.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      story.author,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip(
                        Icons.menu_book_outlined,
                        '${story.chapters.length} ch',
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        Icons.access_time_outlined,
                        '~${story.readMinutes} min',
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        Icons.text_snippet_outlined,
                        '${(story.totalWords / 1000).toStringAsFixed(1)}k words',
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.offline_bolt_rounded,
                          color: Colors.green,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Offline ready',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // More menu
            Obx(
              () =>
                  ctrl.isMarked.value
                      ? const SizedBox.shrink()
                      : PopupMenuButton<int>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        color: const Color(0xFF2a2a2a),
                        itemBuilder:
                            (_) => [
                              const PopupMenuItem(
                                value: 0,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Read',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        onSelected: (v) {
                          if (v == 1) ctrl.deleteDownload(story.slug);
                          if (v == 0 && story.chapters.isNotEmpty) {
                            final ch = story.chapters.first;
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder:
                                    (_) => NovelUpReadingInterface(
                                      storySlug: story.slug,
                                      storyTitle: story.title,
                                      chapterNumber: ch.number,
                                      chapterTitle: ch.title,
                                      coverUrl: story.coverUrl,
                                      offlineContent: Map.fromEntries(
                                        story.chapters.map(
                                          (c) => MapEntry(c.number, c.content),
                                        ),
                                      ),
                                    ),
                              ),
                            );
                          }
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF3a3a3a) : const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey, size: 11),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    ),
  );
}
