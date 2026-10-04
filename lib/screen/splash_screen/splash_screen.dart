import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/local_storage.dart';
import 'package:novelux/screen/auth/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final db = Get.find<DataBase>();
    final token = await db.getToken();
    if (token.isNotEmpty) {
      final auth = Get.find<AuthController>();
      auth.isLoggedIn.value = true;
      await auth.fetchMe();
      auth.routePostAuth();
      return;
    }
    // Signed out readers go straight into the app as guests. Browsing,
    // bookmarks, downloads and history all work without an account, so there
    // is nothing to introduce or gate before the catalogue.
    Get.offAllNamed('/main_screen');
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Android matches the native splash's black so there's no flash
      backgroundColor:
          defaultTargetPlatform == TargetPlatform.iOS
              ? background
              : Colors.black,
      body: FadeTransition(
        // Android continues the native splash, so it must not fade in
        opacity:
            defaultTargetPlatform == TargetPlatform.iOS
                ? _fadeAnim
                : kAlwaysCompleteAnimation,
        child: Stack(
          children: [
            // iOS (still NoveluX): the full-screen artwork.
            // Android (HuxNovel): the wordmark on black, at the same size and
            // spot as the native splash so the hand-over is seamless.
            if (defaultTargetPlatform == TargetPlatform.iOS)
              SizedBox.expand(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/new-splash-screen.png',
                        // cacheHeight: 1200
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            else
              const _HuxNovelSplash(),
            // Content overlay
            // Center(
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       const Icon(
            //         Icons.menu_book,
            //         color: Colors.white,
            //         size: 50,
            //       ),
            //       const SizedBox(height: 24),
            //       Text(
            //         'NoveluX',
            //         style: TextStyle(
            //           fontSize: 36,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.white,
            //           letterSpacing: 2,
            //         ),
            //       ),
            //       const SizedBox(height: 8),
            //       const Text(
            //         'Read. Write. Earn.',
            //         style: TextStyle(
            //           color: Colors.grey,
            //           fontSize: 16,
            //           letterSpacing: 1,
            //         ),
            //       ),
            //       const SizedBox(height: 60),
            //       SizedBox(
            //         width: 30,
            //         height: 30,
            //         child: CircularProgressIndicator(
            //           color: depperBlue,
            //           strokeWidth: 2,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _HuxNovelSplash extends StatelessWidget {
  const _HuxNovelSplash();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 172dp = the wordmark's width inside the native splash image
        Center(
          child: Image.asset('assets/images/huxnovel_wordmark.png', width: 172),
        ),
        Align(
          alignment: const Alignment(0, 0.16),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder:
                (_, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - t)),
                    child: child,
                  ),
                ),
            child: const Text(
              'Read. Discover. Escape.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
