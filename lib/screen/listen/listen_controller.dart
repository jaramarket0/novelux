import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/tts_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'book_parser.dart';
import 'listen_library.dart';

const _maxImportMb = 60;

/// The reader's imported books.
class ListenLibraryController extends GetxController {
  final RxList<ListenBook> books = <ListenBook>[].obs;
  final RxBool loading = true.obs;
  final RxBool importing = false.obs;
  final RxString importStatus = ''.obs;
  final RxString sort = 'recent'.obs; // recent | title | added

  final _store = ListenLibraryStore.instance;
  Timer? _saveDebounce;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    _saveDebounce?.cancel();
    _store.saveBooks(books);
    super.onClose();
  }

  Future<void> _load() async {
    books.assignAll(await _store.loadBooks());
    try {
      final p = await SharedPreferences.getInstance();
      sort.value = p.getString('listen_sort') ?? 'recent';
    } catch (_) {}
    loading.value = false;
  }

  List<ListenBook> get sortedBooks {
    final list = [...books];
    switch (sort.value) {
      case 'title':
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case 'added':
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      default:
        list.sort((a, b) => (b.lastOpenedAt ?? b.addedAt).compareTo(a.lastOpenedAt ?? a.addedAt));
    }
    return list;
  }

  void setSort(String s) {
    sort.value = s;
    SharedPreferences.getInstance().then((p) => p.setString('listen_sort', s)).catchError((_) => false);
  }

  /// Save soon (positions change every sentence; don't write each time).
  void persistSoon() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), persistNow);
  }

  Future<void> persistNow() async {
    _saveDebounce?.cancel();
    await _store.saveBooks(books);
    books.refresh();
  }

  /// Pick a file with the system picker (no storage permission) and import it.
  Future<ListenBook?> importBook() async {
    if (importing.value) return null;
    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...listenSupportedExtensions,
          ...listenUnsupportedHints.keys,
        ],
      );
    } on PlatformException {
      // Some devices' pickers reject custom extension filters — allow any file
      picked = await FilePicker.pickFiles(type: FileType.any);
    }
    final file = picked?.files.firstOrNull;
    if (file == null) return null;

    importing.value = true;
    importStatus.value = 'Reading "${file.name}"…';
    try {
      if (file.size > _maxImportMb * 1024 * 1024) {
        throw BookParseException('That file is over $_maxImportMb MB — try a smaller one.');
      }
      final bytes = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) throw BookParseException('Could not open that file.');
      importStatus.value = 'Preparing "${file.name}" for listening…';
      final parsed = await parseBookFile(bytes: bytes, fileName: file.name);
      final ext = file.name.contains('.') ? file.name.split('.').last : '';
      final book = await _store.addBook(parsed, ext);
      books.add(book);
      await persistNow();
      // The picker's temporary copy isn't needed any more
      if (file.path != null && Platform.isAndroid) {
        File(file.path!).delete().catchError((_) => File(file.path!));
      }
      AppAlert.success('"${book.title}" added — ${book.chapterTitles.length} chapters');
      return book;
    } on BookParseException catch (e) {
      AppAlert.error(e.message);
    } catch (_) {
      AppAlert.error('Could not read "${file.name}". The file may be damaged or protected.');
    } finally {
      importing.value = false;
      importStatus.value = '';
    }
    return null;
  }

  Future<void> deleteBook(ListenBook book) async {
    books.removeWhere((b) => b.id == book.id);
    await _store.deleteBook(book.id);
    await persistNow();
  }

  Future<void> renameBook(ListenBook book, String title, String author) async {
    book.title = title.trim().isEmpty ? book.title : title.trim();
    book.author = author.trim();
    await persistNow();
  }
}

/// A search hit inside a book.
class ListenSearchHit {
  final int chapter;
  final int paragraph;
  final String snippet;
  ListenSearchHit(this.chapter, this.paragraph, this.snippet);
}

/// Reads a book aloud with the phone's text-to-speech voices.
class ListenPlayerController extends GetxController implements TtsOwner {
  /// The Listen library, when this player belongs to it (null in story mode).
  ListenLibraryController? get _library =>
      !isStory && Get.isRegistered<ListenLibraryController>()
          ? Get.find<ListenLibraryController>()
          : null;

  // ── Story mode: reading a HuxNovel chapter aloud from the reader ───────────
  String? storySlug;
  String storyCover = '';
  String storyAuthor = '';
  int storyTotalChapters = 0;
  /// Chapter number of each entry in [chapters] (story mode).
  final List<int> storyChapterNumbers = [];
  final RxBool fetchingNextChapter = false.obs;
  bool get isStory => storySlug != null;

  /// HuxNovel chapter number being read (story mode), else 0.
  int get storyChapterNumber =>
      isStory && chapterIndex.value < storyChapterNumbers.length
          ? storyChapterNumbers[chapterIndex.value]
          : 0;

  /// Start (or return to) reading a story chapter from the reading screen.
  /// Returns false when there's nothing to read (e.g. a locked chapter).
  Future<bool> openStoryChapter({
    required String slug,
    required String storyTitle,
    required String author,
    required String cover,
    required int chapterNumber,
    required String chapterTitle,
    required String html,
    int totalChapters = 0,
  }) async {
    // Already on this chapter — just show the player again
    if (storySlug == slug && storyChapterNumber == chapterNumber && book.value != null) {
      return true;
    }
    final paragraphs = [for (final b in htmlToBlocks(html)) b.text];
    if (paragraphs.isEmpty) return false;
    await _stopSpeech();
    storySlug = slug;
    storyCover = cover;
    storyAuthor = author;
    storyTotalChapters = totalChapters;
    storyChapterNumbers
      ..clear()
      ..add(chapterNumber);
    chapters = [ParsedChapter(chapterTitle.isEmpty ? 'Chapter $chapterNumber' : chapterTitle, paragraphs)];
    final words = chapters.first.wordCount;
    book.value = ListenBook(
      id: 'story:$slug',
      title: storyTitle,
      author: author,
      format: 'STORY',
      addedAt: DateTime.now(),
      wordCount: words,
      chapterTitles: [chapters.first.title],
      chapterWords: [words],
    );
    chapterIndex.value = 0;
    paragraphIndex.value = 0;
    sentenceIndex.value = 0;
    _clearWord();
    _notificationShown = false;
    return true;
  }

  /// Fetch a story chapter's text. Null (with a message) when it's locked,
  /// missing or couldn't load.
  Future<ParsedChapter?> _fetchStoryChapter(int number) async {
    if (number < 1 || (storyTotalChapters > 0 && number > storyTotalChapters)) {
      AppAlert.info(number < 1 ? 'This is the first chapter.' : 'That was the last chapter.');
      return null;
    }
    fetchingNextChapter.value = true;
    final res = await ApiService.getChapter(storySlug!, number);
    fetchingNextChapter.value = false;
    if (res['success'] != true) {
      if (res['status'] == 404) {
        AppAlert.info('That was the last chapter.');
      } else {
        AppAlert.error('Couldn\'t load chapter $number. Check your connection.');
      }
      return null;
    }
    final data = res['data'];
    final locked = data['is_locked'] == true && data['is_unlocked'] != true;
    final paragraphs = locked
        ? const <String>[]
        : [for (final b in htmlToBlocks(data['content']?.toString() ?? '')) b.text];
    if (paragraphs.isEmpty) {
      AppAlert.info(locked
          ? 'Chapter $number is locked — unlock it in the reader to keep listening.'
          : 'Chapter $number has no text to read.');
      return null;
    }
    return ParsedChapter(data['title']?.toString() ?? 'Chapter $number', paragraphs);
  }

  /// Load the story chapter after the last one loaded and move to it.
  Future<void> _continueStory({required bool keepPlaying}) async {
    final next = storyChapterNumbers.last + 1;
    final ch = await _fetchStoryChapter(next);
    if (storySlug == null) return; // session stopped while loading
    if (ch == null) {
      if (keepPlaying) pause();
      return;
    }
    chapters = [...chapters, ch];
    storyChapterNumbers.add(next);
    book.value?.chapterTitles.add(ch.title);
    _moveToChapter(chapters.length - 1, keepPlaying: keepPlaying && isPlaying.value);
  }

  /// Load the story chapter before the first one loaded and move to it.
  Future<void> _previousStoryChapter() async {
    final prev = storyChapterNumbers.first - 1;
    final ch = await _fetchStoryChapter(prev);
    if (ch == null || storySlug == null) return;
    chapters = [ch, ...chapters];
    storyChapterNumbers.insert(0, prev);
    book.value?.chapterTitles.insert(0, ch.title);
    await jumpTo(0, 0, startPlaying: isPlaying.value);
  }

  /// "Stop listening": stop the voice and end the session.
  Future<void> stopSession() async {
    await pause();
    await _hideNotification();
    book.value = null;
    chapters = [];
    storyChapterNumbers.clear();
    storySlug = null;
    TtsBridge.instance.release(this);
  }

  final Rxn<ListenBook> book = Rxn<ListenBook>();
  List<ParsedChapter> chapters = [];
  final RxBool loadingBook = false.obs;

  final RxInt chapterIndex = 0.obs;
  final RxInt paragraphIndex = 0.obs;
  final RxInt sentenceIndex = 0.obs;
  final RxInt wordStart = (-1).obs;
  final RxInt wordEnd = (-1).obs;
  final RxBool isPlaying = false.obs;

  // Settings (remembered)
  final RxDouble speed = 1.0.obs;
  final RxDouble pitch = 1.0.obs;
  final RxString voiceName = ''.obs;
  final RxString voiceLabel = 'Phone default'.obs;
  final RxDouble textScale = 1.0.obs;
  final RxBool followAlong = true.obs;
  final RxBool keepAwake = false.obs;
  final RxBool highlightWords = true.obs;

  // Sleep timer
  final Rxn<Duration> sleepLeft = Rxn<Duration>();
  final RxBool sleepAtChapterEnd = false.obs;
  Timer? _sleepTimer;

  int _utterance = 0;
  String get _currentId => 'listen-$_utterance';
  Timer? _startWatchdog;
  int _errorsInARow = 0;
  bool _notificationShown = false;

  static const wordsPerMinute = 165.0;

  @override
  void onInit() {
    super.onInit();
    _loadPrefs();
  }

  @override
  void onClose() {
    _stopSpeech();
    _sleepTimer?.cancel();
    _startWatchdog?.cancel();
    _savePosition(immediate: true);
    _hideNotification();
    WakelockPlus.disable().catchError((_) {});
    TtsBridge.instance.release(this);
    super.onClose();
  }

  // ── Preferences ────────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      speed.value = p.getDouble('listen_speed') ?? 1.0;
      pitch.value = p.getDouble('listen_pitch') ?? 1.0;
      voiceName.value = p.getString('listen_voice') ?? '';
      voiceLabel.value = p.getString('listen_voice_label') ?? 'Phone default';
      textScale.value = p.getDouble('listen_text_scale') ?? 1.0;
      followAlong.value = p.getBool('listen_follow') ?? true;
      highlightWords.value = p.getBool('listen_highlight') ?? true;
    } catch (_) {}
  }

  Future<void> _savePrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble('listen_speed', speed.value);
      await p.setDouble('listen_pitch', pitch.value);
      await p.setString('listen_voice', voiceName.value);
      await p.setString('listen_voice_label', voiceLabel.value);
      await p.setDouble('listen_text_scale', textScale.value);
      await p.setBool('listen_follow', followAlong.value);
      await p.setBool('listen_highlight', highlightWords.value);
    } catch (_) {}
  }

  // ── Opening a book ─────────────────────────────────────────────────────────
  Future<bool> open(ListenBook b) async {
    if (book.value?.id == b.id && chapters.isNotEmpty) return true;
    await pause();
    _savePosition(immediate: true);
    loadingBook.value = true;
    try {
      chapters = await ListenLibraryStore.instance.loadChapters(b.id);
    } catch (_) {
      loadingBook.value = false;
      AppAlert.error('This book\'s text is missing — please import it again.');
      return false;
    }
    book.value = b;
    chapterIndex.value = b.chapter.clamp(0, chapters.isEmpty ? 0 : chapters.length - 1);
    paragraphIndex.value = b.paragraph.clamp(0, _paragraphs.isEmpty ? 0 : _paragraphs.length - 1);
    sentenceIndex.value = 0;
    _clearWord();
    b.lastOpenedAt = DateTime.now();
    if (b.finished) {
      b.finished = false;
      chapterIndex.value = 0;
      paragraphIndex.value = 0;
    }
    _library?.persistSoon();
    loadingBook.value = false;
    _notificationShown = false;
    return true;
  }

  List<String> get _paragraphs =>
      chapters.isEmpty ? const [] : chapters[chapterIndex.value].paragraphs;
  List<String> get paragraphs => _paragraphs;
  String get chapterTitle =>
      chapters.isEmpty ? '' : chapters[chapterIndex.value].title;

  /// Sentences of a paragraph. Long sentences are cut at commas or spaces so
  /// skipping and highlighting stay responsive.
  static List<String> sentencesOf(String paragraph) {
    final parts = paragraph
        .split(RegExp(r'(?<=[.!?…]["”’)\]]*)\s+(?=["“‘(\[]?\p{Lu}|\d)', unicode: true))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final out = <String>[];
    for (final p in parts) {
      if (p.length <= 320) {
        out.add(p);
        continue;
      }
      var rest = p;
      while (rest.length > 320) {
        var cut = rest.lastIndexOf(RegExp(r'[,;:—]\s'), 300);
        if (cut < 120) cut = rest.lastIndexOf(' ', 300);
        if (cut < 60) cut = 300;
        out.add(rest.substring(0, cut + 1).trim());
        rest = rest.substring(cut + 1).trim();
      }
      if (rest.isNotEmpty) out.add(rest);
    }
    return out.isEmpty ? [paragraph] : out;
  }

  List<String> get currentSentences =>
      _paragraphs.isEmpty ? const [] : sentencesOf(_paragraphs[paragraphIndex.value]);

  String get currentSentence {
    final s = currentSentences;
    if (s.isEmpty) return '';
    return s[sentenceIndex.value.clamp(0, s.length - 1)];
  }

  // ── Playback ───────────────────────────────────────────────────────────────
  Future<void> play() async {
    if (chapters.isEmpty || _paragraphs.isEmpty) return;
    TtsBridge.instance.claim(this);
    isPlaying.value = true;
    _errorsInARow = 0;
    if (keepAwake.value) WakelockPlus.enable().catchError((_) {});
    _showNotification();
    await _speakCurrent();
  }

  Future<void> pause() async {
    if (!isPlaying.value) return;
    isPlaying.value = false;
    await _stopSpeech();
    _clearWord();
    _savePosition(immediate: true);
    _updateNotification();
    WakelockPlus.disable().catchError((_) {});
  }

  void togglePlay() => isPlaying.value ? pause() : play();

  Future<void> _speakCurrent() async {
    final text = currentSentence;
    if (text.isEmpty) return _advance();
    _utterance++;
    _clearWord();
    _startWatchdog?.cancel();
    _startWatchdog = Timer(const Duration(seconds: 6), () {
      if (isPlaying.value) {
        pause();
        AppAlert.error(
          'No voice is speaking. Check that a text-to-speech engine is installed '
          '(Settings › Accessibility › Text-to-speech) and try again.',
        );
      }
    });
    try {
      await TtsBridge.tts.invokeMethod('speak', {
        'text': text,
        'speed': speed.value,
        'pitch': pitch.value,
        'id': _currentId,
        if (voiceName.value.isNotEmpty) 'voice': voiceName.value,
      });
    } catch (_) {
      _startWatchdog?.cancel();
      isPlaying.value = false;
      AppAlert.error('Text-to-speech isn\'t available on this device.');
    }
  }

  Future<void> _stopSpeech() async {
    _utterance++; // late callbacks from the stopped sentence are ignored
    _startWatchdog?.cancel();
    try {
      await TtsBridge.tts.invokeMethod('stop');
    } catch (_) {}
  }

  void _clearWord() {
    wordStart.value = -1;
    wordEnd.value = -1;
  }

  /// Next sentence → next paragraph → next chapter.
  void _advance() {
    final sentences = currentSentences;
    if (sentenceIndex.value < sentences.length - 1) {
      sentenceIndex.value++;
    } else if (paragraphIndex.value < _paragraphs.length - 1) {
      paragraphIndex.value++;
      sentenceIndex.value = 0;
    } else {
      // End of chapter
      if (sleepAtChapterEnd.value) {
        cancelSleepTimer();
        _moveToChapter(chapterIndex.value + 1, keepPlaying: false);
        pause();
        AppAlert.info('Sleep timer — stopped at the end of the chapter.');
        return;
      }
      if (chapterIndex.value < chapters.length - 1) {
        _moveToChapter(chapterIndex.value + 1, keepPlaying: true);
        return;
      }
      if (isStory) {
        _continueStory(keepPlaying: true);
        return;
      }
      // End of book
      book.value?.finished = true;
      pause();
      _library?.persistSoon();
      AppAlert.success('You finished "${book.value?.title ?? 'the book'}"!');
      return;
    }
    _savePosition();
    if (isPlaying.value) _speakCurrent();
  }

  void _moveToChapter(int index, {required bool keepPlaying}) {
    if (index < 0 || index >= chapters.length) return;
    chapterIndex.value = index;
    paragraphIndex.value = 0;
    sentenceIndex.value = 0;
    _clearWord();
    _savePosition();
    _updateNotification();
    if (keepPlaying && isPlaying.value) _speakCurrent();
  }

  /// Jump to a place in the book (contents, bookmark, search, tapped text).
  Future<void> jumpTo(int chapter, int paragraph, {bool startPlaying = true}) async {
    final wasPlaying = isPlaying.value;
    await _stopSpeech();
    chapterIndex.value = chapter.clamp(0, chapters.length - 1);
    paragraphIndex.value = paragraph.clamp(0, _paragraphs.isEmpty ? 0 : _paragraphs.length - 1);
    sentenceIndex.value = 0;
    _clearWord();
    _savePosition();
    _updateNotification();
    if (wasPlaying || startPlaying) {
      if (!isPlaying.value) {
        await play();
      } else {
        _speakCurrent();
      }
    }
  }

  Future<void> _restartAt(void Function() move) async {
    final wasPlaying = isPlaying.value;
    await _stopSpeech();
    move();
    _clearWord();
    _savePosition();
    if (wasPlaying) _speakCurrent();
  }

  void nextSentence() => _restartAt(() {
    if (sentenceIndex.value < currentSentences.length - 1) {
      sentenceIndex.value++;
    } else if (paragraphIndex.value < _paragraphs.length - 1) {
      paragraphIndex.value++;
      sentenceIndex.value = 0;
    }
  });

  void previousSentence() => _restartAt(() {
    if (sentenceIndex.value > 0) {
      sentenceIndex.value--;
    } else if (paragraphIndex.value > 0) {
      paragraphIndex.value--;
      sentenceIndex.value = sentencesOf(_paragraphs[paragraphIndex.value]).length - 1;
    }
  });

  void nextParagraph() => _restartAt(() {
    if (paragraphIndex.value < _paragraphs.length - 1) {
      paragraphIndex.value++;
      sentenceIndex.value = 0;
    } else if (chapterIndex.value < chapters.length - 1) {
      chapterIndex.value++;
      paragraphIndex.value = 0;
      sentenceIndex.value = 0;
    }
  });

  /// Back to the start of this paragraph, or the previous one if we're at it.
  void previousParagraph() => _restartAt(() {
    if (sentenceIndex.value > 0) {
      sentenceIndex.value = 0;
    } else if (paragraphIndex.value > 0) {
      paragraphIndex.value--;
      sentenceIndex.value = 0;
    } else if (chapterIndex.value > 0) {
      chapterIndex.value--;
      paragraphIndex.value = (_paragraphs.length - 1).clamp(0, 1 << 30);
      sentenceIndex.value = 0;
    }
  });

  void nextChapter() {
    if (chapterIndex.value < chapters.length - 1) {
      jumpTo(chapterIndex.value + 1, 0, startPlaying: isPlaying.value);
    } else if (isStory) {
      _stopSpeech().then((_) => _continueStory(keepPlaying: isPlaying.value));
    }
  }

  void previousChapter() {
    // Restart this chapter if we're into it, otherwise go to the previous one
    if (isStory && chapterIndex.value == 0 && paragraphIndex.value <= 1 &&
        storyChapterNumber > 1) {
      _previousStoryChapter();
    } else if (paragraphIndex.value > 1 || chapterIndex.value == 0) {
      jumpTo(chapterIndex.value, 0, startPlaying: isPlaying.value);
    } else {
      jumpTo(chapterIndex.value - 1, 0, startPlaying: isPlaying.value);
    }
  }

  void seekParagraph(double fraction) {
    if (_paragraphs.isEmpty) return;
    final p = (fraction * (_paragraphs.length - 1)).round();
    jumpTo(chapterIndex.value, p, startPlaying: isPlaying.value);
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  void setSpeed(double v) {
    speed.value = double.parse(v.clamp(0.5, 3.0).toStringAsFixed(2));
    _savePrefs();
    if (isPlaying.value) _restartAt(() {});
  }

  void setPitch(double v) {
    pitch.value = double.parse(v.clamp(0.5, 2.0).toStringAsFixed(2));
    _savePrefs();
    if (isPlaying.value) _restartAt(() {});
  }

  void setVoice(String name, String label) {
    voiceName.value = name;
    voiceLabel.value = label;
    _savePrefs();
    if (isPlaying.value) _restartAt(() {});
  }

  void setTextScale(double v) {
    textScale.value = v.clamp(0.8, 1.8);
    _savePrefs();
  }

  void toggleFollowAlong() {
    followAlong.toggle();
    _savePrefs();
  }

  void toggleHighlightWords() {
    highlightWords.toggle();
    _savePrefs();
  }

  void toggleKeepAwake() {
    keepAwake.toggle();
    if (keepAwake.value && isPlaying.value) {
      WakelockPlus.enable().catchError((_) {});
    } else {
      WakelockPlus.disable().catchError((_) {});
    }
  }

  // ── Sleep timer ────────────────────────────────────────────────────────────
  void setSleepTimer(Duration d) {
    cancelSleepTimer();
    sleepLeft.value = d;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = sleepLeft.value;
      if (left == null) return;
      final next = left - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        cancelSleepTimer();
        pause();
        AppAlert.info('Sleep timer — playback paused.');
      } else {
        sleepLeft.value = next;
      }
    });
  }

  void setSleepAtChapterEnd() {
    cancelSleepTimer();
    sleepAtChapterEnd.value = true;
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepLeft.value = null;
    sleepAtChapterEnd.value = false;
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────────
  void addBookmark() {
    final b = book.value;
    if (b == null || _paragraphs.isEmpty) return;
    final text = _paragraphs[paragraphIndex.value];
    if (b.bookmarks.any((m) => m.chapter == chapterIndex.value && m.paragraph == paragraphIndex.value)) {
      AppAlert.info('Already bookmarked.');
      return;
    }
    b.bookmarks.add(ListenBookmark(
      chapter: chapterIndex.value,
      paragraph: paragraphIndex.value,
      snippet: text.length > 140 ? '${text.substring(0, 140)}…' : text,
      createdAt: DateTime.now(),
    ));
    b.bookmarks.sort((x, y) => x.chapter != y.chapter
        ? x.chapter.compareTo(y.chapter)
        : x.paragraph.compareTo(y.paragraph));
    _library?.persistSoon();
    book.refresh();
    AppAlert.success('Bookmark added');
  }

  void removeBookmark(ListenBookmark m) {
    book.value?.bookmarks.remove(m);
    _library?.persistSoon();
    book.refresh();
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  List<ListenSearchHit> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final hits = <ListenSearchHit>[];
    for (var c = 0; c < chapters.length; c++) {
      final paras = chapters[c].paragraphs;
      for (var p = 0; p < paras.length; p++) {
        final text = paras[p];
        final i = text.toLowerCase().indexOf(q);
        if (i < 0) continue;
        final start = (i - 50).clamp(0, text.length);
        final end = (i + q.length + 70).clamp(0, text.length);
        hits.add(ListenSearchHit(c, p,
            '${start > 0 ? '…' : ''}${text.substring(start, end)}${end < text.length ? '…' : ''}'));
        if (hits.length >= 200) return hits;
      }
    }
    return hits;
  }

  // ── Progress ───────────────────────────────────────────────────────────────
  int get wordsBeforePosition {
    var n = 0;
    for (var c = 0; c < chapterIndex.value && c < chapters.length; c++) {
      n += chapters[c].wordCount;
    }
    for (var p = 0; p < paragraphIndex.value && p < _paragraphs.length; p++) {
      n += _countWords(_paragraphs[p]);
    }
    return n;
  }

  static int _countWords(String s) => RegExp(r"[\p{L}\p{N}']+", unicode: true).allMatches(s).length;

  double get bookProgress {
    final total = book.value?.wordCount ?? 0;
    return total == 0 ? 0 : (wordsBeforePosition / total).clamp(0.0, 1.0);
  }

  Duration get timeLeftInBook {
    final total = book.value?.wordCount ?? 0;
    final left = (total - wordsBeforePosition).clamp(0, total);
    return Duration(seconds: (left / (wordsPerMinute * speed.value) * 60).round());
  }

  Duration get timeLeftInChapter {
    var left = 0;
    for (var p = paragraphIndex.value; p < _paragraphs.length; p++) {
      left += _countWords(_paragraphs[p]);
    }
    return Duration(seconds: (left / (wordsPerMinute * speed.value) * 60).round());
  }

  void _savePosition({bool immediate = false}) {
    final b = book.value;
    if (b == null) return;
    b.chapter = chapterIndex.value;
    b.paragraph = paragraphIndex.value;
    final lib = _library;
    if (lib == null) return;
    immediate ? lib.persistNow() : lib.persistSoon();
  }

  // ── Speech engine events (via TtsBridge) ───────────────────────────────────
  @override
  Future<dynamic> onTts(MethodCall call) async {
    final id = (call.arguments is Map) ? call.arguments['id']?.toString() : null;
    if (id != _currentId) return; // a stopped sentence, or another player's
    switch (call.method) {
      case 'onStart':
        _startWatchdog?.cancel();
        _errorsInARow = 0;
      case 'onRange':
        if (highlightWords.value) {
          wordStart.value = (call.arguments['start'] as num?)?.toInt() ?? -1;
          wordEnd.value = (call.arguments['end'] as num?)?.toInt() ?? -1;
        }
      case 'onDone':
        if (isPlaying.value) _advance();
      case 'onError':
        _startWatchdog?.cancel();
        if (!isPlaying.value) return;
        // Skip a sentence the engine can't say; give up after a few in a row
        if (++_errorsInARow >= 3) {
          pause();
          AppAlert.error('The voice stopped responding. Try another voice in settings.');
        } else {
          _advance();
        }
    }
  }

  @override
  Future<dynamic> onMedia(MethodCall call) async {
    switch (call.method) {
      case 'play':
        play();
      case 'pause':
        pause();
      case 'stop':
        pause();
        _hideNotification();
      case 'next':
        nextParagraph();
      case 'previous':
        previousParagraph();
    }
  }

  @override
  void onPreempted() {
    if (isPlaying.value) {
      isPlaying.value = false;
      _utterance++;
      _clearWord();
      _savePosition(immediate: true);
    }
  }

  // ── Notification / lock screen ─────────────────────────────────────────────
  Future<void> _showNotification() async {
    try {
      await TtsBridge.media.invokeMethod(_notificationShown ? 'update' : 'show', {
        'title': book.value?.title ?? 'Listening',
        'artist': chapterTitle,
        'albumArt': isStory ? storyCover : '',
        'isPlaying': true,
        'duration': 0,
        'position': 0,
      });
      _notificationShown = true;
    } catch (_) {}
  }

  Future<void> _updateNotification() async {
    if (!_notificationShown) return;
    try {
      await TtsBridge.media.invokeMethod('update', {'isPlaying': isPlaying.value});
    } catch (_) {}
  }

  Future<void> _hideNotification() async {
    if (!_notificationShown) return;
    _notificationShown = false;
    try {
      await TtsBridge.media.invokeMethod('hide');
    } catch (_) {}
  }
}
