import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  static const _key = 'app_locale';

  final _locale = const Locale('en', 'US').obs;
  Locale get locale => _locale.value;

  static const supportedLanguages = [
    _Lang('en', 'US', 'English', 'English', '🇺🇸'),
    _Lang('fr', 'FR', 'French', 'Français', '🇫🇷'),
    _Lang('es', 'ES', 'Spanish', 'Español', '🇪🇸'),
    _Lang('pt', 'BR', 'Portuguese', 'Português', '🇧🇷'),
    _Lang('ar', 'SA', 'Arabic', 'العربية', '🇸🇦'),
    _Lang('zh', 'CN', 'Chinese', '中文', '🇨🇳'),
    _Lang('de', 'DE', 'German', 'Deutsch', '🇩🇪'),
    _Lang('yo', 'NG', 'Yoruba', 'Yorùbá', '🇳🇬'),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      final parts = saved.split('_');
      if (parts.length == 2) {
        _locale.value = Locale(parts[0], parts[1]);
        Get.updateLocale(_locale.value);
      }
    }
  }

  Future<void> changeLanguage(Locale newLocale) async {
    _locale.value = newLocale;
    Get.updateLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, '${newLocale.languageCode}_${newLocale.countryCode}');
  }
}

class _Lang {
  final String languageCode;
  final String countryCode;
  final String nameEn;
  final String nameNative;
  final String flag;

  const _Lang(
    this.languageCode,
    this.countryCode,
    this.nameEn,
    this.nameNative,
    this.flag,
  );

  Locale get locale => Locale(languageCode, countryCode);
}
