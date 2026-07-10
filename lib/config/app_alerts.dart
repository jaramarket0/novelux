import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';

class AppAlert {
  // Set once by MainScreen.build — always a live context inside the overlay.
  static BuildContext? _ctx;
  static void register(BuildContext ctx) => _ctx = ctx;

  static void _show(String text, TypeInfo type, BuildContext? provided) {
    final ctx = provided ?? _ctx;
    if (ctx == null) return;
    AlertInfo.show(context: ctx, text: text, typeInfo: type);
  }

  static void success(String text, {BuildContext? context}) =>
      _show(text, TypeInfo.success, context);

  static void error(String text, {BuildContext? context}) =>
      _show(text, TypeInfo.error, context);

  static void warning(String text, {BuildContext? context}) =>
      _show(text, TypeInfo.warning, context);

  static void info(String text, {BuildContext? context}) =>
      _show(text, TypeInfo.info, context);
}
