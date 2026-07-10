import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/local_storage.dart';

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
      Get.offAllNamed('/main_screen');
    } else {
      Get.offAllNamed('/onboarding_screen');
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Full-screen background image
            SizedBox.expand(
              // height: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/new_splash_screen.jpg',
                      // cacheHeight: 1200
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
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
