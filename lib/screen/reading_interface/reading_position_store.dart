import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Where a reader stopped in a book: the chapter and how far down it.
class ReadingPosition {
  final int chapter;
  final String chapterTitle;

  /// 0.0 = top of the chapter, 1.0 = bottom. A fraction rather than pixels so
  /// it still lands in the right place after a font-size change.
  final double fraction;
  final DateTime savedAt;

  const ReadingPosition({
    required this.chapter,
    required this.chapterTitle,
    required this.fraction,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'c': chapter,
    't': chapterTitle,
    'f': fraction,
    'at': savedAt.millisecondsSinceEpoch,
  };

  static ReadingPosition? fromJson(Object? j) {
    if (j is! Map) return null;
    final c = (j['c'] as num?)?.toInt();
    if (c == null || c < 1) return null;
    return ReadingPosition(
      chapter: c,
      chapterTitle: j['t']?.toString() ?? '',
      fraction: ((j['f'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        (j['at'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

/// Per-book reading positions, kept on the device (works signed out too).
class ReadingPositionStore {
  static const _key = 'reading_positions_v1';
  static const _maxBooks = 200;

  static Future<Map<String, dynamic>> _all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<ReadingPosition?> get(String storySlug) async =>
      ReadingPosition.fromJson((await _all())[storySlug]);

  static Future<void> save(String storySlug, ReadingPosition pos) async {
    final all = await _all()..[storySlug] = pos.toJson();
    if (all.length > _maxBooks) {
      // Forget the books read longest ago
      final oldest =
          all.entries.toList()..sort(
            (a, b) => ((a.value as Map)['at'] as num? ?? 0).compareTo(
              (b.value as Map)['at'] as num? ?? 0,
            ),
          );
      for (final e in oldest.take(all.length - _maxBooks)) {
        all.remove(e.key);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all));
  }
}
