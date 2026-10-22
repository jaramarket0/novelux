import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import 'book_parser.dart';

/// A bookmark at a paragraph of a chapter.
class ListenBookmark {
  final int chapter;
  final int paragraph;
  final String snippet;
  final DateTime createdAt;

  ListenBookmark({
    required this.chapter,
    required this.paragraph,
    required this.snippet,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'c': chapter,
    'p': paragraph,
    's': snippet,
    'at': createdAt.toIso8601String(),
  };

  factory ListenBookmark.fromJson(Map m) => ListenBookmark(
    chapter: (m['c'] as num?)?.toInt() ?? 0,
    paragraph: (m['p'] as num?)?.toInt() ?? 0,
    snippet: m['s']?.toString() ?? '',
    createdAt: DateTime.tryParse(m['at']?.toString() ?? '') ?? DateTime.now(),
  );
}

/// An imported book's details and where the reader got to. The text itself
/// lives in a separate file, loaded only when the book is opened.
class ListenBook {
  final String id;
  String title;
  String author;
  final String format;
  final DateTime addedAt;
  DateTime? lastOpenedAt;
  final int wordCount;
  final List<String> chapterTitles;
  final List<int> chapterWords;
  int chapter;
  int paragraph;
  bool finished;
  final List<ListenBookmark> bookmarks;

  ListenBook({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.addedAt,
    required this.wordCount,
    required this.chapterTitles,
    required this.chapterWords,
    this.lastOpenedAt,
    this.chapter = 0,
    this.paragraph = 0,
    this.finished = false,
    List<ListenBookmark>? bookmarks,
  }) : bookmarks = bookmarks ?? [];

  /// Share of the book's words before the current position (0–1).
  double get progress {
    if (finished) return 1;
    if (wordCount == 0 || chapterWords.isEmpty) return 0;
    final before = chapterWords.take(chapter).fold<int>(0, (a, b) => a + b);
    return (before / wordCount).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'format': format,
    'added': addedAt.toIso8601String(),
    'opened': lastOpenedAt?.toIso8601String(),
    'words': wordCount,
    'ct': chapterTitles,
    'cw': chapterWords,
    'c': chapter,
    'p': paragraph,
    'done': finished,
    'bm': [for (final b in bookmarks) b.toJson()],
  };

  factory ListenBook.fromJson(Map m) => ListenBook(
    id: m['id'].toString(),
    title: m['title']?.toString() ?? 'Untitled',
    author: m['author']?.toString() ?? '',
    format: m['format']?.toString() ?? '',
    addedAt: DateTime.tryParse(m['added']?.toString() ?? '') ?? DateTime.now(),
    lastOpenedAt: DateTime.tryParse(m['opened']?.toString() ?? ''),
    wordCount: (m['words'] as num?)?.toInt() ?? 0,
    chapterTitles: [for (final t in (m['ct'] as List? ?? const [])) t.toString()],
    chapterWords: [for (final w in (m['cw'] as List? ?? const [])) (w as num).toInt()],
    chapter: (m['c'] as num?)?.toInt() ?? 0,
    paragraph: (m['p'] as num?)?.toInt() ?? 0,
    finished: m['done'] == true,
    bookmarks: [
      for (final b in (m['bm'] as List? ?? const []))
        if (b is Map) ListenBookmark.fromJson(b),
    ],
  );
}

/// Books are kept in the app's own private folder (no storage permission):
///   listen_books/index.json   — the list of books
///   `listen_books/{id}.json`  — each book's chapters
class ListenLibraryStore {
  ListenLibraryStore._();
  static final ListenLibraryStore instance = ListenLibraryStore._();

  Directory? _dir;

  Future<Directory> _folder() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory('${docs.path}/listen_books');
    if (!await d.exists()) await d.create(recursive: true);
    return _dir = d;
  }

  Future<List<ListenBook>> loadBooks() async {
    try {
      final f = File('${(await _folder()).path}/index.json');
      if (!await f.exists()) return [];
      final list = jsonDecode(await f.readAsString()) as List;
      return [for (final m in list) if (m is Map) ListenBook.fromJson(m)];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBooks(List<ListenBook> books) async {
    final dir = await _folder();
    final tmp = File('${dir.path}/index.json.tmp');
    await tmp.writeAsString(jsonEncode([for (final b in books) b.toJson()]));
    await tmp.rename('${dir.path}/index.json'); // atomic replace
  }

  Future<ListenBook> addBook(ParsedBook parsed, String format) async {
    final id =
        '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9999)}';
    final dir = await _folder();
    await File('${dir.path}/$id.json').writeAsString(
      jsonEncode([for (final c in parsed.chapters) c.toJson()]),
    );
    return ListenBook(
      id: id,
      title: parsed.title,
      author: parsed.author,
      format: format.toUpperCase(),
      addedAt: DateTime.now(),
      wordCount: parsed.wordCount,
      chapterTitles: [for (final c in parsed.chapters) c.title],
      chapterWords: [for (final c in parsed.chapters) c.wordCount],
    );
  }

  Future<List<ParsedChapter>> loadChapters(String id) async {
    final f = File('${(await _folder()).path}/$id.json');
    final list = jsonDecode(await f.readAsString()) as List;
    return [for (final m in list) if (m is Map) ParsedChapter.fromJson(m)];
  }

  Future<void> deleteBook(String id) async {
    try {
      await File('${(await _folder()).path}/$id.json').delete();
    } catch (_) {}
  }
}
