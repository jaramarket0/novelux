import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ad_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/tts_bridge.dart';
import 'package:novelux/screen/reading_interface/ambient_sound.dart';

import 'listen_controller.dart';
import 'listen_home_screen.dart';

class ListenPlayerScreen extends StatefulWidget {
  const ListenPlayerScreen({super.key});

  @override
  State<ListenPlayerScreen> createState() => _ListenPlayerScreenState();
}

class _ListenPlayerScreenState extends State<ListenPlayerScreen> {
  final ListenPlayerController p = Get.find<ListenPlayerController>();
  final ScrollController _scroll = ScrollController();
  List<GlobalKey> _keys = [];
  int _keysForChapter = -1;
  final List<Worker> _workers = [];
  bool _userScrolling = false;
  Timer? _userScrollTimer;

  @override
  void initState() {
    super.initState();
    _workers
      ..add(ever(p.paragraphIndex, (_) => _follow()))
      ..add(ever(p.chapterIndex, (_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
        _follow();
      }));
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(animate: false));
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    _userScrollTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _ensureKeys() {
    if (_keysForChapter != p.chapterIndex.value || _keys.length != p.paragraphs.length) {
      _keys = List.generate(p.paragraphs.length, (_) => GlobalKey());
      _keysForChapter = p.chapterIndex.value;
    }
  }

  /// Keep the paragraph being read in view (unless the reader is scrolling).
  void _follow({bool animate = true}) {
    if (!p.followAlong.value || _userScrolling) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final i = p.paragraphIndex.value;
      if (i >= _keys.length) return;
      final ctx = _keys[i].currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: animate ? const Duration(milliseconds: 350) : Duration.zero,
        curve: Curves.easeOut,
      );
    });
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
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: Get.back,
        ),
        title: Obx(
          () => Text(
            p.book.value?.title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search in book',
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () => _searchSheet(c),
          ),
          IconButton(
            tooltip: 'Bookmarks',
            icon: const Icon(LucideIcons.bookmark, size: 20),
            onPressed: () => _bookmarksSheet(c),
          ),
          IconButton(
            tooltip: 'Contents',
            icon: const Icon(LucideIcons.listOrdered, size: 20),
            onPressed: () => _contentsSheet(c),
          ),
        ],
      ),
      body: Obx(() {
        if (p.loadingBook.value || p.book.value == null) {
          return const Center(child: CircularProgressIndicator(color: depperBlue));
        }
        return Column(
          children: [
            _chapterHeader(c),
            Expanded(child: _textView(c)),
            _controls(c),
            const AdBannerWidget(),
          ],
        );
      }),
    );
  }

  Widget _chapterHeader(ListenColors c) => Obx(
    () => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              p.chapterTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: depperBlue, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${p.chapterIndex.value + 1} / ${p.chapters.length}',
            style: TextStyle(color: c.sub, fontSize: 12),
          ),
        ],
      ),
    ),
  );

  Widget _textView(ListenColors c) => NotificationListener<ScrollNotification>(
    onNotification: (n) {
      if (n is ScrollStartNotification && n.dragDetails != null) {
        _userScrolling = true;
        _userScrollTimer?.cancel();
      } else if (n is ScrollEndNotification && _userScrolling) {
        // Let the reader look around, then catch up with the voice
        _userScrollTimer?.cancel();
        _userScrollTimer = Timer(const Duration(seconds: 6), () {
          _userScrolling = false;
          _follow();
        });
      }
      return false;
    },
    child: Obx(() {
      _ensureKeys();
      final paras = p.paragraphs;
      final current = p.paragraphIndex.value;
      final scale = p.textScale.value;
      // Read reactive values here so highlighting rebuilds
      final sentence = p.sentenceIndex.value;
      final ws = p.wordStart.value;
      final we = p.wordEnd.value;
      final playing = p.isPlaying.value;
      return SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < paras.length; i++)
              GestureDetector(
                key: _keys[i],
                onTap: () => p.jumpTo(p.chapterIndex.value, i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == current ? depperBlue.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      i == current
                          ? _currentParagraph(paras[i], sentence, ws, we, playing, c, scale)
                          : Text(
                            paras[i],
                            style: TextStyle(color: c.text.withValues(alpha: 0.75), fontSize: 16 * scale, height: 1.6),
                          ),
                ),
              ),
          ],
        ),
      );
    }),
  );

  /// The paragraph being read: the sentence is tinted and the word being
  /// spoken is underlined.
  Widget _currentParagraph(String text, int sentence, int ws, int we, bool playing,
      ListenColors c, double scale) {
    final sentences = ListenPlayerController.sentencesOf(text);
    final base = TextStyle(color: c.text, fontSize: 16 * scale, height: 1.6);
    final spans = <TextSpan>[];
    for (var i = 0; i < sentences.length; i++) {
      final s = sentences[i];
      final sep = i < sentences.length - 1 ? ' ' : '';
      if (i != sentence) {
        spans.add(TextSpan(text: '$s$sep'));
        continue;
      }
      final hl = base.copyWith(
        backgroundColor: depperBlue.withValues(alpha: 0.22),
        fontWeight: FontWeight.w600,
      );
      if (playing && ws >= 0 && we > ws && we <= s.length) {
        spans
          ..add(TextSpan(text: s.substring(0, ws), style: hl))
          ..add(TextSpan(
            text: s.substring(ws, we),
            style: hl.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: depperBlue,
              decorationThickness: 2.5,
              color: depperBlue,
            ),
          ))
          ..add(TextSpan(text: s.substring(we), style: hl));
      } else {
        spans.add(TextSpan(text: s, style: hl));
      }
      spans.add(TextSpan(text: sep));
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }

  Widget _controls(ListenColors c) {
    Widget round(IconData icon, VoidCallback onTap, {String? tip, double size = 26}) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, color: c.text, size: size),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Obx(() {
        final paras = p.paragraphs.length;
        final pos = paras <= 1 ? 0.0 : p.paragraphIndex.value / (paras - 1);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: pos.clamp(0.0, 1.0),
                onChanged: (_) {},
                onChangeEnd: p.seekParagraph,
                activeColor: depperBlue,
                inactiveColor: c.divider,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${formatDuration(p.timeLeftInChapter)} left in chapter',
                  style: TextStyle(color: c.sub, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '${(p.bookProgress * 100).round()}% · ${formatDuration(p.timeLeftInBook)} left',
                  style: TextStyle(color: c.sub, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                round(Icons.skip_previous_rounded, p.previousChapter, tip: 'Previous chapter'),
                round(Icons.replay_rounded, p.previousParagraph, tip: 'Back a paragraph'),
                round(Icons.chevron_left_rounded, p.previousSentence, tip: 'Previous sentence', size: 30),
                GestureDetector(
                  onTap: p.togglePlay,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(color: depperBlue, shape: BoxShape.circle),
                    child: Icon(
                      p.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                round(Icons.chevron_right_rounded, p.nextSentence, tip: 'Next sentence', size: 30),
                round(Icons.forward_rounded, p.nextParagraph, tip: 'Next paragraph'),
                round(Icons.skip_next_rounded, p.nextChapter, tip: 'Next chapter'),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(c, LucideIcons.gauge, '${_fmtSpeed(p.speed.value)}×', () => _speedSheet(c)),
                  _chip(
                    c,
                    LucideIcons.moon,
                    p.sleepAtChapterEnd.value
                        ? 'End of chapter'
                        : p.sleepLeft.value != null
                        ? _fmtClock(p.sleepLeft.value!)
                        : 'Sleep',
                    () => _sleepSheet(c),
                    active: p.sleepLeft.value != null || p.sleepAtChapterEnd.value,
                  ),
                  _chip(c, LucideIcons.audioLines, p.voiceLabel.value, () => _voiceSheet(c)),
                  _chip(c, LucideIcons.bookmarkPlus, 'Bookmark', p.addBookmark),
                  _chip(c, LucideIcons.headphones, 'Sounds', () => showAmbientSoundLibrary(background: c.card)),
                  _chip(c, LucideIcons.slidersHorizontal, 'Display', () => _displaySheet(c)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _chip(ListenColors c, IconData icon, String label, VoidCallback onTap, {bool active = false}) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          avatar: Icon(icon, size: 15, color: active ? Colors.white : depperBlue),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          labelStyle: TextStyle(color: active ? Colors.white : c.text, fontSize: 12),
          backgroundColor: active ? depperBlue : c.bg,
          side: BorderSide.none,
          onPressed: onTap,
        ),
      );

  String _fmtSpeed(double s) => s == s.roundToDouble() ? s.toStringAsFixed(1) : s.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');
  String _fmtClock(Duration d) =>
      '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  Widget _sheet(ListenColors c, String title, Widget child, {double maxHeight = 0.7}) => Container(
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * maxHeight),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(title, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Flexible(child: child),
        ],
      ),
    ),
  );

  // ── Speed & pitch ──────────────────────────────────────────────────────────
  void _speedSheet(ListenColors c) {
    Get.bottomSheet(
      _sheet(
        c,
        'Playback speed',
        Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0])
                    ChoiceChip(
                      label: Text('${_fmtSpeed(s)}×'),
                      selected: (p.speed.value - s).abs() < 0.01,
                      onSelected: (_) => p.setSpeed(s),
                      selectedColor: depperBlue,
                      labelStyle: TextStyle(
                        color: (p.speed.value - s).abs() < 0.01 ? Colors.white : c.text,
                      ),
                      showCheckmark: false,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Fine-tune: ${_fmtSpeed(p.speed.value)}×', style: TextStyle(color: c.sub, fontSize: 12)),
              Slider(
                value: p.speed.value,
                min: 0.5,
                max: 3.0,
                divisions: 25,
                activeColor: depperBlue,
                onChanged: (v) => p.speed.value = v,
                onChangeEnd: p.setSpeed,
              ),
              Text('Voice pitch: ${p.pitch.value.toStringAsFixed(1)}', style: TextStyle(color: c.sub, fontSize: 12)),
              Slider(
                value: p.pitch.value,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                activeColor: depperBlue,
                onChanged: (v) => p.pitch.value = v,
                onChangeEnd: p.setPitch,
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Sleep timer ────────────────────────────────────────────────────────────
  void _sleepSheet(ListenColors c) {
    Widget option(String label, VoidCallback onTap) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(color: c.text)),
      onTap: () {
        onTap();
        Get.back();
      },
    );
    Get.bottomSheet(
      _sheet(
        c,
        'Sleep timer',
        ListView(
          shrinkWrap: true,
          children: [
            for (final m in [5, 10, 15, 30, 45, 60, 90])
              option('$m minutes', () => p.setSleepTimer(Duration(minutes: m))),
            option('End of this chapter', p.setSleepAtChapterEnd),
            if (p.sleepLeft.value != null || p.sleepAtChapterEnd.value)
              option('Turn off sleep timer', p.cancelSleepTimer),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Voices ─────────────────────────────────────────────────────────────────
  static const _languages = {
    'en': 'English', 'fr': 'French', 'es': 'Spanish', 'de': 'German', 'pt': 'Portuguese',
    'it': 'Italian', 'nl': 'Dutch', 'ar': 'Arabic', 'hi': 'Hindi', 'zh': 'Chinese',
    'ja': 'Japanese', 'ko': 'Korean', 'ru': 'Russian', 'tr': 'Turkish', 'sw': 'Swahili',
    'yo': 'Yoruba', 'ig': 'Igbo', 'ha': 'Hausa', 'id': 'Indonesian', 'pl': 'Polish',
  };

  String _localeName(String tag) {
    final parts = tag.replaceAll('_', '-').split('-');
    final lang = _languages[parts.first.toLowerCase()] ?? parts.first;
    return parts.length > 1 ? '$lang (${parts[1].toUpperCase()})' : lang;
  }

  Future<void> _voiceSheet(ListenColors c) async {
    final voices = await TtsBridge.instance.voices();
    if (!mounted) return;
    final device = Get.deviceLocale?.languageCode ?? 'en';
    voices.sort((a, b) {
      final la = (a['locale'] ?? '').toString(), lb = (b['locale'] ?? '').toString();
      final da = la.startsWith(device) ? 0 : 1, db = lb.startsWith(device) ? 0 : 1;
      if (da != db) return da - db;
      final cmp = la.compareTo(lb);
      if (cmp != 0) return cmp;
      return ((b['quality'] as num?) ?? 0).compareTo((a['quality'] as num?) ?? 0);
    });
    final counts = <String, int>{};
    final items = <Map<String, String>>[];
    for (final v in voices) {
      final locale = (v['locale'] ?? '').toString();
      final n = counts[locale] = (counts[locale] ?? 0) + 1;
      final custom = (v['label'] ?? '').toString();
      final hd = ((v['quality'] as num?) ?? 0) >= 400 ? ' · HD' : '';
      final online = v['network'] == true ? ' · needs internet' : '';
      items.add({
        'name': (v['name'] ?? '').toString(),
        'label': custom.isNotEmpty ? '$custom · ${_localeName(locale)}' : '${_localeName(locale)} · voice $n',
        'extra': '$hd$online',
      });
    }
    Get.bottomSheet(
      _sheet(
        c,
        'Voice',
        voices.isEmpty
            ? Text(
              'No voices found. Install a text-to-speech engine or voices in your phone\'s settings '
              '(Accessibility › Text-to-speech).',
              style: TextStyle(color: c.sub),
            )
            : Obx(
              () => ListView(
                shrinkWrap: true,
                children: [
                  _voiceTile(c, '', 'Phone default', ''),
                  for (final v in items) _voiceTile(c, v['name']!, v['label']!, v['extra']!),
                ],
              ),
            ),
        maxHeight: 0.8,
      ),
      isScrollControlled: true,
    );
  }

  Widget _voiceTile(ListenColors c, String name, String label, String extra) {
    final sel = p.voiceName.value == name;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off, color: sel ? depperBlue : c.sub),
      title: Text(label, style: TextStyle(color: c.text, fontSize: 13)),
      subtitle: extra.isEmpty ? null : Text(extra.substring(3), style: TextStyle(color: c.sub, fontSize: 11)),
      onTap: () => p.setVoice(name, label),
    );
  }

  // ── Display options ────────────────────────────────────────────────────────
  void _displaySheet(ListenColors c) {
    Get.bottomSheet(
      _sheet(
        c,
        'Display & listening',
        Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('A', style: TextStyle(color: c.sub, fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: p.textScale.value,
                      min: 0.8,
                      max: 1.8,
                      divisions: 10,
                      activeColor: depperBlue,
                      onChanged: p.setTextScale,
                    ),
                  ),
                  Text('A', style: TextStyle(color: c.sub, fontSize: 20)),
                ],
              ),
              _switch(c, 'Follow along', 'Keep the sentence being read in view', p.followAlong.value, p.toggleFollowAlong),
              _switch(c, 'Highlight words', 'Underline each word as it\'s spoken', p.highlightWords.value, p.toggleHighlightWords),
              _switch(c, 'Keep screen on', 'Stop the screen dimming while listening', p.keepAwake.value, p.toggleKeepAwake),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _switch(ListenColors c, String title, String sub, bool value, VoidCallback onTap) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: (_) => onTap(),
    activeThumbColor: depperBlue,
    title: Text(title, style: TextStyle(color: c.text, fontSize: 14)),
    subtitle: Text(sub, style: TextStyle(color: c.sub, fontSize: 11)),
  );

  // ── Contents ───────────────────────────────────────────────────────────────
  void _contentsSheet(ListenColors c) {
    final b = p.book.value;
    if (b == null) return;
    Get.bottomSheet(
      _sheet(
        c,
        'Contents',
        ListView.builder(
          shrinkWrap: true,
          itemCount: p.chapters.length,
          itemBuilder: (_, i) {
            final cur = i == p.chapterIndex.value;
            final words = p.chapters[i].wordCount;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(
                '${i + 1}',
                style: TextStyle(color: cur ? depperBlue : c.sub, fontWeight: FontWeight.w700),
              ),
              title: Text(
                p.chapters[i].title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cur ? depperBlue : c.text, fontWeight: cur ? FontWeight.w700 : FontWeight.normal),
              ),
              trailing: Text(
                formatDuration(Duration(seconds: (words / ListenPlayerController.wordsPerMinute * 60).round())),
                style: TextStyle(color: c.sub, fontSize: 11),
              ),
              onTap: () {
                Get.back();
                p.jumpTo(i, 0, startPlaying: p.isPlaying.value);
              },
            );
          },
        ),
        maxHeight: 0.8,
      ),
      isScrollControlled: true,
    );
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────────
  void _bookmarksSheet(ListenColors c) {
    Get.bottomSheet(
      _sheet(
        c,
        'Bookmarks',
        Obx(() {
          final marks = p.book.value?.bookmarks ?? const [];
          if (marks.isEmpty) {
            return Text(
              'No bookmarks yet. Tap "Bookmark" while listening to save your place.',
              style: TextStyle(color: c.sub),
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final m in marks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    m.chapter < p.chapters.length ? p.chapters[m.chapter].title : 'Chapter ${m.chapter + 1}',
                    style: const TextStyle(color: depperBlue, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(m.snippet, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 13)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: c.sub),
                    onPressed: () => p.removeBookmark(m),
                  ),
                  onTap: () {
                    Get.back();
                    p.jumpTo(m.chapter, m.paragraph);
                  },
                ),
            ],
          );
        }),
        maxHeight: 0.8,
      ),
      isScrollControlled: true,
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  void _searchSheet(ListenColors c) {
    final results = <ListenSearchHit>[].obs;
    final query = ''.obs;
    Timer? debounce;
    Get.bottomSheet(
      _sheet(
        c,
        'Search in book',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              style: TextStyle(color: c.text),
              decoration: InputDecoration(
                hintText: 'Words or a name…',
                hintStyle: TextStyle(color: c.sub),
                prefixIcon: Icon(LucideIcons.search, color: c.sub, size: 18),
                filled: true,
                fillColor: c.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (q) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 300), () {
                  query.value = q;
                  results.assignAll(p.search(q));
                });
              },
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Obx(
                () =>
                    results.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            query.value.trim().length < 2 ? 'Type at least 2 letters.' : 'No matches.',
                            style: TextStyle(color: c.sub),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final h = results[i];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                p.chapters[h.chapter].title,
                                style: const TextStyle(color: depperBlue, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(h.snippet, style: TextStyle(color: c.text, fontSize: 13)),
                              onTap: () {
                                Get.back();
                                p.jumpTo(h.chapter, h.paragraph);
                              },
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
        maxHeight: 0.85,
      ),
      isScrollControlled: true,
    );
  }
}
