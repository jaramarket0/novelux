import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_style.dart';

const _items = [
  (LucideIcons.libraryBig400, 'nav_library'),
  (LucideIcons.bubbles, 'nav_explorer'),
  (LucideIcons.command, 'nav_genres'),
  (LucideIcons.userRound, 'nav_me'),
];

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final bottomInset = MediaQuery.of(context).padding.bottom;

        return Container(
          color: Colors.transparent,
          padding: EdgeInsets.fromLTRB(
            12,
            0,
            12,
            bottomInset > 0 ? bottomInset : 10,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.9),
                    width: 0.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sliding pill indicator
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOut,
                      alignment: Alignment(
                        -1.0 + (2.0 * currentIndex / (_items.length - 1)),
                        0,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 1 / _items.length,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: depperBlue.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Tab items
                    Row(
                      children: List.generate(_items.length, (i) {
                        final selected = i == currentIndex;
                        final icon = _items[i].$1;
                        final label = _items[i].$2;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onTap(i),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: selected ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  child: Icon(
                                    icon,
                                    size: 22,
                                    color:
                                        selected
                                            ? const Color(0xFFC55A11)
                                            : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        selected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                    color:
                                        selected
                                            ? const Color(0xFFC55A11)
                                            : sub,
                                  ),
                                  child: Text(label.tr),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
