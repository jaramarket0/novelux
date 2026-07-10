import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novelux/screen/explore/explore_screen.dart';

void main() {
  testWidgets('shows a fallback card when no featured stories are available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeaturedCarouselSection(
            stories: const [],
            txt: Colors.black,
            cardBg: Colors.white,
            carouselController: CarouselSliderController(),
            coverUrlBuilder: (_) => '',
            onStoryTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Featured stories will appear soon'), findsOneWidget);
  });
}
