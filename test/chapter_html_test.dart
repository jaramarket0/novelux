import 'package:flutter_test/flutter_test.dart';
import 'package:novelux/screen/reading_interface/chapter_html.dart';

void main() {
  test('strips colours, sizes and fonts but keeps emphasis and alignment', () {
    final out = normalizeChapterHtml(
      '<p style="color:#000000; font-size:28px; font-weight:bold; '
      'text-align:center; mso-line-height-rule:exactly">Hi</p>'
      '<p><font color="black" size="7">Big</font> <span>plain</span></p>',
    );
    expect(out, '<p style="font-weight:bold; text-align:center">Hi</p>'
        '<p>Big plain</p>');
  });

  test('collapses empty paragraphs, nbsp and br runs', () {
    final out = normalizeChapterHtml(
      '<p>One</p><p>&nbsp;</p><p><br></p><div> <p></p> </div>'
      '<p>Two<br><br><br>Three&nbsp;&nbsp;words</p>',
    );
    expect(out, '<p>One</p><p>Two<br>Three words</p>');
  });

  test('headings become bold reading-size paragraphs', () {
    expect(normalizeChapterHtml('<h1 style="font-size:40px">Chapter 1</h1>'),
        '<p><strong>Chapter 1</strong></p>');
  });

  test('plain text gets paragraphs and is escaped', () {
    expect(normalizeChapterHtml('Line a\nline b\n\n\n\nIf 1 < 2 & co'),
        '<p>Line a<br>line b</p><p>If 1 &lt; 2 &amp; co</p>');
  });

  test('never edits prose that looks like an attribute', () {
    expect(normalizeChapterHtml('<p>Set size=5 and color=red</p>'),
        '<p>Set size=5 and color=red</p>');
  });
}
