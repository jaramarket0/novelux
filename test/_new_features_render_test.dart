// TEMPORARY — renders the new screens to PNGs for a visual check. Delete.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/listen/book_parser.dart';
import 'package:novelux/screen/listen/listen_chat_head.dart';
import 'package:novelux/screen/listen/listen_controller.dart';
import 'package:novelux/screen/listen/listen_home_screen.dart';
import 'package:novelux/screen/listen/listen_library.dart';
import 'package:novelux/screen/listen/listen_player_screen.dart';
import 'package:novelux/screen/reading_interface/ambient_sound.dart';
import 'package:novelux/screen/reading_interface/reading_interface.dart';
import 'package:novelux/screen/reading_interface/controller/reading_interface_controller.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

const flutterRoot = '/home/daniel/snap/flutter/common/flutter';
const lucide = '/home/daniel/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.14+2/assets';
final tmp = Directory.systemTemp.createTempSync('listen_shots');

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async => tmp.path;
  @override
  Future<String?> getTemporaryPath() async => tmp.path;
  @override
  Future<String?> getApplicationSupportPath() async => tmp.path;
  @override
  Future<String?> getApplicationCachePath() async => tmp.path;
}

class _Theme extends ThemeController {
  @override
  void onInit() {}
}

class _Sounds extends AmbientSoundController {
  @override
  Future<void> loadLibrary({bool force = false}) async {
    categories.assignAll([
      AmbientSoundCategory(id: 1, name: 'Rain', icon: '🌧️', sounds: const [
        AmbientSound(id: 1, title: 'Light rain', icon: '🌦️', url: 'x'),
        AmbientSound(id: 2, title: 'Thunderstorm', icon: '⛈️', url: 'x'),
        AmbientSound(id: 3, title: 'Rain on window', icon: '🪟', url: 'x'),
        AmbientSound(id: 4, title: 'Tin roof', icon: '🏚️', url: 'x'),
        AmbientSound(id: 5, title: 'Forest rain', icon: '🌲', url: 'x'),
      ]),
      AmbientSoundCategory(id: 2, name: 'Café', icon: '☕', sounds: const []),
      AmbientSoundCategory(id: 3, name: 'Fireplace', icon: '🔥', sounds: const []),
      AmbientSoundCategory(id: 4, name: 'Nature', icon: '🌿', sounds: const []),
    ]);
    current.value = categories.first.sounds[1];
    isPlaying.value = true;
  }
}

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await l.load();
}

Future<void> _setup() async {
  final m = '$flutterRoot/bin/cache/artifacts/material_fonts';
  await _font('Roboto', ['$m/Roboto-Regular.ttf', '$m/Roboto-Medium.ttf', '$m/Roboto-Bold.ttf', '$m/Roboto-Black.ttf']);
  kFontFamily;
  await GoogleFonts.pendingFonts();
  await _font('MaterialIcons', ['$m/MaterialIcons-Regular.otf']);
  await _font('packages/lucide_icons_flutter/Lucide', ['$lucide/lucide.ttf']);
  for (final w in [100, 200, 300, 400, 500, 600]) {
    await _font('packages/lucide_icons_flutter/Lucide$w', ['$lucide/build_font/LucideVariable-w$w.ttf']);
  }
  // Emoji (best effort)
  for (final f in ['/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf']) {
    if (File(f).existsSync()) await _font('Roboto', [f]);
  }
}

void _mockChannels() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in [
    'novelux/tts', 'novelux/media_notification',
    'com.ryanheise.just_audio.methods', 'com.ryanheise.audio_session',
    'dev.fluttercommunity.plus/wakelock_plus', 'github.com/clovisnicolas/flutter_screen_brightness',
    'com.flutterplaza.no_screenshot_methods', 'no_screenshot', 'screen_brightness',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (call) async => null);
  }
  messenger.setMockMethodCallHandler(
    MethodChannel('plugins.flutter.io/google_mobile_ads', StandardMethodCodec(AdMessageCodec())),
    (call) async => null,
  );
}

final _key = GlobalKey();

Future<void> _app(WidgetTester tester, Widget home, {Size size = const Size(390, 844), bool dark = true}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  await tester.pumpWidget(
    RepaintBoundary(
      key: _key,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light, fontFamily: 'Roboto'),
        home: home,
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final b = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/new_feature_screens/$name.png')..createSync(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

ParsedBook _book(String title, String author, int chapters) => ParsedBook(title, author, [
  for (var c = 0; c < chapters; c++)
    ParsedChapter(c == 0 ? 'Chapter 1: The Letter' : 'Chapter ${c + 1}', [
      'The rain had not stopped for three days when the letter arrived. Mara turned it over twice before she '
          'opened it, as if the paper might change its mind.',
      'Inside was a single line, written in her grandmother\'s careful hand. “Come home before the river rises.” '
          'She read it again. Then she packed a bag.',
      'The train north was nearly empty. Fields slid past the window, grey and patient, and somewhere past the '
          'second station she fell asleep with the letter still folded in her palm.',
      'When she woke, the conductor was standing over her. “Last stop,” he said. “Nobody gets off here any more.”',
      'She stepped onto the platform anyway.',
    ]),
]);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    PathProviderPlatform.instance = _FakePaths();
    _mockChannels();
    await _setup();
  });

  testWidgets('listen empty', (tester) async {
    Get.reset();
    Get.put<ThemeController>(_Theme());
    await _app(tester, const ListenHomeScreen());
    await _settle(tester);
    await _save(tester, '1_listen_empty');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('listen library + player', (tester) async {
    Get.reset();
    Get.put<ThemeController>(_Theme());
    final store = ListenLibraryStore.instance;
    late ListenBook a;
    await tester.runAsync(() async {
      a = await store.addBook(_book('The River House', 'Ada Okafor', 24), 'epub');
      final b = await store.addBook(_book('Notes on Quiet Places', 'J. Mensah', 9), 'pdf');
      final c = await store.addBook(_book('Midnight Market', '', 15), 'docx');
      a..chapter = 0..paragraph = 1..lastOpenedAt = DateTime(2026, 10, 22);
      b..chapter = 4;
      c.finished = true;
      a.bookmarks.add(ListenBookmark(chapter: 0, paragraph: 1, snippet: 'Inside was a single line…', createdAt: DateTime.now()));
      await store.saveBooks([a, b, c]);
    });
    await _app(tester, const ListenHomeScreen());
    await _settle(tester);
    final player = Get.find<ListenPlayerController>();
    await tester.runAsync(() => player.open(a));
    await _settle(tester);
    await _save(tester, '2_listen_library');

    // Player, mid-sentence with a word highlighted
    player.paragraphIndex.value = 1;
    player.sentenceIndex.value = 1;
    player.isPlaying.value = true;
    player.wordStart.value = 0;
    player.wordEnd.value = 4;
    player.setSleepTimer(const Duration(minutes: 14, seconds: 32));
    Get.to(() => const ListenPlayerScreen());
    await _settle(tester);
    await _save(tester, '3_listen_player');

    await tester.tap(find.textContaining('1.0×'));
    await _settle(tester);
    await _save(tester, '4_listen_speed_sheet');
    Get.back();
    await _settle(tester);

    await tester.tap(find.byTooltip('Contents'));
    await _settle(tester);
    await _save(tester, '5_listen_contents');
    Get.back();
    await _settle(tester);
    player.cancelSleepTimer();
    player.isPlaying.value = false;
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ambient sounds sheet', (tester) async {
    Get.reset();
    Get.put<ThemeController>(_Theme());
    Get.put<AmbientSoundController>(_Sounds());
    await _app(tester, Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Builder(builder: (ctx) {
        return Center(
          child: TextButton(
            onPressed: () => showAmbientSoundLibrary(background: const Color(0xFF1a1a1a)),
            child: const Text('open'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await _settle(tester);
    await _save(tester, '6_background_sounds');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reader settings + auto scroll', (tester) async {
    Get.reset();
    Get.put<ThemeController>(_Theme());
    final text = List.generate(40, (i) =>
        '<p>Paragraph ${i + 1}. The lamps along the harbour came on one by one, and the boats rocked '
        'gently against the stone as the tide turned and the town settled into night.</p>').join();
    await _app(tester, NovelUpReadingInterface(
      storyTitle: 'The River House',
      chapterTitle: 'Chapter 1: The Letter',
      chapterNumber: 1,
      totalChapter: 1,
      author: 'Ada Okafor',
      coverUrl: '',
      offlineContent: {1: text},
    ));
    await _settle(tester);
    final ctrl = Get.find<ReadingInterfaceController>();
    ctrl.chapterContent.value = text;
    ctrl.toggleSettings();
    await _settle(tester);
    await _save(tester, '7_reader_settings');
    // Scroll the settings panel to the new sections
    await tester.drag(find.text('Background color'), const Offset(0, -260));
    await _settle(tester);
    await _save(tester, '8_reader_settings_autoscroll');

    ctrl.hideAllControls();
    ctrl.setAutoScrollMode('Custom');
    ctrl.startAutoScroll();
    ctrl.pauseAutoScroll();
    await _settle(tester);
    await _save(tester, '9_reader_autoscroll_control');
    ctrl.stopAutoScroll();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('story listen + chat head', (tester) async {
    Get.reset();
    Get.put<ThemeController>(_Theme());
    final html = List.generate(8, (i) =>
        '<p>${i == 1 ? 'She stepped onto the platform. The town was quieter than she remembered, and the river louder.' : 'The lamps along the harbour came on one by one, and the boats rocked gently against the stone.'}</p>').join();
    final c = StoryListen.controller;
    await tester.runAsync(() => c.openStoryChapter(
      slug: 'river-house', storyTitle: 'I Came Back To Make My Ex Husband Pay', author: 'Riana Rain',
      cover: 'assets/images/_tmp_cover_main.png', chapterNumber: 5, chapterTitle: 'Chapter 5',
      html: html, totalChapters: 32));
    c.paragraphIndex.value = 1;
    c.isPlaying.value = true;
    c.wordStart.value = 4;
    c.wordEnd.value = 11;
    await _app(tester, const ListenPlayerScreen(tag: StoryListen.tag));
    await _settle(tester);
    await _save(tester, '10_story_listen_player');

    // Leave everything: the floating head over another screen
    ListenChatHead.instance.playerClosed();
    await _app(tester, Builder(builder: (context) => Stack(children: [
      Scaffold(
        backgroundColor: const Color(0xFF0d0d0f),
        appBar: AppBar(title: const Text('Explore'), backgroundColor: const Color(0xFF0d0d0f)),
        body: ListView(children: [for (var i = 0; i < 8; i++) ListTile(title: Text('Story ${i + 1}'), subtitle: const Text('Romance · 32 chapters'))]),
      ),
      const ListenChatHeadLayer(),
    ])));
    await _settle(tester);
    await _save(tester, '11_floating_head');

    // Dragging shows the × target
    final g = await tester.startGesture(tester.getCenter(find.byIcon(Icons.pause_rounded)) - const Offset(24, 24));
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(-14, 12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await _save(tester, '12_floating_head_dragging');
    await g.up();
    await _settle(tester);
    c.isPlaying.value = false;
    await tester.pumpWidget(const SizedBox());
  });
}
