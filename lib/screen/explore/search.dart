import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/widgets/custom_image_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Search Controller ─────────────────────────────────────────────────────────
class SearchController extends GetxController {
  final RxList results = [].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasSearched = false.obs;
  final RxString query = ''.obs;
  final RxList<String> recentQueries = <String>[].obs;

  final List<String> topKeywords = [
    'Forbidden Uncle',
    'Sexy',
    'Mafia',
    'Pregnant',
    'Silent Phoenix',
    'Devil',
    'Alpha',
    'CEO',
    'Werewolf',
    'Billionaire',
  ];

  final RxList topRated = [].obs;
  final RxBool isLoadingTop = false.obs;

  static const _kHistoryKey = 'nux_search_history';
  static const _kMaxHistory = 8;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    fetchTopRated();
  }

  // ── Persist search history ────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    recentQueries.value = prefs.getStringList(_kHistoryKey) ?? [];
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHistoryKey, recentQueries.toList());
  }

  Future<void> removeHistoryItem(String q) async {
    recentQueries.remove(q);
    await _saveHistory();
  }

  Future<void> clearAllHistory() async {
    recentQueries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }

  // ── Top rated ─────────────────────────────────────────────────────────────
  Future<void> fetchTopRated() async {
    isLoadingTop.value = true;
    final res = await ApiService.getTrending();
    isLoadingTop.value = false;
    if (res['success']) {
      final data = res['data'];
      topRated.value = data is List ? data : (data['results'] ?? []);
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────
  void onQueryChanged(String q) {
    query.value = q;
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      results.clear();
      hasSearched.value = false;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 380), () => search(q));
  }

  Future<void> search(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    isLoading.value = true;
    hasSearched.value = true;
    query.value = trimmed;

    final res = await ApiService.getStories(search: trimmed);
    isLoading.value = false;

    if (res['success']) {
      final data = res['data'];
      results.value = data is List ? data : (data['results'] ?? []);
    }

    // Persist to history
    recentQueries.remove(trimmed);
    recentQueries.insert(0, trimmed);
    if (recentQueries.length > _kMaxHistory) {
      recentQueries.removeLast();
    }
    await _saveHistory();
  }

  void clearSearch() {
    query.value = '';
    results.clear();
    hasSearched.value = false;
  }

  String getCoverUrl(Map story) {
    final c = story['cover_image'];
    if (c == null || c.toString().isEmpty) return '';
    if (c.toString().startsWith('http')) return c.toString();
    return 'http://10.0.2.2:8000$c';
  }

  // Highlight matched query words — returns TextSpans
  List<TextSpan> highlight(String text, String q, Color txt) {
    if (q.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(color: txt, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ];
    }
    final pattern = RegExp(RegExp.escape(q), caseSensitive: false);
    final spans = <TextSpan>[];
    int last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(
          TextSpan(
            text: text.substring(last, m.start),
            style: TextStyle(
              color: txt,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: TextStyle(
            color: depperBlue,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      last = m.end;
    }
    if (last < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(last),
          style: TextStyle(
            color: txt,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return spans;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}

// ── Search Screen ─────────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = Get.put(SearchController());
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _pick(String kw) {
    _textCtrl.text = kw;
    _textCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: kw.length),
    );
    _ctrl.search(kw);
  }

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

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Search bar ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: onBg,
                            size: 20,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              Icon(Icons.search, color: onBg, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _textCtrl,
                                  focusNode: _focusNode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    fillColor: cardBg,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: 'Search novels, authors, tags...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  textInputAction: TextInputAction.search,
                                  onChanged: _ctrl.onQueryChanged,
                                  onSubmitted: _ctrl.search,
                                ),
                              ),
                              Obx(
                                () =>
                                    _ctrl.query.value.isNotEmpty
                                        ? GestureDetector(
                                          onTap: () {
                                            _textCtrl.clear();
                                            _ctrl.clearSearch();
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.only(right: 12),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.grey,
                                              size: 18,
                                            ),
                                          ),
                                        )
                                        : const SizedBox(width: 12),
                              ),
                            ],
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () => _ctrl.search(_textCtrl.text),
                        child: Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            'Search',
                            style: TextStyle(
                              color: txt,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Body ───────────────────────────────────────────────────────
                Expanded(
                  child: Obx(
                    () =>
                        _ctrl.hasSearched.value
                            ? _buildResults(txt, bg, sub, onBg, divClr)
                            : _buildDefault(txt, bg, sub, onBg, divClr, cardBg),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Default — history + keywords + top rated ───────────────────────
  Widget _buildDefault(
    Color txt,
    Color bg,
    Color sub,
    Color onBg,
    Color divClr,
    Color cardbg,
  ) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search history
        Obx(() {
          if (_ctrl.recentQueries.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search history',
                    style: TextStyle(
                      color: txt,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _ctrl.clearAllHistory,
                    child: Icon(Icons.delete_outline, color: onBg, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._ctrl.recentQueries.map(
                (q) => GestureDetector(
                  onTap: () => _pick(q),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            q,
                            style: TextStyle(color: txt, fontSize: 15),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _ctrl.removeHistoryItem(q),
                          child: Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(Icons.close, color: onBg, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: divClr, height: 1),
              const SizedBox(height: 20),
            ],
          );
        }),

        // Top keywords
        Text(
          'Top keywords',
          style: TextStyle(
            color: txt,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              _ctrl.topKeywords
                  .map(
                    (kw) => GestureDetector(
                      onTap: () => _pick(kw),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cardbg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          kw,
                          style: TextStyle(
                            color: txt,
                            fontSize: 12,
                            fontFamily: kFontFamily,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 28),

        // Top rated header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Rated',
              style: TextStyle(
                color: txt,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text('View all', style: TextStyle(color: sub, fontSize: 13)),
                Icon(Icons.chevron_right, color: sub, size: 18),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Top rated 2-column grid
        Obx(() {
          if (_ctrl.isLoadingTop.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: depperBlue,
                strokeWidth: 2,
              ),
            );
          }
          final stories = _ctrl.topRated.take(10).toList();
          return Column(
            children: List.generate((stories.length / 2).ceil(), (row) {
              final left = stories[row * 2];
              final right =
                  row * 2 + 1 < stories.length ? stories[row * 2 + 1] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TopRatedCard(
                        story: left,
                        rank: row * 2 + 1,
                        ctrl: _ctrl,
                        txt: txt,
                        sub: sub,
                      ),
                    ),
                    const SizedBox(width: 16),
                    right != null
                        ? Expanded(
                          child: _TopRatedCard(
                            story: right,
                            rank: row * 2 + 2,
                            ctrl: _ctrl,
                            txt: txt,
                            sub: sub,
                          ),
                        )
                        : const Expanded(child: SizedBox()),
                  ],
                ),
              );
            }),
          );
        }),
        const SizedBox(height: 80),
      ],
    ),
  );

  // ── Results ────────────────────────────────────────────────────────
  Widget _buildResults(
    Color txt,
    Color bg,
    Color sub,
    Color onBg,
    Color divClr,
  ) {
    if (_ctrl.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: depperBlue, strokeWidth: 2),
      );
    }
    if (_ctrl.results.isEmpty) return _emptyResults();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: _ctrl.results.length,
            itemBuilder:
                (_, i) => _ResultRow(
                  story: _ctrl.results[i] as Map,
                  ctrl: _ctrl,
                  query: _ctrl.query.value,
                ),
          ),
        ),

        // "Not found? Please tell us." bar
        _NotFoundBar(query: _ctrl.query.value),
      ],
    );
  }

  Widget _emptyResults() => Column(
    children: [
      const Spacer(),
      Icon(Icons.menu_book_outlined, color: Colors.grey[800], size: 72),
      const SizedBox(height: 60),
      _NotFoundBar(query: _ctrl.query.value),
      const SizedBox(height: 24),
    ],
  );
}

// ── "Not found? Please tell us." bar + "Find the book" bottom sheet ───────────
class _NotFoundBar extends StatelessWidget {
  final String query;
  const _NotFoundBar({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final barBg = isDark
            ? const Color(0xFF2a2a2a)
            : const Color(0xFFE8E8EE);
        final arrowBg = isDark
            ? const Color(0xFF3a3a3a)
            : Colors.grey[300]!;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);

        return GestureDetector(
          onTap: () => _FindBookSheet.show(context, prefillTitle: query),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: barBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not found? Please tell us.',
                  style: TextStyle(color: txt, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: arrowBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: txt,
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── "Find the book" bottom sheet ─────────────────────────────────────────────
class _FindBookSheet extends StatefulWidget {
  final String prefillTitle;
  const _FindBookSheet({required this.prefillTitle});

  static Future<void> show(
    BuildContext context, {
    required String prefillTitle,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FindBookSheet(prefillTitle: prefillTitle),
  );

  @override
  State<_FindBookSheet> createState() => _FindBookSheetState();
}

class _FindBookSheetState extends State<_FindBookSheet> {
  late final TextEditingController _titleCtrl;
  final _authorCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.prefillTitle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    // Fire to backend — best effort
    await ApiService.requestBook(
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
    ).catchError((_) {});

    setState(() {
      _submitting = false;
      _submitted = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final theme = Get.find<ThemeController>();
    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark
            ? const Color(0xFF1e1e22)
            : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final inputFill = isDark ? const Color(0xFF2a2a2a) : Colors.grey[100]!;
        final handleClr = isDark ? Colors.grey[700]! : Colors.grey[300]!;
        final cancelBg = isDark ? const Color(0xFF3a3a3a) : Colors.grey[200]!;

        return Container(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + kb),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: handleClr,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Icon
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(bottom: 12),
                child: Icon(
                  Icons.bookmark_add_outlined,
                  color: depperBlue.withValues(alpha: 0.5),
                  size: 50,
                ),
              ),

              // Title
              Text(
                'Find the book',
                style: TextStyle(
                  color: txt,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              if (_submitted)
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Request submitted!',
                      style: TextStyle(color: txt, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "We'll look into it",
                      style: TextStyle(color: sub, fontSize: 13),
                    ),
                  ],
                )
              else ...[
                // Title field
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Title',
                          style: TextStyle(
                            color: txt,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  style: TextStyle(color: txt),
                  decoration: InputDecoration(
                    hintText: 'Enter book title',
                    hintStyle: TextStyle(color: sub),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Author field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Author',
                    style: TextStyle(
                      color: txt,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _authorCtrl,
                  style: TextStyle(color: txt),
                  decoration: InputDecoration(
                    hintText: 'Enter author name (optional)',
                    hintStyle: TextStyle(color: sub),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Cancel / Submit
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: cancelBg,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: txt,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _submitting ? null : _submit,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: depperBlue,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Top Rated Card ─────────────────────────────────────────────────────────────
class _TopRatedCard extends StatelessWidget {
  final Map story;
  final int rank;
  final SearchController ctrl;
  final Color txt;
  final Color sub;
  const _TopRatedCard({
    required this.story,
    required this.rank,
    required this.ctrl,
    required this.txt,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg =
        isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;
    final cover = ctrl.getCoverUrl(story);
    final views = story['total_views'] ?? 0;
    final viewStr =
        views >= 1000
            ? '${(views / 1000).toStringAsFixed(0)}K Views'
            : '$views Views';
    final badgeColors = [
      const Color(0xFFFF4500),
      const Color(0xFF2a2a2a),
      const Color(0xFF7a6010),
      const Color(0xFF7a6010),
      const Color(0xFF7a6010),
    ];
    final badgeColor =
        rank <= 5 ? badgeColors[rank - 1] : const Color(0xFF3a3a3a);

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => StoryDetailScreen(slug: story['slug']),
            ),
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 110,
                  child:
                      cover.isNotEmpty
                          ? CustomImageView(imagePath: cover, fit: BoxFit.cover)
                          : 
                            // Container(
                            //     color: placeholderBg,
                            //     child: Icon(Icons.book, color: sub),
                            //   ),
                            CustomImageView(
                      imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story['title'] ?? '',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(viewStr, style: TextStyle(color: sub, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Result Row ─────────────────────────────────────────────────────────
class _ResultRow extends StatelessWidget {
  final Map story;
  final SearchController ctrl;
  final String query;
  const _ResultRow({
    required this.story,
    required this.ctrl,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
        final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        final placeholderBg =
            isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;

        final cover = ctrl.getCoverUrl(story);
        final title = story['title']?.toString() ?? '';
        final author = story['author'] is Map
            ? story['author']['username']?.toString() ?? ''
            : story['author']?.toString() ?? '';
        final description = story['description']?.toString() ?? '';
        final rating =
            double.tryParse(story['average_rating']?.toString() ?? '0') ?? 0.0;
        final views = story['total_views'] ?? 0;
        final chapCount =
            story['total_chapters'] ?? story['chapter_count'] ?? 0;
        final tags = story['tags'] as List? ?? [];
        final isShort = chapCount > 0 && chapCount < 20;
        final viewStr = views >= 1000
            ? '${(views / 1000).toStringAsFixed(1)}K Views'
            : '$views Views';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => StoryDetailScreen(slug: story['slug']),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover + short badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 100,
                        height: 138,
                        child: cover.isNotEmpty
                            ? CustomImageView(
                                imagePath: cover,
                                fit: BoxFit.cover,
                              )
                            : 
                              // Container(
                              //     color: placeholderBg,
                              //     child: Icon(
                              //     Icons.book,
                              //     color: sub,
                              //     size: 32,
                              //   ),
                              // ),
                              CustomImageView(
                      imagePath: 'assets/images/novelux_placeholder_transcpr.jpg',
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                      ),
                    ),
                    if (isShort)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: depperBlue,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Short',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: ctrl.highlight(title, query, txt),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (author.isNotEmpty)
                        Text(
                          'Author: $author',
                          style: TextStyle(color: sub, fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey[500]!,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (rating > 0) ...[
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: txt,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              '$viewStr · $chapCount chapters',
                              style: TextStyle(color: sub, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: tags.take(3).map((t) {
                            final name = t is Map
                                ? t['name']?.toString() ?? ''
                                : t.toString();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: depperBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: depperBlue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: depperBlue.withValues(alpha: 0.9),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
