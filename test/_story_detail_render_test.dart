// TEMPORARY — renders StoryDetailScreen to PNGs for a visual check. Delete.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/screen/reading_interface/reading_position_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const slug = 'ex-husband-pay';
const flutterRoot = '/home/daniel/snap/flutter/common/flutter';
const lucide =
    '/home/daniel/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.14+2/assets';

class _Theme extends ThemeController {
  @override
  void onInit() {}
}

class _Ctrl extends StoryDetailController {
  @override
  Future<void> loadStory(String slug, {bool silent = false}) async {}
  @override
  String getCoverUrl(Map? s) => s?['cover_image']?.toString() ?? '';
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
  final roboto = [
    '$m/Roboto-Regular.ttf',
    '$m/Roboto-Medium.ttf',
    '$m/Roboto-Bold.ttf',
    '$m/Roboto-Black.ttf',
  ];
  await _font('Roboto', roboto);
  kFontFamily;
  await GoogleFonts.pendingFonts();
  await _font('MaterialIcons', ['$m/MaterialIcons-Regular.otf']);
  await _font('packages/lucide_icons_flutter/Lucide', ['$lucide/lucide.ttf']);
  for (final w in [100, 200, 300, 400, 500, 600]) {
    await _font('packages/lucide_icons_flutter/Lucide$w', [
      '$lucide/build_font/LucideVariable-w$w.ttf',
    ]);
  }
}

_Ctrl _seed() {
  final c = _Ctrl();
  c.story.value = {
    'slug': slug,
    'title': 'I Came Back To Make My Ex Husband Pay',
    'cover_image': 'assets/images/_tmp_cover_main.png',
    'author': {'username': 'Riana Rain', 'followers_count': 0},
    'language': 'en',
    'age_rating': '18+',
    'status': 'ongoing',
    'total_views': 8,
    'total_chapters': 32,
    'genre': {'name': 'Romance', 'slug': 'romance'},
    'description':
        '"Get Cassian Devereaux to fall in love with Seraphina Voss. Then break his heart."\n\n'
        '"An eye for an eye. A father for a daughter. Make him suffer the way he made us suffer."\n\n'
        "Seraphina never wanted revenge. But when her mother's dying wish is delivered wrapped in a name she's spent years running from, she has no choice.",
    'tags': [
      for (final t in [
        'Billionaire CEO',
        'Hidden Identity',
        'Love Triangle',
        'Revenge',
        'Slow Burn Romance',
      ])
        {'name': t},
    ],
  };
  c.chapters.value = [
    for (var i = 1; i <= 32; i++)
      {
        'chapter_number': i,
        'title': 'Chapter $i',
        'word_count': 1100 + (i * 37) % 700,
        'is_locked': i > 20,
        'coin_cost': i > 20 ? 15 : 0,
      },
  ];
  c.reviews.value = [
    {
      'user': {'username': 'amaka.reads'},
      'rating': 'recommend',
      'content':
          'The first two chapters hooked me. Seraphina is such a sharp lead.',
    },
  ];
  c.reviewCount.value = 1;
  c.similarStories.value = [
    {
      'slug': 'a',
      'title': 'Beautiful Ruins',
      'cover_image': 'assets/images/_tmp_cover_s1.png',
      'genre': {'name': 'Romance'},
      'total_chapters': 12,
    },
    {
      'slug': 'b',
      'title': 'The Second Chance',
      'cover_image': 'assets/images/_tmp_cover_s2.png',
      'genre': {'name': 'Romance'},
      'total_chapters': 4,
    },
    {
      'slug': 'c',
      'title': 'Betrayed By My Spoiled Billionaire',
      'cover_image': 'assets/images/_tmp_cover_s3.png',
      'genre': {'name': 'Billionaire'},
      'total_chapters': 12,
    },
  ];
  c.position.value = ReadingPosition(
    chapter: 2,
    chapterTitle: 'Chapter 2',
    fraction: 0.4,
    savedAt: DateTime(2026, 10, 21),
  );
  c.accentColor.value = const Color(0xFF695B4E);
  c.totalChapters.value = 32; // only a page of chapters is loaded on open
  return c;
}

Future<void> _shot(
  WidgetTester tester, {
  required String name,
  required Size size,
  required bool dark,
  double scrollBy = 0,
}) async {
  Get.reset();
  Get.put<ThemeController>(_Theme());
  Get.put<StoryDetailController>(_seed(), tag: slug);

  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          fontFamily: 'Roboto',
        ),
        home: const StoryDetailScreen(slug: slug),
      ),
    ),
  );
  await tester.runAsync(() async {
    for (final el in find.byType(Image).evaluate()) {
      await precacheImage((el.widget as Image).image, el);
    }
  });
  await tester.pump();
  if (scrollBy > 0) {
    await tester.drag(find.byType(CustomScrollView), Offset(0, -scrollBy));
    await tester.pumpAndSettle();
  }
  await tester.pump(const Duration(milliseconds: 400));

  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/story_detail_screens/$name.png')
      ..createSync(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await _setup();
  });

  testWidgets('render', (tester) async {
    await _shot(
      tester,
      name: '1_light_full',
      size: const Size(390, 2050),
      dark: false,
    );
    await _shot(
      tester,
      name: '2_light_scrolled',
      size: const Size(390, 844),
      dark: false,
      scrollBy: 640,
    );
    await _shot(
      tester,
      name: '3_dark_full',
      size: const Size(390, 2050),
      dark: true,
    );
  });
}
