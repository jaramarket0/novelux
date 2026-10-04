// ══════════════════════════════════════════════════════════════════════════════
//  Native Liquid Glass — iOS 26+ only
//
//  On iOS 26+ these widgets put Apple's real Liquid Glass material (SwiftUI
//  `glassEffect`, via cupertino_native_better) behind the app's own content.
//  Everywhere else — Android, iOS ≤ 25 — they render exactly what the screen
//  rendered before, so those platforms are untouched.
//
//  Pattern: a surface asks `AppGlass` for a builder flag and drops its opaque
//  background when glass is on, keeping its own icons, colours and layout:
//
//    AppGlass(
//      cornerRadius: 14,
//      builder: (context, glass) => Container(
//        color: glass ? Colors.transparent : cardBg,
//        child: ...,
//      ),
//    )
//
//  Don't put AppGlass inside long scrolling lists — each one is a native
//  platform view, and dozens of them scrolling will stutter. Use it for bars,
//  floating cards, sheets and dialogs.
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:io' show Platform;

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// True when the device can render Apple's native Liquid Glass.
bool get nativeGlass =>
    !kIsWeb && Platform.isIOS && PlatformVersion.supportsLiquidGlass;

class AppGlass extends StatelessWidget {
  const AppGlass({
    super.key,
    required this.builder,
    this.cornerRadius = 16,
    this.shape = CNGlassEffectShape.rect,
    this.effect = CNGlassEffect.regular,
    this.tint,
    this.interactive = false,
    this.forceDark = false,
  });

  /// Builds the surface. `glass` is true when native glass sits behind it —
  /// drop the opaque background (and drop shadows/borders) in that case.
  final Widget Function(BuildContext context, bool glass) builder;

  final double cornerRadius;
  final CNGlassEffectShape shape;
  final CNGlassEffect effect;
  final Color? tint;

  /// Touch-reactive glass (the lens "squish" on press). For buttons/bars.
  final bool interactive;

  /// Surfaces designed dark in both themes (most sheets/dialogs here) need
  /// dark glass even in light mode, or their white text loses contrast.
  final bool forceDark;

  @override
  Widget build(BuildContext context) {
    if (!nativeGlass) return builder(context, false);

    final theme = Theme.of(context);
    Widget glass = LiquidGlassContainer(
      config: LiquidGlassConfig(
        effect: effect,
        shape: shape,
        cornerRadius: cornerRadius,
        tint: tint,
        interactive: interactive,
      ),
      // Content keeps the real theme even when the glass is forced dark.
      child: Theme(data: theme, child: builder(context, true)),
    );
    if (forceDark && theme.brightness != Brightness.dark) {
      // LiquidGlassContainer reads brightness from the (Cupertino) theme.
      glass = Theme(
        data: theme.copyWith(brightness: Brightness.dark),
        child: glass,
      );
    }
    return glass;
  }
}

/// Drop-in for the app's [AlertDialog]s: identical on Android / iOS ≤ 25,
/// a Liquid Glass panel on iOS 26+.
class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.backgroundColor,
    this.insetPadding,
    this.contentPadding,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final EdgeInsets? insetPadding;
  final EdgeInsetsGeometry? contentPadding;

  static const _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    if (!nativeGlass) {
      return AlertDialog(
        title: title,
        content: content,
        actions: actions,
        backgroundColor: backgroundColor,
        insetPadding: insetPadding,
        contentPadding: contentPadding,
      );
    }

    // Same layout as a Material 3 AlertDialog, minus the opaque Material.
    final theme = Theme.of(context);
    final dialogTheme = DialogTheme.of(context);
    final isDarkSurface =
        backgroundColor != null &&
        ThemeData.estimateBrightnessForColor(backgroundColor!) ==
            Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      child: AppGlass(
        cornerRadius: _radius,
        forceDark: isDarkSurface,
        builder:
            (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      content == null ? 20 : 16,
                    ),
                    child: DefaultTextStyle(
                      style:
                          dialogTheme.titleTextStyle ??
                          theme.textTheme.headlineSmall!,
                      child: title!,
                    ),
                  ),
                if (content != null)
                  Flexible(
                    child: Padding(
                      padding:
                          contentPadding ??
                          EdgeInsets.fromLTRB(24, title == null ? 24 : 0, 24, 24),
                      child: DefaultTextStyle(
                        style:
                            dialogTheme.contentTextStyle ??
                            theme.textTheme.bodyMedium!,
                        child: content!,
                      ),
                    ),
                  ),
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.end,
                      spacing: 8,
                      overflowAlignment: OverflowBarAlignment.end,
                      children: actions!,
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}

/// Wrap a bottom sheet's root: Liquid Glass on iOS 26+, otherwise the sheet's
/// own decoration. Pass the colour the sheet used to paint.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.color,
    required this.child,
    this.radius = 20,
    this.padding,
    this.height,
    this.constraints,
  });

  final Color color;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return AppGlass(
      cornerRadius: radius,
      forceDark:
          ThemeData.estimateBrightnessForColor(color) == Brightness.dark,
      builder:
          (context, glass) => Container(
            height: height,
            constraints: constraints,
            padding: padding,
            decoration: BoxDecoration(
              color: glass ? Colors.transparent : color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            ),
            child: child,
          ),
    );
  }
}

/// Drop-in for `showModalBottomSheet` on sheets that pass their colour via
/// [backgroundColor]: unchanged on Android / iOS ≤ 25, Liquid Glass on 26+.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? barrierColor,
}) {
  if (!nativeGlass || backgroundColor == null) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      shape: shape,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      barrierColor: barrierColor,
    );
  }

  var radius = 20.0;
  if (shape is RoundedRectangleBorder &&
      shape.borderRadius is BorderRadius) {
    radius = (shape.borderRadius as BorderRadius).topLeft.x;
  }
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: barrierColor,
    builder:
        (ctx) => GlassSheet(
          color: backgroundColor,
          radius: radius,
          child: Builder(builder: builder),
        ),
  );
}
