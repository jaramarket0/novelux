import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';

import 'listen_controller.dart';
import 'listen_player_screen.dart';

/// The player that reads HuxNovel chapters aloud from the reading screen.
/// It outlives the reader so listening can carry on around the app.
class StoryListen {
  static const tag = 'story';

  static ListenPlayerController get controller {
    if (Get.isRegistered<ListenPlayerController>(tag: tag)) {
      return Get.find<ListenPlayerController>(tag: tag);
    }
    final c = Get.put(ListenPlayerController(), tag: tag, permanent: true);
    ever(c.book, (_) => ListenChatHead.instance.refresh());
    ever(c.isPlaying, (_) => ListenChatHead.instance.refresh());
    return c;
  }

  static bool get isRegistered =>
      Get.isRegistered<ListenPlayerController>(tag: tag);

  /// A chapter is loaded in the player (playing or paused).
  static bool get active => isRegistered && controller.book.value != null;

  static bool get isPlaying => active && controller.isPlaying.value;

  /// Where listening got to, so the reader can catch up when it's shown again
  /// (kept after "Stop listening" too).
  static String? lastSlug;
  static int lastChapter = 0;
  static String lastChapterTitle = '';

  static void rememberPosition() {
    if (!active || !controller.isStory) return;
    lastSlug = controller.storySlug;
    lastChapter = controller.storyChapterNumber;
    lastChapterTitle = controller.chapterTitle;
  }

  static void openPlayer() => Get.to(
    () => const ListenPlayerScreen(tag: tag),
    transition: Transition.downToUp,
    duration: const Duration(milliseconds: 300),
  );
}

/// Decides when the floating "chat head" shows: while a chapter is being
/// listened to and neither the reading screen nor the player is on screen.
class ListenChatHead {
  ListenChatHead._();
  static final ListenChatHead instance = ListenChatHead._();

  final RxBool visible = false.obs;
  int _readersOpen = 0;
  bool _playerOpen = false;
  bool _armed = false; // shown once the reader is left mid-listen

  bool get readerOpen => _readersOpen > 0;

  /// The listening player is on screen (still true while it's closing).
  bool get playerIsOpen => _playerOpen;

  void readerOpened() {
    _readersOpen++;
    refresh();
  }

  void readerClosed() {
    _readersOpen = math.max(0, _readersOpen - 1);
    if (_readersOpen == 0 && StoryListen.isPlaying) _armed = true;
    refresh();
  }

  void playerOpened() {
    _playerOpen = true;
    refresh();
  }

  void playerClosed() {
    _playerOpen = false;
    // Opened from the chat head (no reader behind it): bring the head back
    if (_readersOpen == 0 && StoryListen.active) _armed = true;
    refresh();
  }

  void refresh() {
    if (!StoryListen.active) _armed = false;
    visible.value = _armed && StoryListen.active && _readersOpen == 0 && !_playerOpen;
  }
}

/// Put above the whole app (GetMaterialApp.builder) so the head floats over
/// every screen, like a Messenger chat head.
class ListenChatHeadLayer extends StatelessWidget {
  const ListenChatHeadLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () =>
          ListenChatHead.instance.visible.value
              ? const _ChatHead()
              : const SizedBox.shrink(),
    );
  }
}

class _ChatHead extends StatefulWidget {
  const _ChatHead();

  @override
  State<_ChatHead> createState() => _ChatHeadState();
}

class _ChatHeadState extends State<_ChatHead> with TickerProviderStateMixin {
  static const double _size = 62; // the cover circle
  static const double _box = _size + 14; // with the pulse and ring around it
  static const double _margin = 4;
  static const double _magnetRadius = 90;

  // Remembered across shows so the head comes back where it was left
  static Offset? _saved;

  late Offset _pos;
  bool _placed = false;
  bool _dragging = false;
  bool _overTarget = false;
  bool _dismissing = false;
  DateTime _magnetUntil = DateTime(2000);

  late final AnimationController _snap = AnimationController.unbounded(vsync: this);
  Offset _snapFrom = Offset.zero, _snapTo = Offset.zero;

  late final AnimationController _appear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.9,
    upperBound: 1,
    value: 1,
  );

  ListenPlayerController get p => StoryListen.controller;

  @override
  void initState() {
    super.initState();
    _snap.addListener(() {
      setState(() => _pos = Offset.lerp(_snapFrom, _snapTo, _snap.value)!);
    });
  }

  @override
  void dispose() {
    _saved = _placed ? _pos : _saved;
    _snap.dispose();
    _appear.dispose();
    _pulse.dispose();
    _press.dispose();
    super.dispose();
  }

  Size get _screen => MediaQuery.of(context).size;
  EdgeInsets get _safe => MediaQuery.of(context).padding;

  Offset get _targetCenter =>
      Offset(_screen.width / 2, _screen.height - _safe.bottom - 70);

  double get _minY => _safe.top + _margin;
  double get _maxY => _screen.height - _safe.bottom - _box - 120;

  Offset _clampToEdge(Offset raw, {double vx = 0}) {
    // Throw it and it flies to the side it's heading for
    final projectedX = raw.dx + vx * 0.18;
    final left = projectedX + _box / 2 < _screen.width / 2;
    return Offset(
      left ? _margin : _screen.width - _box - _margin,
      raw.dy.clamp(_minY, math.max(_minY, _maxY)),
    );
  }

  void _animateTo(Offset to, {double velocity = 0}) {
    _snapFrom = _pos;
    _snapTo = to;
    final dist = (to - _pos).distance;
    _snap.value = 0;
    _snap.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 260, damping: 20),
        0,
        1,
        dist == 0 ? 0 : (velocity / dist).clamp(-8.0, 8.0),
      ),
    );
  }

  void _onPanStart(DragStartDetails _) {
    _snap.stop();
    setState(() => _dragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final next = _pos + d.delta;
    final center = next + const Offset(_box / 2, _box / 2);
    final near = (center - _targetCenter).distance < _magnetRadius;
    if (near != _overTarget) {
      HapticFeedback.selectionClick();
      // Glide onto / off the × instead of jumping
      _magnetUntil = DateTime.now().add(const Duration(milliseconds: 180));
    }
    setState(() {
      _pos = next;
      _overTarget = near;
    });
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    setState(() => _dragging = false);
    if (_overTarget) {
      // Dropped on the ×: stop listening
      setState(() => _dismissing = true);
      HapticFeedback.mediumImpact();
      await _appear.reverse();
      _overTarget = false;
      StoryListen.rememberPosition();
      await p.stopSession();
      ListenChatHead.instance.refresh();
      return;
    }
    final v = d.velocity.pixelsPerSecond;
    final to = _clampToEdge(_pos + Offset(0, v.dy * 0.12), vx: v.dx);
    _animateTo(to, velocity: v.distance);
  }

  void _open() {
    HapticFeedback.lightImpact();
    StoryListen.openPlayer();
  }

  @override
  Widget build(BuildContext context) {
    if (!_placed) {
      _pos = _saved ?? Offset(_screen.width - _box - _margin, _screen.height * 0.62);
      _pos = _clampToEdge(_pos);
      _placed = true;
    }
    // Pulled onto the × while hovering over it
    final shown = _overTarget && !_dismissing
        ? _targetCenter - const Offset(_box / 2, _box / 2)
        : _pos;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dismiss zone, shown while dragging
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _dragging ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: _targetCenter.dx - 30,
            top: _targetCenter.dy - 30,
            child: IgnorePointer(
              child: AnimatedScale(
                scale: _dragging ? (_overTarget ? 1.25 : 1) : 0.4,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: _dragging ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ),
          // The head
          AnimatedPositioned(
            duration: DateTime.now().isBefore(_magnetUntil)
                ? const Duration(milliseconds: 160)
                : Duration.zero,
            curve: Curves.easeOut,
            left: shown.dx,
            top: shown.dy,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: _appear, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn),
              child: ScaleTransition(
                scale: _press,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onTapDown: (_) => _press.reverse(),
                  onTapCancel: () => _press.forward(),
                  onTapUp: (_) => _press.forward(),
                  onTap: _open,
                  child: _head(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _head() => Obx(() {
    final playing = p.isPlaying.value;
    final paras = p.paragraphs.length;
    final progress = paras == 0 ? 0.0 : (p.paragraphIndex.value + 1) / paras;
    final loading = p.fetchingNextChapter.value;
    return SizedBox(
      width: _size + 14,
      height: _size + 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft pulse while the voice is speaking
          if (playing)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t = _pulse.value;
                return Container(
                  width: _size + 14 * t,
                  height: _size + 14 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: depperBlue.withValues(alpha: 0.28 * (1 - t)),
                  ),
                );
              },
            ),
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(child: _cover()),
          ),
          // Chapter progress ring
          SizedBox(
            width: _size + 4,
            height: _size + 4,
            child: CircularProgressIndicator(
              value: loading ? null : progress,
              strokeWidth: 3,
              color: depperBlue,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          // Play / pause badge
          Positioned(
            right: 4,
            bottom: 4,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                p.togglePlay();
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: depperBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });

  Widget _cover() {
    final url = p.storyCover;
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFC15F3C), Color(0xFF7A2E17)]),
      ),
      child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 28),
    );
    if (url.isEmpty) return fallback;
    final image = url.startsWith('http')
        ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
        : Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    return SizedBox.expand(child: image);
  }
}
