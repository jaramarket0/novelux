import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ad_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/reading_interface/ambient_sound.dart';

import 'book_parser.dart';
import 'listen_controller.dart';
import 'listen_library.dart';
import 'listen_player_screen.dart';

/// Shared colours for the Listen screens, following the app's light/dark theme.
class ListenColors {
  final bool dark;
  ListenColors(BuildContext context)
    : dark = Theme.of(context).brightness == Brightness.dark;

  Color get bg => dark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
  Color get card => dark ? const Color(0xFF212324) : Colors.white;
  Color get text => dark ? Colors.white : const Color(0xFF1a1a1a);
  Color get sub => dark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get divider => dark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;
}

String formatDuration(Duration d) {
  if (d.inHours > 0) return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
  if (d.inMinutes > 0) return '${d.inMinutes} min';
  return '${d.inSeconds} s';
}

/// "Listen to your books": import any book file and have it read aloud.
class ListenHomeScreen extends StatefulWidget {
  const ListenHomeScreen({super.key});

  @override
  State<ListenHomeScreen> createState() => _ListenHomeScreenState();
}

class _ListenHomeScreenState extends State<ListenHomeScreen> {
  late final ListenLibraryController lib;
  late final ListenPlayerController player;
  bool _createdAmbient = false;

  @override
  void initState() {
    super.initState();
    lib = Get.put(ListenLibraryController());
    player = Get.put(ListenPlayerController());
    _createdAmbient = !Get.isRegistered<AmbientSoundController>();
  }

  @override
  void dispose() {
    // Leaving the Listen section stops playback (and any background sound
    // started from here).
    Get.delete<ListenPlayerController>();
    Get.delete<ListenLibraryController>();
    if (_createdAmbient && Get.isRegistered<AmbientSoundController>()) {
      Get.delete<AmbientSoundController>();
    }
    super.dispose();
  }

  Future<void> _openBook(ListenBook b) async {
    final ok = await player.open(b);
    if (!ok || !mounted) return;
    AdService.instance.onListenBookOpened();
    Get.to(() => const ListenPlayerScreen(), transition: Transition.downToUp);
  }

  Future<void> _import() async {
    final book = await lib.importBook();
    if (book != null) _openBook(book);
  }

  @override
  Widget build(BuildContext context) {
    final c = ListenColors(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.text),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Listen',
              style: TextStyle(
                color: depperBlue,
                fontFamily: kFontFamily,
                fontSize: 20,
              ),
            ),
            Text(
              'Your own books, read aloud',
              style: TextStyle(color: c.sub, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Obx(
            () => PopupMenuButton<String>(
              tooltip: 'Sort',
              icon: Icon(LucideIcons.arrowUpDown, color: c.text, size: 20),
              initialValue: lib.sort.value,
              onSelected: lib.setSort,
              itemBuilder:
                  (_) => const [
                    PopupMenuItem(value: 'recent', child: Text('Recently listened')),
                    PopupMenuItem(value: 'added', child: Text('Recently added')),
                    PopupMenuItem(value: 'title', child: Text('Title A–Z')),
                  ],
            ),
          ),
          IconButton(
            tooltip: 'Supported files',
            icon: Icon(LucideIcons.info, color: c.text, size: 20),
            onPressed: () => _showFormats(context, c),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          backgroundColor: depperBlue,
          foregroundColor: Colors.white,
          onPressed: lib.importing.value ? null : _import,
          icon: const Icon(LucideIcons.filePlus2),
          label: const Text('Import book'),
        ),
      ),
      body: Column(
        children: [
          Obx(
            () =>
                lib.importing.value
                    ? Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: depperBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lib.importStatus.value,
                              style: TextStyle(color: c.text, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
          _nowPlaying(c),
          Expanded(
            child: Obx(() {
              if (lib.loading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: depperBlue),
                );
              }
              final books = lib.sortedBooks;
              if (books.isEmpty) return _empty(c);
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _bookCard(books[i], c),
              );
            }),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _nowPlaying(ListenColors c) => Obx(() {
    final b = player.book.value;
    if (b == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Get.to(() => const ListenPlayerScreen(), transition: Transition.downToUp),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: depperBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: depperBlue.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            BookCover(book: b, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    player.chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.sub, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: player.togglePlay,
              icon: Icon(
                player.isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: depperBlue,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  });

  Widget _empty(ListenColors c) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
    children: [
      Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: depperBlue.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.headphones, color: depperBlue, size: 44),
      ),
      const SizedBox(height: 20),
      Text(
        'Turn any book into an audiobook',
        textAlign: TextAlign.center,
        style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        'Import a book you have on your phone and listen while you cook, commute or rest. '
        'Choose the voice and speed, follow along with the highlighted text, set a sleep '
        'timer and pick up where you left off.',
        textAlign: TextAlign.center,
        style: TextStyle(color: c.sub, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 20),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final f in ['EPUB', 'PDF', 'DOCX', 'TXT', 'HTML', 'ODT', 'FB2', 'RTF', 'MD'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(f, style: TextStyle(color: c.text, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Center(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: depperBlue,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          onPressed: _import,
          icon: const Icon(LucideIcons.filePlus2, size: 18),
          label: const Text('Import a book'),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.lock, size: 12, color: c.sub),
          const SizedBox(width: 6),
          Text(
            'Your files stay on this phone — nothing is uploaded.',
            style: TextStyle(color: c.sub, fontSize: 11),
          ),
        ],
      ),
    ],
  );

  Widget _bookCard(ListenBook b, ListenColors c) {
    final minutes = (b.wordCount / ListenPlayerController.wordsPerMinute).round();
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openBook(b),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(book: b, size: 62),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (b.author.isNotEmpty)
                      Text(
                        b.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.sub, fontSize: 12),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${b.chapterTitles.length} chapters · about ${formatDuration(Duration(minutes: minutes))}'
                      '${b.bookmarks.isNotEmpty ? ' · ${b.bookmarks.length} bookmark${b.bookmarks.length == 1 ? '' : 's'}' : ''}',
                      style: TextStyle(color: c.sub, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: b.progress,
                              minHeight: 4,
                              color: depperBlue,
                              backgroundColor: c.divider,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          b.finished ? 'Finished' : '${(b.progress * 100).round()}%',
                          style: TextStyle(color: c.sub, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: c.sub),
                onSelected: (v) {
                  if (v == 'rename') _rename(b);
                  if (v == 'info') _info(b, c);
                  if (v == 'delete') _delete(b);
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'info', child: Text('Book info')),
                      PopupMenuItem(value: 'delete', child: Text('Remove')),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(ListenBook b) async {
    final title = TextEditingController(text: b.title);
    final author = TextEditingController(text: b.author);
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Edit book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: author, decoration: const InputDecoration(labelText: 'Author')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) await lib.renameBook(b, title.text, author.text);
  }

  void _info(ListenBook b, ListenColors c) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.title, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final row in [
              ['Author', b.author.isEmpty ? '—' : b.author],
              ['Format', b.format],
              ['Chapters', '${b.chapterTitles.length}'],
              ['Words', '${b.wordCount}'],
              ['Listening time', 'about ${formatDuration(Duration(minutes: (b.wordCount / ListenPlayerController.wordsPerMinute).round()))} at 1×'],
              ['Added', '${b.addedAt.day}/${b.addedAt.month}/${b.addedAt.year}'],
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(row[0], style: TextStyle(color: c.sub, fontSize: 13))),
                    Expanded(child: Text(row[1], style: TextStyle(color: c.text, fontSize: 13))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(ListenBook b) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove book?'),
        content: Text('"${b.title}" and its bookmarks will be removed from Listen. '
            'The original file on your phone is not touched.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    if (player.book.value?.id == b.id) {
      await player.pause();
      player.book.value = null;
    }
    await lib.deleteBook(b);
  }

  void _showFormats(BuildContext context, ListenColors c) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supported files', style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              '${listenSupportedExtensions.map((e) => e.toUpperCase()).join(', ')}.\n\n'
              'Scanned PDFs (pictures of pages), DRM-protected books and Kindle files '
              '(MOBI/AZW) can\'t be read aloud — convert Kindle books to EPUB first.\n\n'
              'Voices come from your phone. For more or better voices, install them in '
              'your phone\'s text-to-speech settings.',
              style: TextStyle(color: c.sub, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// A generated cover: a colour from the title, initials and the file type.
class BookCover extends StatelessWidget {
  final ListenBook book;
  final double size;
  const BookCover({super.key, required this.book, required this.size});

  static const _palette = [
    [Color(0xFFC15F3C), Color(0xFF7A2E17)],
    [Color(0xFF3C6EC1), Color(0xFF1B3A78)],
    [Color(0xFF3CA37A), Color(0xFF1C5E44)],
    [Color(0xFF8E44AD), Color(0xFF4A235A)],
    [Color(0xFFD4A017), Color(0xFF7D5E0A)],
    [Color(0xFF2C3E50), Color(0xFF111A24)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palette[book.title.hashCode.abs() % _palette.length];
    final words = book.title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.take(2).map((w) => w.characters.first.toUpperCase()).join();
    return Container(
      width: size * 0.72,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.1),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.06,
            left: 0,
            right: 0,
            child: Text(
              book.format,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: size * 0.11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
