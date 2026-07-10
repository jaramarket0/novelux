import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';

// ── TTS Audio Controller ──────────────────────────────────────────────────────
class AudioPlayerController extends GetxController {
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxInt currentSeconds = 0.obs;
  final RxInt totalSeconds = 0.obs;
  final RxDouble speed = 1.0.obs;
  final RxString chapterTitle = ''.obs;
  final RxString storyTitle = ''.obs;
  final RxString coverUrl = ''.obs;
  final RxString author = ''.obs;
  final RxBool isMinimized = false.obs;
  final RxInt currentSentence = 0.obs;

  List<String> _sentences = [];
  List<String> get sentences => List.unmodifiable(_sentences);

  Timer? _progressTimer;

  static const _tts = MethodChannel('novelux/tts');
  static const _media = MethodChannel('novelux/media_notification');

  @override
  void onInit() {
    super.onInit();
    _tts.setMethodCallHandler(_handleTtsEvent);
    _media.setMethodCallHandler(_handleMediaCommand);
  }

  OverlayEntry? _bubbleEntry;

  void showBubble({OverlayState? overlay}) {
    if (_bubbleEntry != null) return;
    isMinimized.value = true;
    final entry = OverlayEntry(builder: (_) => AudioBubble(ctrl: this));
    _bubbleEntry = entry;
    // Use the overlay passed from the screen context, or fall back to the
    // root navigator's overlay (more reliable than Get.overlayContext).
    final target = overlay ?? Get.key.currentState?.overlay;
    if (target == null) {
      _bubbleEntry = null;
      isMinimized.value = false;
      return;
    }
    target.insert(entry);
  }

  void hideBubble() {
    _bubbleEntry?.remove();
    _bubbleEntry = null;
    isMinimized.value = false;
  }

  void cancelAudio() {
    hideBubble();
    _stopTts();
    _hideNotification();
    chapterTitle.value = '';
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    _stopTts();
    _hideNotification();
    hideBubble();
    super.onClose();
  }

  // ── TTS events from native ─────────────────────────────────────────────────
  Future<dynamic> _handleTtsEvent(MethodCall call) async {
    switch (call.method) {
      case 'onStart':
        isLoading.value = false;
        isPlaying.value = true;
        _updateNotification();
        break;
      case 'onDone':
        if (isPlaying.value) _nextSentence();
        break;
      case 'onError':
        isPlaying.value = false;
        isLoading.value = false;
        _updateNotification();
        break;
    }
  }

  // ── Media notification commands ────────────────────────────────────────────
  Future<dynamic> _handleMediaCommand(MethodCall call) async {
    switch (call.method) {
      case 'play':
        resume();
        break;
      case 'pause':
        pause();
        break;
      case 'stop':
        _stopTts();
        _hideNotification();
        break;
      case 'next':
        forward15();
        break;
      case 'previous':
        rewind15();
        break;
      case 'seekTo':
        // Native lock screen seek bar dragged
        final posSec = ((call.arguments['position'] as int? ?? 0) ~/ 1000);
        final ratio =
            totalSeconds.value > 0
                ? (posSec / totalSeconds.value).clamp(0.0, 1.0)
                : 0.0;
        seekTo(ratio);
        break;
      case 'onProgress':
        // Native is tracking progress (only matters if using native timer)
        // We manage our own timer so we can ignore this,
        // but sync if there's drift:
        final durMs = call.arguments['duration'] as int? ?? 0;
        if (durMs > 0 && totalSeconds.value == 0) {
          totalSeconds.value = durMs ~/ 1000;
        }
        break;
    }
  }

  // // ── Load chapter ───────────────────────────────────────────────────────────
  // void loadChapter({
  //   required String content,
  //   required String chapter,
  //   required String story,
  //   required String author,
  //   required String cover,
  // }) {
  //   _stopTts();
  //   chapterTitle.value = chapter;
  //   storyTitle.value = story;
  //   coverUrl.value = cover;

  //   _sentences =
  //       content
  //           .split(RegExp(r'(?<=[.!?])\s+'))
  //           .where((s) => s.trim().isNotEmpty)
  //           .toList();

  //   final words = content.split(RegExp(r'\s+')).length;
  //   totalSeconds.value = ((words / 130) * 60).round().clamp(60, 7200);
  //   currentSeconds.value = 0;
  //   currentSentence.value = 0;
  //   progress.value = 0.0;

  //   play();
  // }

  // ── Load chapter ───────────────────────────────────────────────────────────
  void loadChapter({
    required String content,
    required String chapter,
    required String story,
    required String author,
    required String cover,
  }) {
    _stopTts();
    chapterTitle.value = chapter;
    storyTitle.value = story;
    coverUrl.value = cover;

    // ── NEW: Strip HTML before splitting into sentences ──
    final String cleanContent =
        content
            .replaceAll(
              RegExp(r'<[^>]*>'),
              ' ',
            ) // Removes tags like <p>, <b>, etc.
            .replaceAll(RegExp(r'&[^;]+;'), ' ') // Removes entities like &nbsp;
            .replaceAll(RegExp(r'\s+'), ' ') // Collapses extra whitespace
            .trim();

    _sentences =
        cleanContent
            .split(RegExp(r'(?<=[.!?])\s+'))
            .where((s) => s.trim().isNotEmpty)
            .toList();

    // Calculate total time based on the CLEAN text
    final words = cleanContent.split(RegExp(r'\s+')).length;
    totalSeconds.value = ((words / 180) * 60).round().clamp(60, 7200);

    currentSeconds.value = 0;
    currentSentence.value = 0;
    progress.value = 0.0;

    play();
  }

  // ── Playback ───────────────────────────────────────────────────────────────
  Future<void> play() async {
    if (_sentences.isEmpty) return;
    if (currentSentence.value >= _sentences.length) return;

    isLoading.value = true;
    try {
      await _tts.invokeMethod('speak', {
        'text': _sentences[currentSentence.value],
        'speed': speed.value,
        'lang': 'en-NG',
      });
    } catch (_) {
      isLoading.value = false;
      isPlaying.value = true;
      _simulatePlayback();
      _showNotification();
      return;
    }

    if (_progressTimer == null || !_progressTimer!.isActive) {
      _startProgressTimer();
    }
    _showNotification();
  }

  void _nextSentence() {
    if (currentSentence.value < _sentences.length - 1) {
      currentSentence.value++;
      play();
    } else {
      _onComplete();
    }
  }

  Future<void> pause() async {
    isPlaying.value = false;
    _progressTimer?.cancel();
    try {
      await _tts.invokeMethod('stop');
    } catch (_) {}
    _updateNotification();
  }

  Future<void> resume() async => play();

  Future<void> _stopTts() async {
    _progressTimer?.cancel();
    _progressTimer = null;
    isPlaying.value = false;
    try {
      await _tts.invokeMethod('stop');
    } catch (_) {}
  }

  void togglePlay() => isPlaying.value ? pause() : resume();

  void seekTo(double value) {
    progress.value = value.clamp(0.0, 1.0);
    currentSeconds.value = (value * totalSeconds.value).round();
    currentSentence.value = (value * _sentences.length).round().clamp(
      0,
      _sentences.isEmpty ? 0 : _sentences.length - 1,
    );
    try {
      _tts.invokeMethod('stop');
    } catch (_) {}
    // ← ADD THIS: sync the notification slider position
    try {
      _media.invokeMethod('seekTo', {'position': currentSeconds.value * 1000});
    } catch (_) {}
    if (isPlaying.value) play();
  }

  void rewind15() {
    final s = (currentSeconds.value - 15).clamp(0, totalSeconds.value);
    seekTo(totalSeconds.value > 0 ? s / totalSeconds.value : 0.0);
  }

  void forward15() {
    final s = (currentSeconds.value + 15).clamp(0, totalSeconds.value);
    seekTo(totalSeconds.value > 0 ? s / totalSeconds.value : 0.0);
  }

  void setSpeed(double s) {
    speed.value = s;
    if (isPlaying.value) {
      try {
        _tts.invokeMethod('stop');
      } catch (_) {}
      play();
    }
  }

  void _simulatePlayback() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!isPlaying.value) return;
      currentSeconds.value =
          (currentSeconds.value + (0.5 * speed.value)).round();
      if (totalSeconds.value > 0) {
        progress.value = (currentSeconds.value / totalSeconds.value).clamp(
          0.0,
          1.0,
        );
      }
      if (currentSeconds.value > 0 && currentSeconds.value % 8 == 0) {
        _nextSentence();
      }
      if (progress.value >= 1.0) _onComplete();
    });
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPlaying.value) return;
      currentSeconds.value++;
      if (totalSeconds.value > 0) {
        progress.value = (currentSeconds.value / totalSeconds.value).clamp(
          0.0,
          1.0,
        );
      }
      if (progress.value >= 1.0) _onComplete();
    });
  }

  void _onComplete() {
    isPlaying.value = false;
    _progressTimer?.cancel();
    _progressTimer = null;
    hideBubble();
    _hideNotification();
    AppAlert.info('Chapter Complete — Finished reading ${chapterTitle.value}');
  }

  // ── Media notification ─────────────────────────────────────────────────────
  Future<void> _showNotification() async {
    try {
      await _media.invokeMethod('show', {
        'title': chapterTitle.value,
        'artist': "${storyTitle.value} By ${author.value}",
        'albumArt': coverUrl.value,
        'isPlaying': isPlaying.value,
        'duration': totalSeconds.value * 1000, // convert to ms
        'position': currentSeconds.value * 1000, // convert to ms
      });
    } catch (e) {
      developer.log('Failed to show media notification');
    }
  }

  Future<void> _updateNotification() async {
    try {
      await _media.invokeMethod('update', {
        'isPlaying': isPlaying.value,
        'position': currentSeconds.value * 1000,
        'duration': totalSeconds.value * 1000,
      });
    } catch (_) {}
  }

  Future<void> _hideNotification() async {
    try {
      await _media.invokeMethod('hide');
    } catch (_) {}
  }

  // ── Formatters ─────────────────────────────────────────────────────────────
  String formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  String get currentTime => formatTime(currentSeconds.value);
  String get totalTime => formatTime(totalSeconds.value);
}

// ── Audio Player Screen ───────────────────────────────────────────────────────
class AudioPlayerScreen extends StatefulWidget {
  final String imagePath;
  final String author;
  final String story;
  const AudioPlayerScreen(this.imagePath, this.author, this.story, {super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final ScrollController _transcriptScroll = ScrollController();
  final List<GlobalKey> _sentenceKeys = [];
  late AudioPlayerController ctrl;
  int _lastScrolledIndex = -1;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<AudioPlayerController>();
    _buildKeys();
    ctrl.author.value = widget.author;
    ctrl.coverUrl.value = widget.imagePath;
    // Auto-scroll transcript to highlighted sentence
    ever(ctrl.currentSentence, (int index) {
      _buildKeys();
      _scrollToSentence(index);
    });
  }

  void _buildKeys() {
    while (_sentenceKeys.length < ctrl.sentences.length) {
      _sentenceKeys.add(GlobalKey());
    }
  }

  void _scrollToSentence(int index) {
    if (index == _lastScrolledIndex) return;
    _lastScrolledIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _sentenceKeys.length) return;
      final ctx = _sentenceKeys[index].currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    });
  }

  @override
  void dispose() {
    _transcriptScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        // Capture overlay while context is still valid, before dispose.
        final overlay = Overlay.of(context, rootOverlay: true);
        ctrl.showBubble(overlay: overlay);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0d0d0f),
        body: SafeArea(
          child: Column(
            children: [
              // ── App bar ────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        const Text(
                          'Now Listening',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Obx(
                          () => SizedBox(
                            width: 230,
                            child: Text(
                              ctrl.chapterTitle.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _speedSheet(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // ── Cover + waveform ─────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF1e1e22),
                          image:
                              widget.imagePath.isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(widget.imagePath),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withValues(alpha: 0.4),
                                      BlendMode.darken,
                                    ),
                                  )
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                              () => AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                width: ctrl.isPlaying.value ? 80 : 70,
                                height: ctrl.isPlaying.value ? 80 : 70,
                                decoration: BoxDecoration(
                                  color: depperBlue.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: depperBlue,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.headphones_rounded,
                                  color: depperBlue,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(
                              () => _WaveformWidget(
                                isPlaying: ctrl.isPlaying.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Story + chapter ───────────────────────────────────────────
                      Obx(
                        () => Column(
                          children: [
                            Text(
                              ctrl.storyTitle.value,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              //ctrl.storyTitle.value,
                              widget.story,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ctrl.chapterTitle.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Transcript (highlighted text) ─────────────────────────────
                      _TranscriptPanel(
                        ctrl: ctrl,
                        scrollController: _transcriptScroll,
                        sentenceKeys: _sentenceKeys,
                      ),
                      const SizedBox(height: 16),

                      // ── Progress slider ───────────────────────────────────────────
                      Obx(
                        () => Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                                activeTrackColor: depperBlue,
                                inactiveTrackColor: const Color(0xFF2a2a2a),
                                thumbColor: depperBlue,
                                overlayColor: depperBlue.withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: ctrl.progress.value.clamp(0.0, 1.0),
                                onChanged: ctrl.seekTo,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ctrl.currentTime,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  ctrl.totalTime,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Controls ──────────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ctrlBtn(
                            LucideIcons.stepBack500,
                            '-15s',
                            ctrl.rewind15,
                          ),
                          _ctrlBtn(
                            LucideIcons.skipBack500,
                            '',
                            () {},
                            size: 32,
                          ),
                          Obx(
                            () => GestureDetector(
                              onTap: ctrl.togglePlay,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: depperBlue,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: depperBlue.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child:
                                    ctrl.isLoading.value
                                        ? const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                        : Icon(
                                          ctrl.isPlaying.value
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                              ),
                            ),
                          ),
                          _ctrlBtn(
                            LucideIcons.skipForward500,
                            '',
                            () {},
                            size: 32,
                          ),
                          _ctrlBtn(
                            LucideIcons.stepForward500,
                            '+15s',
                            ctrl.forward15,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Speed selector ────────────────────────────────────────────
                      Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                                final sel = ctrl.speed.value == s;
                                return GestureDetector(
                                  onTap: () => ctrl.setSpeed(s),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          sel
                                              ? depperBlue
                                              : const Color(0xFF2a2a2a),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${s}x',
                                      style: TextStyle(
                                        color: sel ? Colors.black : Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctrlBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    double size = 28,
  }) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: size),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ],
    ),
  );

  void _speedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e1e22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                          final sel = ctrl.speed.value == s;
                          return GestureDetector(
                            onTap: () {
                              ctrl.setSpeed(s);
                              Get.back();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    sel ? depperBlue : const Color(0xFF2a2a2a),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${s}x',
                                style: TextStyle(
                                  color: sel ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}

// ── Transcript panel with live sentence highlighting ─────────────────────────
class _TranscriptPanel extends StatelessWidget {
  final AudioPlayerController ctrl;
  final ScrollController scrollController;
  final List<GlobalKey> sentenceKeys;

  const _TranscriptPanel({
    required this.ctrl,
    required this.scrollController,
    required this.sentenceKeys,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: depperBlue.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Obx(() {
          final sentences = ctrl.sentences;
          final current = ctrl.currentSentence.value;

          if (sentences.isEmpty) {
            return const Center(
              child: Text(
                'No text loaded',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            );
          }

          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: sentences.length,
            itemBuilder: (context, i) {
              final isActive = i == current;
              final key = i < sentenceKeys.length ? sentenceKeys[i] : null;

              return GestureDetector(
                // Tap a sentence to jump to it
                onTap: () {
                  final ratio =
                      sentences.length > 1 ? i / (sentences.length - 1) : 0.0;
                  ctrl.seekTo(ratio);
                },
                child: AnimatedContainer(
                  key: key,
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? depperBlue.withValues(alpha: 0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isActive
                            ? Border.all(
                              color: depperBlue.withValues(alpha: 0.4),
                            )
                            : null,
                  ),
                  child: Text(
                    sentences[i],
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: isActive ? 13.5 : 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      height: 1.5,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ── Mini player ───────────────────────────────────────────────────────────────
class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AudioPlayerController>()) {
      return const SizedBox.shrink();
    }
    final ctrl = Get.find<AudioPlayerController>();
    return Obx(() {
      if (ctrl.chapterTitle.value.isEmpty) return const SizedBox.shrink();
      return GestureDetector(
        onTap:
            () => Get.to(
              () => AudioPlayerScreen(
                ctrl.coverUrl.value,
                ctrl.author.value,
                ctrl.storyTitle.value,
              ),
            ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1e1e22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: depperBlue.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    ctrl.coverUrl.value.isNotEmpty
                        ? Image.network(
                          ctrl.coverUrl.value,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          width: 40,
                          height: 40,
                          color: const Color(0xFF2a2a2a),
                          child: const Icon(
                            Icons.headphones,
                            color: depperBlue,
                            size: 20,
                          ),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctrl.chapterTitle.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ctrl.storyTitle.value,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                ctrl.currentTime,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: ctrl.togglePlay,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: depperBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ctrl.isPlaying.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Floating audio bubble ─────────────────────────────────────────────────────
class AudioBubble extends StatefulWidget {
  final AudioPlayerController ctrl;
  const AudioBubble({required this.ctrl, super.key});

  @override
  State<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<AudioBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotCtrl;
  Worker? _playWorker;
  Offset _pos = const Offset(20, 400);

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.ctrl.isPlaying.value) _rotCtrl.repeat();
    _playWorker = ever(widget.ctrl.isPlaying, (bool playing) {
      if (!mounted) return;
      if (playing) {
        _rotCtrl.repeat();
      } else {
        _rotCtrl.stop();
      }
    });
  }

  @override
  void dispose() {
    _playWorker?.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cover = widget.ctrl.coverUrl.value;

    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onPanUpdate:
              (d) => setState(() {
                _pos = Offset(
                  (_pos.dx + d.delta.dx).clamp(0.0, size.width - 90.0),
                  (_pos.dy + d.delta.dy).clamp(0.0, size.height - 90.0),
                );
              }),
          child: SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Rotating disc ───────────────────────────────────────────
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () {
                      widget.ctrl.hideBubble();
                      Get.to(
                        () => AudioPlayerScreen(
                          widget.ctrl.coverUrl.value,
                          widget.ctrl.author.value,
                          widget.ctrl.storyTitle.value,
                        ),
                        transition: Transition.downToUp,
                        duration: const Duration(milliseconds: 300),
                      );
                    },
                    child: RotationTransition(
                      turns: _rotCtrl,
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: depperBlue, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: depperBlue.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                          image:
                              cover.isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(cover),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          color: const Color(0xFF1e1e22),
                        ),
                        child:
                            cover.isEmpty
                                ? const Icon(
                                  Icons.headphones,
                                  color: depperBlue,
                                  size: 26,
                                )
                                : null,
                      ),
                    ),
                  ),
                ),

                // ── Play / pause button (bottom-right) ──────────────────────
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Obx(
                    () => GestureDetector(
                      onTap: widget.ctrl.togglePlay,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: depperBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.ctrl.isPlaying.value
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Cancel button (top-right) ───────────────────────────────
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: widget.ctrl.cancelAudio,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a2a),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade600,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Waveform widget ───────────────────────────────────────────────────────────
class _WaveformWidget extends StatefulWidget {
  final bool isPlaying;
  const _WaveformWidget({required this.isPlaying});

  @override
  State<_WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<_WaveformWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      12,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 60),
      ),
    );
    _animations =
        _controllers
            .map(
              (c) => Tween<double>(
                begin: 4,
                end: 28,
              ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
            )
            .toList();
    _sync();
  }

  @override
  void didUpdateWidget(_WaveformWidget old) {
    super.didUpdateWidget(old);
    if (old.isPlaying != widget.isPlaying) _sync();
  }

  void _sync() {
    for (int i = 0; i < _controllers.length; i++) {
      if (widget.isPlaying) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          if (mounted) {
            _controllers[i].repeat(reverse: true);
          }
        });
      } else {
        _controllers[i].animateTo(0.3);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    width: 160,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(
        _controllers.length,
        (i) => AnimatedBuilder(
          animation: _animations[i],
          builder:
              (_, __) => Container(
                width: 4,
                height: _animations[i].value,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: depperBlue.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
        ),
      ),
    ),
  );
}
