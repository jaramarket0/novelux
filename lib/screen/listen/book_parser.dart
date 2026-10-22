import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:xml/xml.dart';

/// Formats the importer understands.
const listenSupportedExtensions = [
  'txt', 'md', 'markdown', 'html', 'htm', 'xhtml', 'epub', 'docx', 'odt',
  'fb2', 'rtf', 'pdf',
];

/// Common book formats we can't read, with a friendly reason.
const listenUnsupportedHints = {
  'mobi': 'Kindle MOBI files are not supported — convert to EPUB first (e.g. with Calibre).',
  'azw': 'Kindle files are not supported — convert to EPUB first (e.g. with Calibre).',
  'azw3': 'Kindle files are not supported — convert to EPUB first (e.g. with Calibre).',
  'kfx': 'Kindle files are not supported — convert to EPUB first (e.g. with Calibre).',
  'doc': 'Old Word .doc files are not supported — save it as .docx and try again.',
  'pages': 'Pages files are not supported — export as EPUB, DOCX or PDF.',
  'cbz': 'Comic archives contain images, not text, so they can\'t be read aloud.',
  'cbr': 'Comic archives contain images, not text, so they can\'t be read aloud.',
};

class ParsedChapter {
  final String title;
  final List<String> paragraphs;
  ParsedChapter(this.title, this.paragraphs);

  Map<String, dynamic> toJson() => {'t': title, 'p': paragraphs};
  factory ParsedChapter.fromJson(Map m) => ParsedChapter(
    m['t']?.toString() ?? '',
    [for (final p in (m['p'] as List? ?? const [])) p.toString()],
  );

  int get wordCount =>
      paragraphs.fold(0, (n, p) => n + _wordRe.allMatches(p).length);
}

class ParsedBook {
  final String title;
  final String author;
  final List<ParsedChapter> chapters;
  ParsedBook(this.title, this.author, this.chapters);

  int get wordCount => chapters.fold(0, (n, c) => n + c.wordCount);
}

class BookParseException implements Exception {
  final String message;
  BookParseException(this.message);
  @override
  String toString() => message;
}

final _wordRe = RegExp(r"[\p{L}\p{N}']+", unicode: true);

/// Parses a book file. Heavy text work runs off the UI thread; PDFs use the
/// PDFium engine, which does its own background work.
Future<ParsedBook> parseBookFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  final baseTitle = _titleFromFileName(fileName);
  if (listenUnsupportedHints.containsKey(ext)) {
    throw BookParseException(listenUnsupportedHints[ext]!);
  }
  if (!listenSupportedExtensions.contains(ext)) {
    throw BookParseException('".$ext" files are not supported yet.');
  }

  ParsedBook book;
  if (ext == 'pdf') {
    book = await _parsePdf(bytes, baseTitle);
  } else {
    book = await compute(_parseInIsolate, _ParseJob(bytes, ext, baseTitle));
  }
  if (book.wordCount < 20) {
    throw BookParseException(
      ext == 'pdf'
          ? 'No readable text found. Scanned PDFs (pictures of pages) can\'t be read aloud.'
          : 'No readable text found in this file.',
    );
  }
  return book;
}

class _ParseJob {
  final Uint8List bytes;
  final String ext;
  final String title;
  _ParseJob(this.bytes, this.ext, this.title);
}

ParsedBook _parseInIsolate(_ParseJob job) {
  switch (job.ext) {
    case 'txt':
      return _fromParagraphs(job.title, '', _textParagraphs(_decodeText(job.bytes)));
    case 'md':
    case 'markdown':
      return _parseMarkdown(_decodeText(job.bytes), job.title);
    case 'html':
    case 'htm':
    case 'xhtml':
      final html = _decodeText(job.bytes);
      final t = _htmlTitle(html);
      return _fromBlocks(t.isNotEmpty ? t : job.title, '', htmlToBlocks(html));
    case 'epub':
      return _parseEpub(job.bytes, job.title);
    case 'docx':
      return _parseDocx(job.bytes, job.title);
    case 'odt':
      return _parseOdt(job.bytes, job.title);
    case 'fb2':
      return _parseFb2(_decodeText(job.bytes), job.title);
    case 'rtf':
      return _fromParagraphs(job.title, '', _textParagraphs(_rtfToText(_decodeText(job.bytes))));
  }
  throw BookParseException('Unsupported file.');
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _titleFromFileName(String name) {
  var t = name.replaceAll(RegExp(r'\.[^.]+$'), '');
  t = t.replaceAll(RegExp(r'[_]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.isEmpty ? 'Untitled book' : t;
}

String _decodeText(Uint8List bytes) {
  // Strip a UTF-8 BOM; fall back to Latin-1 for legacy files
  var b = bytes;
  if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
    b = b.sublist(3);
  }
  if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) {
    final codes = <int>[];
    for (var i = 2; i + 1 < b.length; i += 2) {
      codes.add(b[i] | (b[i + 1] << 8));
    }
    return String.fromCharCodes(codes);
  }
  try {
    return utf8.decode(b);
  } catch (_) {
    return latin1.decode(b, allowInvalid: true);
  }
}

String _clean(String s) => s
    .replaceAll('\u00A0', ' ')
    .replaceAll(RegExp(r'[ \t\r\f\v]+'), ' ')
    .trim();

/// Plain text → paragraphs. Blank lines separate paragraphs; if the file has
/// none, each line is a paragraph.
List<String> _textParagraphs(String text) {
  text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final hasBlankLines = RegExp(r'\n[ \t]*\n').hasMatch(text);
  final parts = hasBlankLines ? text.split(RegExp(r'\n[ \t]*\n')) : text.split('\n');
  return [
    for (final p in parts)
      if (_clean(p.replaceAll('\n', ' ')).isNotEmpty) _clean(p.replaceAll('\n', ' ')),
  ];
}

const _entities = {
  'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' ',
  'rsquo': '’', 'lsquo': '‘', 'rdquo': '”', 'ldquo': '“', 'mdash': '—',
  'ndash': '–', 'hellip': '…', 'copy': '©', 'reg': '®', 'trade': '™',
  'eacute': 'é', 'egrave': 'è', 'aacute': 'á', 'agrave': 'à', 'oacute': 'ó',
  'uacute': 'ú', 'iacute': 'í', 'ntilde': 'ñ', 'ccedil': 'ç', 'uuml': 'ü',
  'ouml': 'ö', 'auml': 'ä', 'szlig': 'ß', 'laquo': '«', 'raquo': '»',
};

String unescapeHtml(String s) => s.replaceAllMapped(
  RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'),
  (m) {
    final e = m[1]!;
    if (e.startsWith('#x')) {
      return String.fromCharCode(int.tryParse(e.substring(2), radix: 16) ?? 32);
    }
    if (e.startsWith('#')) {
      return String.fromCharCode(int.tryParse(e.substring(1)) ?? 32);
    }
    return _entities[e.toLowerCase()] ?? m[0]!;
  },
);

/// A block of text from HTML, marked when it's a heading.
class TextBlock {
  final String text;
  final bool heading;
  TextBlock(this.text, {this.heading = false});
}

String _htmlTitle(String html) {
  final m = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true)
      .firstMatch(html);
  return m == null ? '' : _clean(unescapeHtml(m[1]!.replaceAll(RegExp(r'<[^>]+>'), '')));
}

/// HTML/XHTML → text blocks (paragraphs and headings).
List<TextBlock> htmlToBlocks(String html) {
  var s = html;
  s = s.replaceAll(RegExp(r'<head[\s\S]*?</head>', caseSensitive: false), ' ');
  s = s.replaceAll(RegExp(r'<(script|style|svg)[\s\S]*?</\1>', caseSensitive: false), ' ');
  s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
  // Mark headings so they can start chapters
  s = s.replaceAllMapped(
    RegExp(r'<h([1-3])[^>]*>([\s\S]*?)</h\1>', caseSensitive: false),
    (m) => '\n\n\u0001${m[2]!.replaceAll(RegExp(r'<[^>]+>'), ' ')}\n\n',
  );
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(
    RegExp(r'</?(p|div|li|h[4-6]|blockquote|tr|section|article|pre|dd|dt)[^>]*>', caseSensitive: false),
    '\n\n',
  );
  s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
  s = unescapeHtml(s);
  final out = <TextBlock>[];
  for (final raw in s.split(RegExp(r'\n\s*\n'))) {
    final heading = raw.contains('\u0001');
    final text = _clean(raw.replaceAll('\u0001', '').replaceAll('\n', ' '));
    if (text.isNotEmpty) out.add(TextBlock(text, heading: heading));
  }
  return out;
}

final _headingRe = RegExp(
  r'^(chapter|chap\.|part|book|prologue|epilogue|interlude|section|act)\b[\s\S]{0,70}$|^[IVXLC]{1,7}\.?$|^\d{1,3}\.?$',
  caseSensitive: false,
);

const _targetWords = 2500; // size of auto-made parts when there are no chapters
const _maxWords = 6000; // longer chapters are split so the text view stays light

/// Paragraphs with no structure → chapters, using "Chapter 3"-style headings
/// when the text has them, otherwise parts of about 2,500 words.
ParsedBook _fromParagraphs(String title, String author, List<String> paragraphs) {
  final blocks = [
    for (final p in paragraphs) TextBlock(p, heading: p.length <= 80 && _headingRe.hasMatch(p)),
  ];
  return _fromBlocks(title, author, blocks);
}

ParsedBook _fromBlocks(String title, String author, List<TextBlock> blocks) {
  final headings = blocks.where((b) => b.heading).length;
  final chapters = <ParsedChapter>[];
  if (headings >= 2) {
    var current = ParsedChapter('', []);
    for (final b in blocks) {
      if (b.heading) {
        if (current.paragraphs.isNotEmpty) chapters.add(current);
        current = ParsedChapter(b.text, []);
      } else {
        current.paragraphs.add(b.text);
      }
    }
    if (current.paragraphs.isNotEmpty) chapters.add(current);
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i].title.isEmpty) {
        chapters[i] = ParsedChapter(i == 0 ? 'Opening' : 'Chapter ${i + 1}', chapters[i].paragraphs);
      }
    }
  } else {
    chapters.addAll(_chunk([for (final b in blocks) b.text], 'Part'));
  }
  return ParsedBook(title, author, _splitLong(chapters));
}

List<ParsedChapter> _chunk(List<String> paragraphs, String label) {
  final out = <ParsedChapter>[];
  var cur = <String>[];
  var words = 0;
  for (final p in paragraphs) {
    cur.add(p);
    words += _wordRe.allMatches(p).length;
    if (words >= _targetWords) {
      out.add(ParsedChapter('$label ${out.length + 1}', cur));
      cur = [];
      words = 0;
    }
  }
  if (cur.isNotEmpty) out.add(ParsedChapter('$label ${out.length + 1}', cur));
  return out;
}

List<ParsedChapter> _splitLong(List<ParsedChapter> chapters) {
  final out = <ParsedChapter>[];
  for (final c in chapters) {
    if (c.wordCount <= _maxWords) {
      out.add(c);
      continue;
    }
    final parts = _chunk(c.paragraphs, '');
    for (var i = 0; i < parts.length; i++) {
      out.add(ParsedChapter(i == 0 ? c.title : '${c.title} (${i + 1})', parts[i].paragraphs));
    }
  }
  return out;
}

// ── Markdown ─────────────────────────────────────────────────────────────────

ParsedBook _parseMarkdown(String md, String title) {
  final blocks = <TextBlock>[];
  for (final para in md.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'))) {
    var p = para.trim();
    if (p.isEmpty || RegExp(r'^(```|---|\*\*\*|___)').hasMatch(p)) continue;
    final heading = RegExp(r'^#{1,3}\s').hasMatch(p);
    p = p
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
        .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
        .replaceAll(RegExp(r'[*_`>]+'), '')
        .replaceAll(RegExp(r'^\s*[-+]\s+', multiLine: true), '')
        .replaceAll('\n', ' ');
    p = _clean(p);
    if (p.isNotEmpty) blocks.add(TextBlock(p, heading: heading));
  }
  return _fromBlocks(title, '', blocks);
}

// ── EPUB ─────────────────────────────────────────────────────────────────────

ArchiveFile? _zipFile(Archive a, String path) {
  final norm = path.replaceAll('\\', '/');
  for (final f in a.files) {
    if (f.name == norm || Uri.decodeFull(f.name) == norm) return f;
  }
  final lower = norm.toLowerCase();
  for (final f in a.files) {
    if (f.name.toLowerCase() == lower) return f;
  }
  return null;
}

String _zipText(Archive a, String path) {
  final f = _zipFile(a, path);
  if (f == null) return '';
  return _decodeText(Uint8List.fromList(f.content as List<int>));
}

String _resolve(String base, String href) {
  final clean = Uri.decodeFull(href.split('#').first);
  final dir = base.contains('/') ? base.substring(0, base.lastIndexOf('/') + 1) : '';
  final parts = <String>[];
  for (final seg in '$dir$clean'.split('/')) {
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (seg != '.' && seg.isNotEmpty) {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

Iterable<XmlElement> _byLocal(XmlNode n, String local) =>
    n.descendants.whereType<XmlElement>().where((e) => e.name.local == local);

ParsedBook _parseEpub(Uint8List bytes, String fallbackTitle) {
  final Archive zip;
  try {
    zip = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw BookParseException('This EPUB file is damaged or protected.');
  }
  if (_zipFile(zip, 'META-INF/encryption.xml') != null &&
      _zipText(zip, 'META-INF/encryption.xml').contains('EncryptedData')) {
    throw BookParseException('This EPUB is DRM-protected, so it can\'t be read aloud.');
  }
  final container = XmlDocument.parse(_zipText(zip, 'META-INF/container.xml'));
  final opfPath = _byLocal(container, 'rootfile').first.getAttribute('full-path') ?? '';
  final opf = XmlDocument.parse(_zipText(zip, opfPath));

  final title = _byLocal(opf, 'title').map((e) => _clean(e.innerText)).firstWhere(
        (t) => t.isNotEmpty, orElse: () => fallbackTitle);
  final author = _byLocal(opf, 'creator').map((e) => _clean(e.innerText)).firstWhere(
        (t) => t.isNotEmpty, orElse: () => '');

  final manifest = <String, String>{};
  for (final item in _byLocal(opf, 'item')) {
    final id = item.getAttribute('id');
    final href = item.getAttribute('href');
    if (id != null && href != null) manifest[id] = _resolve(opfPath, href);
  }

  // Chapter names from the table of contents (EPUB 2 NCX or EPUB 3 nav)
  final tocTitles = <String, String>{};
  try {
    for (final item in _byLocal(opf, 'item')) {
      final href = item.getAttribute('href') ?? '';
      final media = item.getAttribute('media-type') ?? '';
      final props = item.getAttribute('properties') ?? '';
      final path = _resolve(opfPath, href);
      if (media == 'application/x-dtbncx+xml') {
        final ncx = XmlDocument.parse(_zipText(zip, path));
        for (final np in _byLocal(ncx, 'navPoint')) {
          final label = _byLocal(np, 'text').map((e) => _clean(e.innerText)).firstOrNull;
          final src = _byLocal(np, 'content').firstOrNull?.getAttribute('src');
          if (label != null && src != null) tocTitles.putIfAbsent(_resolve(path, src), () => label);
        }
      } else if (props.contains('nav')) {
        final nav = _zipText(zip, path);
        for (final m in RegExp(r'<a[^>]*href="([^"]+)"[^>]*>([\s\S]*?)</a>', caseSensitive: false)
            .allMatches(nav)) {
          final label = _clean(unescapeHtml(m[2]!.replaceAll(RegExp(r'<[^>]+>'), ' ')));
          if (label.isNotEmpty) tocTitles.putIfAbsent(_resolve(path, m[1]!), () => label);
        }
      }
    }
  } catch (_) {}

  final chapters = <ParsedChapter>[];
  for (final ref in _byLocal(opf, 'itemref')) {
    final path = manifest[ref.getAttribute('idref')];
    if (path == null) continue;
    final blocks = htmlToBlocks(_zipText(zip, path));
    final paras = [for (final b in blocks) b.text];
    final words = paras.fold<int>(0, (n, p) => n + _wordRe.allMatches(p).length);
    if (words < 15) continue; // cover, title page, blank separators
    var name = tocTitles[path] ?? '';
    if (name.isEmpty) {
      final h = blocks.where((b) => b.heading).firstOrNull;
      name = h?.text ?? 'Chapter ${chapters.length + 1}';
    }
    // Don't read the heading twice when it's also the first paragraph
    if (paras.isNotEmpty && paras.first.toLowerCase() == name.toLowerCase() && paras.length > 1) {
      paras.removeAt(0);
    }
    chapters.add(ParsedChapter(name, paras));
  }
  return ParsedBook(title, author, _splitLong(chapters));
}

// ── DOCX / ODT ───────────────────────────────────────────────────────────────

ParsedBook _parseDocx(Uint8List bytes, String fallbackTitle) {
  final zip = ZipDecoder().decodeBytes(bytes);
  final doc = XmlDocument.parse(_zipText(zip, 'word/document.xml'));
  var title = fallbackTitle;
  var author = '';
  try {
    final core = XmlDocument.parse(_zipText(zip, 'docProps/core.xml'));
    title = _byLocal(core, 'title').map((e) => _clean(e.innerText)).firstWhere(
          (t) => t.isNotEmpty, orElse: () => fallbackTitle);
    author = _byLocal(core, 'creator').map((e) => _clean(e.innerText)).firstOrNull ?? '';
  } catch (_) {}

  final blocks = <TextBlock>[];
  for (final p in _byLocal(doc, 'p')) {
    if (p.name.prefix != 'w') continue;
    final buf = StringBuffer();
    for (final n in p.descendants.whereType<XmlElement>()) {
      switch (n.name.local) {
        case 't':
          buf.write(n.innerText);
        case 'tab':
          buf.write(' ');
        case 'br':
        case 'cr':
          buf.write(' ');
      }
    }
    final text = _clean(buf.toString());
    if (text.isEmpty) continue;
    final style = _byLocal(p, 'pStyle').firstOrNull?.getAttribute('w:val') ?? '';
    final heading = RegExp(r'^(heading[123]|title)$', caseSensitive: false).hasMatch(style) ||
        (text.length <= 80 && _headingRe.hasMatch(text));
    blocks.add(TextBlock(text, heading: heading));
  }
  return _fromBlocks(title, author, blocks);
}

ParsedBook _parseOdt(Uint8List bytes, String title) {
  final zip = ZipDecoder().decodeBytes(bytes);
  final doc = XmlDocument.parse(_zipText(zip, 'content.xml'));
  final blocks = <TextBlock>[];
  for (final e in doc.descendants.whereType<XmlElement>()) {
    if (e.name.prefix != 'text' || (e.name.local != 'p' && e.name.local != 'h')) continue;
    final text = _clean(e.innerText);
    if (text.isNotEmpty) blocks.add(TextBlock(text, heading: e.name.local == 'h'));
  }
  return _fromBlocks(title, '', blocks);
}

// ── FB2 / RTF ────────────────────────────────────────────────────────────────

ParsedBook _parseFb2(String xml, String fallbackTitle) {
  final doc = XmlDocument.parse(xml);
  final title = _byLocal(doc, 'book-title').map((e) => _clean(e.innerText)).firstWhere(
        (t) => t.isNotEmpty, orElse: () => fallbackTitle);
  final a = _byLocal(doc, 'author').firstOrNull;
  final author = a == null
      ? ''
      : _clean(['first-name', 'middle-name', 'last-name']
          .map((n) => _byLocal(a, n).firstOrNull?.innerText ?? '')
          .join(' '));
  final blocks = <TextBlock>[];
  for (final body in _byLocal(doc, 'body')) {
    for (final e in body.descendants.whereType<XmlElement>()) {
      if (e.name.local == 'title') {
        blocks.add(TextBlock(_clean(e.innerText), heading: true));
      } else if (e.name.local == 'p' &&
          !e.ancestors.whereType<XmlElement>().any((x) => x.name.local == 'title')) {
        final t = _clean(e.innerText);
        if (t.isNotEmpty) blocks.add(TextBlock(t));
      }
    }
  }
  return _fromBlocks(title, author, blocks);
}

String _rtfToText(String rtf) {
  var s = rtf;
  // Drop destination groups ({\*\...}, font tables, colour tables, pictures)
  s = s.replaceAll(RegExp(r'\{\\\*[^{}]*\}'), '');
  for (final g in ['fonttbl', 'colortbl', 'stylesheet', 'info', 'pict']) {
    s = s.replaceAll(RegExp('\\{\\\\$g[\\s\\S]*?\\}\\}?'), '');
  }
  s = s.replaceAll(RegExp(r'\\par[d]?\b ?'), '\n\n');
  s = s.replaceAll(RegExp(r'\\line\b ?'), '\n');
  s = s.replaceAllMapped(RegExp(r"\\'([0-9a-fA-F]{2})"),
      (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)));
  s = s.replaceAllMapped(RegExp(r'\\u(-?\d+)\??'), (m) {
    var c = int.parse(m[1]!);
    if (c < 0) c += 65536;
    return String.fromCharCode(c);
  });
  s = s.replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), '');
  s = s.replaceAll(RegExp(r'[{}]'), '');
  return s;
}

// ── PDF ──────────────────────────────────────────────────────────────────────

Future<ParsedBook> _parsePdf(Uint8List bytes, String title) async {
  await pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  PdfDocument doc;
  try {
    doc = await PdfDocument.openData(bytes);
  } catch (_) {
    throw BookParseException('This PDF can\'t be opened — it may be damaged or password-protected.');
  }
  try {
    final pages = <String>[];
    for (final page in doc.pages) {
      final text = await page.loadText();
      pages.add(text?.fullText ?? '');
    }
    return compute(_pdfPagesToBook, _PdfJob(pages, title));
  } finally {
    await doc.dispose();
  }
}

class _PdfJob {
  final List<String> pages;
  final String title;
  _PdfJob(this.pages, this.title);
}

/// PDF text comes as hard-wrapped lines. Re-join them into paragraphs:
/// a line ending a sentence that's noticeably shorter than a full line ends a
/// paragraph; everything else continues it. Page numbers and repeated
/// headers are dropped.
ParsedBook _pdfPagesToBook(_PdfJob job) {
  final lineCounts = <String, int>{};
  final pageLines = <List<String>>[];
  for (final p in job.pages) {
    final lines = [
      for (final l in p.replaceAll('\r', '\n').split('\n'))
        if (_clean(l).isNotEmpty) _clean(l),
    ];
    pageLines.add(lines);
    for (final l in {...lines.take(2), ...lines.skip(lines.length > 2 ? lines.length - 2 : 0)}) {
      lineCounts[l] = (lineCounts[l] ?? 0) + 1;
    }
  }
  final repeated = job.pages.length >= 4
      ? {for (final e in lineCounts.entries) if (e.value >= job.pages.length * 0.5) e.key}
      : <String>{};

  final all = <String>[];
  for (final lines in pageLines) {
    for (final l in lines) {
      if (repeated.contains(l)) continue;
      if (RegExp(r'^(page\s*)?\d{1,4}(\s*(of|/)\s*\d+)?$', caseSensitive: false).hasMatch(l)) continue;
      all.add(l);
    }
  }
  if (all.isEmpty) return ParsedBook(job.title, '', []);
  final lengths = [for (final l in all) l.length]..sort();
  final typical = lengths[(lengths.length * 0.8).floor().clamp(0, lengths.length - 1)];

  final blocks = <TextBlock>[];
  final buf = StringBuffer();
  void flush() {
    final t = _clean(buf.toString());
    if (t.isNotEmpty) blocks.add(TextBlock(t, heading: t.length <= 80 && _headingRe.hasMatch(t)));
    buf.clear();
  }

  for (final l in all) {
    if (l.length <= 80 && _headingRe.hasMatch(l)) {
      flush();
      buf.write(l);
      flush();
      continue;
    }
    if (buf.isNotEmpty) {
      final prev = buf.toString();
      if (prev.endsWith('-') && !prev.endsWith(' -')) {
        // Hyphenated word broken across lines
        final joined = prev.substring(0, prev.length - 1);
        buf
          ..clear()
          ..write(joined)
          ..write(l);
        continue;
      }
      buf.write(' ');
    }
    buf.write(l);
    final endsSentence = RegExp(r'[.!?…:"”’)]$').hasMatch(l);
    if (endsSentence && l.length < typical * 0.85) flush();
  }
  flush();
  return _fromBlocks(job.title, '', blocks);
}
