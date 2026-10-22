import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A background sound from the admin-managed library.
class AmbientSound {
  final int id;
  final String title;
  final String icon;
  final String url;

  const AmbientSound({
    required this.id,
    required this.title,
    required this.icon,
    required this.url,
  });

  factory AmbientSound.fromJson(Map m) => AmbientSound(
    id: (m['id'] as num).toInt(),
    title: m['title']?.toString() ?? '',
    icon: m['icon']?.toString() ?? '',
    url: m['url']?.toString() ?? '',
  );
}

class AmbientSoundCategory {
  final int id;
  final String name;
  final String icon;
  final List<AmbientSound> sounds;

  const AmbientSoundCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.sounds,
  });

  factory AmbientSoundCategory.fromJson(Map m) => AmbientSoundCategory(
    id: (m['id'] as num).toInt(),
    name: m['name']?.toString() ?? '',
    icon: m['icon']?.toString() ?? '',
    sounds: [
      for (final s in (m['sounds'] as List? ?? const []))
        if (s is Map) AmbientSound.fromJson(s),
    ],
  );
}

/// Plays one looping background sound while the reader reads. Lives as long
/// as the reading screen (it's deleted there, which stops the sound).
class AmbientSoundController extends GetxController {
  final AudioPlayer _player = AudioPlayer();

  final RxList<AmbientSoundCategory> categories = <AmbientSoundCategory>[].obs;
  final RxBool loadingLibrary = false.obs;
  final RxString libraryError = ''.obs;
  final Rxn<AmbientSound> current = Rxn<AmbientSound>();
  final RxBool isPlaying = false.obs;
  final RxBool isBuffering = false.obs;
  final RxDouble volume = 0.5.obs;

  StreamSubscription<PlayerState>? _stateSub;

  @override
  void onInit() {
    super.onInit();
    _player.setLoopMode(LoopMode.one);
    _stateSub = _player.playerStateStream.listen((st) {
      isPlaying.value = st.playing;
      isBuffering.value =
          st.processingState == ProcessingState.loading ||
          st.processingState == ProcessingState.buffering;
    });
    SharedPreferences.getInstance().then((p) {
      final v = p.getDouble('ambient_volume');
      if (v != null) {
        volume.value = v.clamp(0.0, 1.0);
        _player.setVolume(volume.value);
      }
    }).catchError((_) {});
    _player.setVolume(volume.value);
  }

  @override
  void onClose() {
    _stateSub?.cancel();
    _player.dispose();
    super.onClose();
  }

  /// Fetches the library. Called when the sound screen opens, not before.
  Future<void> loadLibrary({bool force = false}) async {
    if (loadingLibrary.value) return;
    if (categories.isNotEmpty && !force) return;
    loadingLibrary.value = true;
    libraryError.value = '';
    final res = await ApiService.getAmbientSounds();
    loadingLibrary.value = false;
    if (res['success'] == true) {
      final list = (res['data']?['categories'] as List?) ?? const [];
      categories.assignAll([
        for (final c in list)
          if (c is Map) AmbientSoundCategory.fromJson(c),
      ]);
    } else {
      libraryError.value =
          res['error']?.toString() ?? 'Could not load sounds.';
    }
  }

  Future<void> play(AmbientSound sound) async {
    if (current.value?.id == sound.id) {
      return isPlaying.value ? pause() : resume();
    }
    current.value = sound;
    try {
      // Cache to disk so the loop doesn't re-download the file every pass
      AudioSource source;
      try {
        source = LockCachingAudioSource(Uri.parse(sound.url));
      } catch (_) {
        source = AudioSource.uri(Uri.parse(sound.url));
      }
      await _player.setAudioSource(source);
      await _player.setLoopMode(LoopMode.one);
      _player.play();
      ApiService.ambientSoundPlayed(sound.id);
    } catch (_) {
      current.value = null;
      AppAlert.error('Could not play "${sound.title}". Check your connection.');
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() async {
    if (current.value != null) _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    current.value = null;
  }

  void setVolume(double v) {
    volume.value = v.clamp(0.0, 1.0);
    _player.setVolume(volume.value);
  }

  void saveVolume() {
    SharedPreferences.getInstance()
        .then((p) => p.setDouble('ambient_volume', volume.value))
        .catchError((_) => false);
  }
}

/// Opens the sound library over the reader.
Future<void> showAmbientSoundLibrary({required Color background}) {
  final ctrl =
      Get.isRegistered<AmbientSoundController>()
          ? Get.find<AmbientSoundController>()
          : Get.put(AmbientSoundController());
  ctrl.loadLibrary();
  return Get.bottomSheet(
    _AmbientSoundSheet(ctrl: ctrl, background: background),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _AmbientSoundSheet extends StatefulWidget {
  final AmbientSoundController ctrl;
  final Color background;
  const _AmbientSoundSheet({required this.ctrl, required this.background});

  @override
  State<_AmbientSoundSheet> createState() => _AmbientSoundSheetState();
}

class _AmbientSoundSheetState extends State<_AmbientSoundSheet> {
  int _selected = 0;

  AmbientSoundController get ctrl => widget.ctrl;

  @override
  Widget build(BuildContext context) {
    final dark = widget.background.computeLuminance() < 0.4;
    final fg = dark ? Colors.white : const Color(0xFF1F1F1F);
    final muted = dark ? Colors.white60 : Colors.black54;
    final card = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(LucideIcons.headphones, color: depperBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Background sounds',
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () =>
                        ctrl.current.value == null
                            ? const SizedBox.shrink()
                            : TextButton.icon(
                              onPressed: ctrl.stop,
                              icon: const Icon(Icons.stop_rounded, size: 18),
                              label: const Text('Stop'),
                              style: TextButton.styleFrom(
                                foregroundColor: depperBlue,
                              ),
                            ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Obx(() {
                if (ctrl.loadingLibrary.value && ctrl.categories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: depperBlue),
                    ),
                  );
                }
                if (ctrl.categories.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ctrl.libraryError.value.isNotEmpty
                              ? ctrl.libraryError.value
                              : 'No sounds yet — check back soon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted),
                        ),
                        if (ctrl.libraryError.value.isNotEmpty)
                          TextButton(
                            onPressed: () => ctrl.loadLibrary(force: true),
                            child: const Text('Try again'),
                          ),
                      ],
                    ),
                  );
                }
                final sel = _selected.clamp(0, ctrl.categories.length - 1);
                final cat = ctrl.categories[sel];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: ctrl.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = ctrl.categories[i];
                          final on = i == sel;
                          return ChoiceChip(
                            label: Text(
                              '${c.icon.isNotEmpty ? '${c.icon} ' : ''}${c.name}',
                            ),
                            selected: on,
                            onSelected: (_) => setState(() => _selected = i),
                            selectedColor: depperBlue,
                            backgroundColor: card,
                            labelStyle: TextStyle(
                              color: on ? Colors.white : fg,
                              fontSize: 13,
                            ),
                            side: BorderSide.none,
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                        itemCount: cat.sounds.length,
                        itemBuilder: (_, i) {
                          final s = cat.sounds[i];
                          return Obx(() {
                            final active = ctrl.current.value?.id == s.id;
                            final playing = active && ctrl.isPlaying.value;
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => ctrl.play(s),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color:
                                      active
                                          ? depperBlue.withValues(alpha: 0.15)
                                          : card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        active
                                            ? depperBlue
                                            : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      s.icon.isNotEmpty
                                          ? s.icon
                                          : (cat.icon.isNotEmpty
                                              ? cat.icon
                                              : '🎵'),
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      s.title,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: fg,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (active && ctrl.isBuffering.value)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: depperBlue,
                                        ),
                                      )
                                    else
                                      Icon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 16,
                                        color: active ? depperBlue : muted,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
            // Volume
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.volume_down_rounded, color: muted, size: 20),
                  Expanded(
                    child: Obx(
                      () => Slider(
                        value: ctrl.volume.value,
                        onChanged: ctrl.setVolume,
                        onChangeEnd: (_) => ctrl.saveVolume(),
                        activeColor: depperBlue,
                        inactiveColor: Colors.grey[700],
                      ),
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, color: muted, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
