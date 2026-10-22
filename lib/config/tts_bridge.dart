import 'package:flutter/services.dart';

/// One owner at a time for the native text-to-speech and media-notification
/// channels.
///
/// A MethodChannel has a single Dart handler, so the chapter audio player and
/// the "Listen to your books" player can't both listen to it. Whoever starts
/// speaking calls [claim]; the previous owner is told to stop through its
/// `onPreempted` callback, and events go to the new owner only.
class TtsBridge {
  TtsBridge._() {
    tts.setMethodCallHandler((call) async => _owner?.onTts(call));
    media.setMethodCallHandler((call) async => _owner?.onMedia(call));
  }

  static final TtsBridge instance = TtsBridge._();

  static const tts = MethodChannel('novelux/tts');
  static const media = MethodChannel('novelux/media_notification');

  TtsOwner? _owner;

  /// Make [owner] the receiver of TTS and media events.
  void claim(TtsOwner owner) {
    if (identical(_owner, owner)) return;
    final previous = _owner;
    _owner = owner;
    previous?.onPreempted();
  }

  /// Give up the channels (only if [owner] still holds them).
  void release(TtsOwner owner) {
    if (identical(_owner, owner)) _owner = null;
  }

  bool owns(TtsOwner owner) => identical(_owner, owner);

  /// Installed voices: [{name, locale, network, quality, label?}].
  Future<List<Map<String, dynamic>>> voices() async {
    try {
      final list = await tts.invokeMethod<List>('getVoices') ?? const [];
      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

/// Something that plays speech through [TtsBridge].
abstract class TtsOwner {
  Future<dynamic> onTts(MethodCall call);
  Future<dynamic> onMedia(MethodCall call);

  /// Another player took over the speech engine — stop or pause.
  void onPreempted();
}
