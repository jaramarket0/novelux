import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/about/controller/about_controller.dart';
import 'package:novelux/screen/me/atomic_webview_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';

class AboutScreen extends GetWidget<AboutController> {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
        final onBg =
            !isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
        final cardBg =
            isDark ? const Color.fromARGB(255, 33, 35, 36) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;

        return SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              centerTitle: true,
              title: Text('About', style: TextStyle(color: txt, fontSize: 14)),
              leading: IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: sub),
                onPressed: () {
                  Get.back();
                },
              ),
            ),
            body: Container(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 120),
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomImageView(
                        imagePath: 'assets/images/1024.png',
                        radius: BorderRadius.circular(8),
                        placeHolder: 'assets/images/novelux_placeholder_transcpr.jpg',
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'NoveluX',
                    style: TextStyle(
                      color: txt,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('version 1.1.1.1', style: TextStyle(color: sub)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: depperBlue,
                    ),
                    child: Text(
                      'Check for updates',
                      style: TextStyle(color: txt),
                    ),
                  ),
                  Spacer(),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => AtomicWebViewScreen(
                                  url: 'https://novelux.onrender.com/terms/',
                                ),
                              );
                            },
                            child: Text(
                              'Terms of services',
                              style: TextStyle(
                                color: txt,
                                fontSize: 12,
                                fontFamily: kFontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => AtomicWebViewScreen(
                                  url: 'https://novelux.onrender.com/privacy/',
                                ),
                              );
                            },
                            child: Text(
                              'privacy policy',
                              style: TextStyle(
                                color: txt,
                                fontSize: 12,
                                fontFamily: kFontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => AtomicWebViewScreen(
                                  url:
                                      'https://novelux.onrender.com/copyright-policy/',
                                ),
                              );
                            },
                            child: Text(
                              'copyright policy',
                              style: TextStyle(
                                color: txt,
                                fontSize: 12,
                                fontFamily: kFontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Get.to(
                            () => AtomicWebViewScreen(
                              url: 'https://novelux.onrender.com/cookies/',
                            ),
                          );
                        },
                        child: Text(
                          'cookie policy',
                          style: TextStyle(
                            color: txt,
                            fontSize: 12,
                            fontFamily: kFontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'c copyright 2025 DanTech Software. Ltd All rights Reserved.',
                        style: TextStyle(
                          color: sub,
                          fontSize: 12,
                          fontFamily: kFontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
