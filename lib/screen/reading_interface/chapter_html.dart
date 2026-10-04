// Normalises chapter HTML so the reader's own settings (theme colours, font
// size, line height) always win over whatever the author's editor pasted in.
//
// Chapters come from a rich-text editor and often carry Word/Docs leftovers:
//   • inline `color:#000` / `background:#fff`  → black text on the dark theme
//   • inline `font-size`, <font size>, <h1>     → text far bigger than the setting
//   • <p>&nbsp;</p>, <br><br><br>, margins      → large random gaps
//   • plain-text chapters with blank lines       → no paragraphs at all

/// Inline style properties the reader controls itself. Everything else
/// (bold, italic, underline, alignment) is kept.
const _readerOwnedProps = {
  'color',
  'background',
  'background-color',
  'font-size',
  'font-family',
  'font',
  'line-height',
  'letter-spacing',
  'word-spacing',
  'margin',
  'margin-top',
  'margin-bottom',
  'margin-left',
  'margin-right',
  'padding',
  'padding-top',
  'padding-bottom',
  'padding-left',
  'padding-right',
  'text-indent',
  'white-space',
  'width',
  'height',
  'min-height',
};

final _styleAttr = RegExp(
  r'''\sstyle\s*=\s*("([^"]*)"|'([^']*)')''',
  caseSensitive: false,
);
final _presentationAttrs = RegExp(
  r'''\s(?:color|bgcolor|face|size|class)\s*=\s*("[^"]*"|'[^']*'|[^\s>]+)''',
  caseSensitive: false,
);
final _openTag = RegExp(r'<[a-zA-Z][^>]*>');
final _fontTag = RegExp(r'</?font\b[^>]*>', caseSensitive: false);
final _spanTag = RegExp(
  r'<span\s*>(.*?)</span>',
  caseSensitive: false,
  dotAll: true,
);
final _heading = RegExp(r'<(/?)h[1-6]\b[^>]*>', caseSensitive: false);
final _nbsp = RegExp(r'(&nbsp;|\u00A0)+', caseSensitive: false);
final _brRun = RegExp(r'(\s*<br\s*/?>\s*){2,}', caseSensitive: false);
final _emptyBlock = RegExp(
  r'<(p|div)\b[^>]*>(\s|<br\s*/?>|&nbsp;|\u00A0)*</\1>',
  caseSensitive: false,
);
final _blankLines = RegExp(r'\n\s*\n+');
final _knownTag = RegExp(
  r'</?(p|br|div|span|strong|b|em|i|u|h[1-6]|font|ul|ol|li|blockquote|a|img|hr)\b',
  caseSensitive: false,
);

String normalizeChapterHtml(String raw) {
  var html = raw.trim();
  if (html.isEmpty) return html;

  // Plain-text chapter: blank lines are paragraph breaks, single newlines
  // are soft breaks.
  if (!_knownTag.hasMatch(html)) {
    return html
        .split(_blankLines)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => '<p>${_escape(p).replaceAll('\n', '<br>')}</p>')
        .join();
  }

  // Attribute clean-up only ever touches the inside of opening tags
  html = html.replaceAllMapped(_openTag, (t) => _cleanTag(t.group(0)!));

  html = html
      .replaceAll(_fontTag, '')
      .replaceAllMapped(_spanTag, (m) => m.group(1)!)
      // Headings inside a chapter become bold paragraphs at reading size
      .replaceAllMapped(
        _heading,
        (m) => m.group(1)!.isEmpty ? '<p><strong>' : '</strong></p>',
      )
      .replaceAll(_nbsp, ' ')
      .replaceAll(_brRun, '<br>');

  // Repeat: removing one empty block can expose its now-empty parent
  String prev;
  do {
    prev = html;
    html = html.replaceAll(_emptyBlock, '');
  } while (html != prev);

  return html.trim();
}

String _cleanTag(String tag) => tag
    .replaceAllMapped(_styleAttr, (m) {
      final kept = (m.group(2) ?? m.group(3) ?? '')
          .split(';')
          .map((d) => d.trim())
          .where((d) {
            final i = d.indexOf(':');
            if (i <= 0) return false;
            final prop = d.substring(0, i).trim().toLowerCase();
            return !_readerOwnedProps.contains(prop) &&
                !prop.startsWith('mso-'); // Microsoft Word junk
          })
          .join('; ');
      return kept.isEmpty ? '' : ' style="$kept"';
    })
    .replaceAll(_presentationAttrs, '');

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
