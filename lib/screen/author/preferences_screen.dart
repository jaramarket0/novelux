import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';

// ── All categories ────────────────────────────────────────────────────────────
const kAllCategories = [
  {'label': 'Romance',         'emoji': '💕', 'slug': 'romance'},
  {'label': 'Billionaire',     'emoji': '💰', 'slug': 'billionaire'},
  {'label': 'Werewolf',        'emoji': '🐺', 'slug': 'werewolf'},
  {'label': 'Fantasy',         'emoji': '🧙', 'slug': 'fantasy'},
  {'label': 'CEO / Office',    'emoji': '🏢', 'slug': 'ceo-office'},
  {'label': 'African Fiction', 'emoji': '🌍', 'slug': 'african-fiction'},
  {'label': 'Thriller',        'emoji': '🔪', 'slug': 'thriller'},
  {'label': 'Mystery',         'emoji': '🕵️', 'slug': 'mystery'},
  {'label': 'Sci-Fi',          'emoji': '🚀', 'slug': 'sci-fi'},
  {'label': 'Horror',          'emoji': '👻', 'slug': 'horror'},
  {'label': 'Historical',      'emoji': '🏛️', 'slug': 'historical'},
  {'label': 'Comedy',          'emoji': '😂', 'slug': 'comedy'},
  {'label': 'Action',          'emoji': '⚔️', 'slug': 'action'},
  {'label': 'Drama',           'emoji': '🎭', 'slug': 'drama'},
  {'label': 'Young Adult',     'emoji': '🎓', 'slug': 'young-adult'},
  {'label': 'Reverse Harem',   'emoji': '👑', 'slug': 'reverse-harem'},
  {'label': 'Mafia',           'emoji': '🔫', 'slug': 'mafia'},
  {'label': 'Second Chance',   'emoji': '🔄', 'slug': 'second-chance'},
];

// ── Controller ────────────────────────────────────────────────────────────────
class PreferencesController extends GetxController {
  final RxSet<String> selectedSlugs = <String>{}.obs;
  final RxString      gender         = ''.obs;
  final RxBool        isSaving       = false.obs;
  final RxBool        isLoading      = false.obs;

  // Load existing preferences from backend
  Future<void> loadPreferences() async {
    isLoading.value = true;
    final res = await ApiService.getUserPreferences();
    isLoading.value = false;
    if (res['success']) {
      final data = res['data'];
      final genres = data['preferred_genres'] as List? ?? [];
      selectedSlugs.value = genres.map((g) => g.toString()).toSet();
      gender.value = data['gender']?.toString() ?? '';
    }
  }

  void toggleCategory(String slug) {
    if (selectedSlugs.contains(slug)) {
      selectedSlugs.remove(slug);
    } else {
      selectedSlugs.add(slug);
    }
  }

  void setGender(String g) => gender.value = g;

  Future<bool> save() async {
    if (selectedSlugs.isEmpty) return false;
    isSaving.value = true;
    final res = await ApiService.saveUserPreferences(
      genres: selectedSlugs.toList(),
      gender: gender.value,
    );
    isSaving.value = false;
    return res['success'] == true;
  }
}

// ── Preferences Screen ────────────────────────────────────────────────────────
class PreferencesScreen extends StatefulWidget {
  /// If true, shown after registration (redirects to main).
  /// If false, shown as edit screen from profile.
  final bool isOnboarding;
  const PreferencesScreen({super.key, this.isOnboarding = true});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late final PreferencesController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(PreferencesController());
    if (!widget.isOnboarding) {
      // Edit mode — load existing from backend
      ctrl.loadPreferences();
    }
  }

  Future<void> _handleSave() async {
    if (ctrl.selectedSlugs.isEmpty) {
      AppAlert.warning('Select categories — Please pick at least one genre to continue');
      return;
    }
    final ok = await ctrl.save();
    if (ok) {
      if (widget.isOnboarding) {
        Get.offAllNamed('/main_screen');
      } else {
        Get.back();
        AppAlert.success('✅ Preferences saved — Your reading preferences have been updated');
      }
    } else {
      AppAlert.error('Could not save preferences. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF5F5F5);
    final txt    = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub    = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.chevron_left, color: txt, size: 28),
                onPressed: () => Get.back()),
              title: Text('Reading Preferences',
                  style: TextStyle(color: txt, fontSize: 16,
                      fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator(
                color: Colors.orange));
          }
          return Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(children: [
                Text(
                  widget.isOnboarding
                      ? 'What do you love to read?' : 'Edit Preferences',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: txt, fontSize: 26,
                      fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  widget.isOnboarding
                      ? 'Pick at least one. We\'ll personalise your feed.'
                      : 'Update the genres you enjoy reading.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: sub, fontSize: 14, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 20),

            // Gender selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Text('I read as  ', style: TextStyle(
                    color: txt, fontSize: 13)),
                const Spacer(),
                ...[
                  ('Male', 'male', Icons.male_rounded),
                  ('Female', 'female', Icons.female_rounded),
                  ('Other', 'prefer_not_to_say', Icons.person_outline),
                ].map((g) => Obx(() => GestureDetector(
                  onTap: () => ctrl.setGender(g.$2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: ctrl.gender.value == g.$2
                          ? depperBlue : (isDark
                              ? const Color(0xFF2a2a2a)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ctrl.gender.value == g.$2
                          ? depperBlue : Colors.grey.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(g.$3, size: 14,
                          color: ctrl.gender.value == g.$2
                              ? Colors.white : sub),
                      const SizedBox(width: 4),
                      Text(g.$1, style: TextStyle(
                        color: ctrl.gender.value == g.$2
                            ? Colors.white : sub,
                        fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ))),
              ]),
            ),
            const SizedBox(height: 16),

            // Categories grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 2.4,
                    mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemCount: kAllCategories.length,
                itemBuilder: (_, i) {
                  final cat  = kAllCategories[i];
                  final slug = cat['slug']!;
                  return Obx(() {
                    final sel = ctrl.selectedSlugs.contains(slug);
                    return GestureDetector(
                      onTap: () => ctrl.toggleCategory(slug),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: sel
                              ? depperBlue.withOpacity(0.2)
                              : (isDark
                                  ? const Color(0xFF2a2a2a) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel ? depperBlue
                                  : Colors.grey.withOpacity(0.2),
                              width: 1.5)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cat['emoji']!,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Flexible(child: Text(cat['label']!,
                                style: TextStyle(
                                  color: sel ? depperBlue : txt,
                                  fontSize: 11,
                                  fontWeight: sel
                                      ? FontWeight.bold : FontWeight.normal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),

            // Count + button
            Obx(() => ctrl.selectedSlugs.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${ctrl.selectedSlugs.length} selected',
                        style: TextStyle(color: depperBlue, fontSize: 13,
                            fontWeight: FontWeight.bold)))
                : const SizedBox.shrink()),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(width: double.infinity, height: 52,
                child: Obx(() => ElevatedButton(
                  onPressed: ctrl.selectedSlugs.isNotEmpty
                      ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: depperBlue,
                    disabledBackgroundColor: const Color(0xFF3a3a3a),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                  child: ctrl.isSaving.value
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          widget.isOnboarding ? 'Continue →' : 'Save',
                          style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ))),
            ),
          ]);
        }),
      ),
    );
  }
}