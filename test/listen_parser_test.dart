import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novelux/screen/listen/book_parser.dart';
import 'package:novelux/screen/listen/listen_controller.dart';

Uint8List _zip(Map<String, String> files) {
  final a = Archive();
  files.forEach((name, body) {
    final bytes = utf8.encode(body);
    a.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(a)!);
}

String _words(int n, [String w = 'word']) => List.filled(n, w).join(' ');

void main() {
  test('plain text with chapter headings becomes chapters', () async {
    final txt = 'Chapter 1\n\n${_words(40)}.\n\nMore text here.\n\nChapter 2\n\n${_words(30)}.';
    final book = await parseBookFile(bytes: Uint8List.fromList(utf8.encode(txt)), fileName: 'My_Story.txt');
    expect(book.title, 'My Story');
    expect(book.chapters.map((c) => c.title), ['Chapter 1', 'Chapter 2']);
    expect(book.chapters.first.paragraphs.length, 2);
  });

  test('text without headings is split into parts', () async {
    final paras = List.generate(60, (i) => '${_words(100)}.').join('\n\n'); // 6000 words
    final book = await parseBookFile(bytes: Uint8List.fromList(utf8.encode(paras)), fileName: 'long.txt');
    expect(book.chapters.length, 3);
    expect(book.chapters.first.title, 'Part 1');
  });

  test('html headings start chapters and entities are decoded', () async {
    final html = '<html><head><title>Tale</title><style>p{}</style></head><body>'
        '<h1>One</h1><p>It&rsquo;s ${_words(20)}</p><h1>Two</h1><p>Fish &amp; chips ${_words(20)}</p></body></html>';
    final book = await parseBookFile(bytes: Uint8List.fromList(utf8.encode(html)), fileName: 't.html');
    expect(book.title, 'Tale');
    expect(book.chapters.map((c) => c.title), ['One', 'Two']);
    expect(book.chapters.first.paragraphs.first, startsWith('It’s'));
    expect(book.chapters[1].paragraphs.first, startsWith('Fish & chips'));
  });

  test('epub follows the spine and uses the table of contents', () async {
    final bytes = _zip({
      'META-INF/container.xml':
          '<container><rootfiles><rootfile full-path="OEBPS/content.opf"/></rootfiles></container>',
      'OEBPS/content.opf': '''<package xmlns:dc="http://purl.org/dc/elements/1.1/">
        <metadata><dc:title>The Book</dc:title><dc:creator>Ada</dc:creator></metadata>
        <manifest>
          <item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>
          <item id="c1" href="text/c1.xhtml" media-type="application/xhtml+xml"/>
          <item id="c2" href="text/c2.xhtml" media-type="application/xhtml+xml"/>
          <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
        </manifest>
        <spine><itemref idref="cover"/><itemref idref="c2"/><itemref idref="c1"/></spine></package>''',
      'OEBPS/toc.ncx': '''<ncx><navMap>
        <navPoint><navLabel><text>The Beginning</text></navLabel><content src="text/c2.xhtml"/></navPoint>
        </navMap></ncx>''',
      'OEBPS/cover.xhtml': '<html><body><img src="c.jpg"/></body></html>',
      'OEBPS/text/c1.xhtml': '<html><body><h2>Later</h2><p>${_words(30)}</p></body></html>',
      'OEBPS/text/c2.xhtml': '<html><body><p>${_words(30)}</p></body></html>',
    });
    final book = await parseBookFile(bytes: bytes, fileName: 'x.epub');
    expect((book.title, book.author), ('The Book', 'Ada'));
    expect(book.chapters.map((c) => c.title), ['The Beginning', 'Later']);
  });

  test('docx headings and paragraphs', () async {
    final bytes = _zip({
      'word/document.xml': '''<w:document xmlns:w="w"><w:body>
        <w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Start</w:t></w:r></w:p>
        <w:p><w:r><w:t>${_words(15)}</w:t></w:r><w:r><w:t xml:space="preserve"> more</w:t></w:r></w:p>
        <w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>End</w:t></w:r></w:p>
        <w:p><w:r><w:t>${_words(15)}</w:t></w:r></w:p>
      </w:body></w:document>''',
    });
    final book = await parseBookFile(bytes: bytes, fileName: 'Draft.docx');
    expect(book.chapters.map((c) => c.title), ['Start', 'End']);
    expect(book.chapters.first.paragraphs.single, endsWith('word more'));
  });

  test('unsupported and empty files give friendly errors', () async {
    expect(
      () => parseBookFile(bytes: Uint8List(4), fileName: 'k.mobi'),
      throwsA(isA<BookParseException>().having((e) => e.message, 'message', contains('EPUB'))),
    );
    expect(
      () => parseBookFile(bytes: Uint8List.fromList(utf8.encode('hi')), fileName: 'a.txt'),
      throwsA(isA<BookParseException>()),
    );
  });

  test('sentences split on punctuation and long ones are cut', () {
    expect(
      ListenPlayerController.sentencesOf('Hello there. “Who is it?” she asked. 3 cats came.'),
      ['Hello there.', '“Who is it?” she asked.', '3 cats came.'],
    );
    expect(ListenPlayerController.sentencesOf('Mr. smith went home.').length, 1);
    final long = List.filled(120, 'word').join(' '); // ~600 chars, no punctuation
    final parts = ListenPlayerController.sentencesOf(long);
    expect(parts.length, greaterThan(1));
    expect(parts.every((p) => p.length <= 320), isTrue);
    expect(parts.join(' '), long);
  });
}
