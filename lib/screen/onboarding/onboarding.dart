import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pc = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon':     Icons.menu_book,
      'title':    'Discover Stories',
      'subtitle': 'Explore thousands of novels across romance, fantasy, thriller, African fiction and more.',
      'color':    const Color(0xFF0288D1),
    },
    {
      'icon':     Icons.favorite,
      'title':    'Your Favorites, All Here',
      'subtitle': 'From binge-worthy romance to edge-of-your-seat thrillers — the stories you love are waiting for you.',
      'color':    const Color(0xFF7B1FA2),
    },
    {
      'icon':     Icons.auto_stories,
      'title':    'Read Anytime, Anywhere',
      'subtitle': 'Pick up right where you left off. New chapters, fresh stories, and your next obsession — every day.',
      'color':    const Color(0xFF00897B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: (p['color'] as Color).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 60),
                    ),
                    const SizedBox(height: 40),
                    Text(p['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(p['subtitle'] as String,
                        style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.6),
                        textAlign: TextAlign.center),
                  ]),
                );
              },
            ),
          ),

          // Dots
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
            _pages.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == i ? depperBlue : Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),

          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: depperBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      Get.offAllNamed('/login_screen');
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_currentPage == _pages.length - 1)
                TextButton(
                  onPressed: () => Get.offAllNamed('/main_screen'),
                  child: const Text('Browse as Guest', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              if (_currentPage < _pages.length - 1)
                TextButton(
                  onPressed: () => Get.offAllNamed('/login_screen'),
                  child: const Text('Skip', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
            ]),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}
