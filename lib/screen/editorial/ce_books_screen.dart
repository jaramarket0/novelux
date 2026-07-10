import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/widgets/custom_image_view.dart';

class CeBooksScreen extends StatefulWidget {
  const CeBooksScreen({super.key});

  @override
  State<CeBooksScreen> createState() => _CeBooksScreenState();
}

class _CeBooksScreenState extends State<CeBooksScreen> {
  List _stories = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  String _search = '';
  String _statusFilter = '';
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _statuses = ['', 'published', 'ongoing', 'draft', 'rejected'];
  static const _statusLabels = {
    '': 'All',
    'published': 'Published',
    'ongoing': 'Ongoing',
    'draft': 'Draft',
    'rejected': 'Removed',
  };

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 200 &&
          !_loadingMore &&
          _stories.length < _total) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() { _loading = true; _page = 1; _stories = []; _error = null; });
    final res = await ApiService.getCeBooks(
        status: _statusFilter, search: _search, page: _page);
    if (!mounted) return;
    if (res['success'] == true) {
      final d = res['data'] as Map? ?? {};
      final results = (d['results'] as List? ?? []);
      setState(() {
        _total = (d['total'] as num?)?.toInt() ?? 0;
        _stories = reset ? results : [..._stories, ...results];
        _loading = false;
      });
    } else {
      setState(() { _error = res['error'] ?? 'Failed to load'; _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    setState(() { _loadingMore = true; _page++; });
    await _load();
    setState(() => _loadingMore = false);
  }

  Future<void> _removeStory(Map story) async {
    final slug = story['slug'] as String;
    final confirmed = await _confirmDialog(
      title: 'Remove Story',
      message: 'Remove "${story['title']}"? This will mark it as rejected. You can restore it later.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true) return;
    final res = await ApiService.ceRemoveStory(slug);
    if (res['success'] == true) {
      AppAlert.success('Story removed.');
      _load(reset: true);
    } else {
      AppAlert.error(res['error'] ?? 'Failed to remove story');
    }
  }

  Future<void> _restoreStory(Map story) async {
    final slug = story['slug'] as String;
    final res = await ApiService.ceRestoreStory(slug);
    if (res['success'] == true) {
      AppAlert.success('Story restored to ongoing.');
      _load(reset: true);
    } else {
      AppAlert.error(res['error'] ?? 'Failed to restore story');
    }
  }

  void _openEditSheet(Map story) {
    final titleCtrl    = TextEditingController(text: story['title'] ?? '');
    final synopsisCtrl = TextEditingController(text: story['synopsis'] ?? '');
    final outlineCtrl  = TextEditingController(text: story['story_outline'] ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg  = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Edit Story', style: TextStyle(color: txt,
                  fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(ctx, titleCtrl, 'Title', txt, sub),
              const SizedBox(height: 12),
              _field(ctx, synopsisCtrl, 'Synopsis', txt, sub, maxLines: 4),
              const SizedBox(height: 12),
              _field(ctx, outlineCtrl, 'Story Outline', txt, sub, maxLines: 4),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          setSheet(() => saving = true);
                          final res = await ApiService.ceEditStory(
                            story['slug'] as String,
                            {
                              'title':         titleCtrl.text.trim(),
                              'synopsis':      synopsisCtrl.text.trim(),
                              'story_outline': outlineCtrl.text.trim(),
                            },
                          );
                          setSheet(() => saving = false);
                          if (res['success'] == true) {
                            Navigator.pop(ctx);
                            AppAlert.success('Story updated.');
                            _load(reset: true);
                          } else {
                            AppAlert.error(res['error'] ?? 'Failed to save');
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(BuildContext ctx, TextEditingController ctrl, String hint,
      Color txt, Color sub, {int maxLines = 1}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: txt),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: sub),
        filled: true,
        fillColor: isDark ? const Color(0xFF2a2a2a) : Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel,
                  style: TextStyle(
                      color: destructive ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
    final card = isDark ? const Color(0xFF1e1e20) : Colors.white;
    final txt  = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub  = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: txt, size: 28),
          onPressed: () => Get.back(),
        ),
        title: Text('Manage Stories',
            style: TextStyle(color: txt, fontSize: 16,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(children: [
        // ── Search bar ──────────────────────────────────────────────────
        Container(
          color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: txt),
            decoration: InputDecoration(
              hintText: 'Search by title, author, or code...',
              hintStyle: TextStyle(color: sub, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: sub),
              filled: true,
              fillColor: isDark ? const Color(0xFF2a2a2a) : Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (v) {
              _search = v.trim();
              _load(reset: true);
            },
          ),
        ),
        // ── Status filter chips ─────────────────────────────────────────
        Container(
          color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _statuses.map((s) {
              final selected = _statusFilter == s;
              return GestureDetector(
                onTap: () {
                  setState(() => _statusFilter = s);
                  _load(reset: true);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1976D2)
                        : (isDark
                            ? const Color(0xFF2a2a2a)
                            : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabels[s] ?? s,
                      style: TextStyle(
                          color: selected ? Colors.white : sub,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        // ── List ────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1976D2)))
              : _error != null
                  ? Center(child: Text(_error!,
                      style: TextStyle(color: sub)))
                  : _stories.isEmpty
                      ? Center(child: Text('No stories found.',
                          style: TextStyle(color: sub)))
                      : RefreshIndicator(
                          color: const Color(0xFF1976D2),
                          onRefresh: () => _load(reset: true),
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(12),
                            itemCount:
                                _stories.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _stories.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF1976D2))),
                                );
                              }
                              return _StoryRow(
                                story: _stories[i] as Map,
                                card: card,
                                txt: txt,
                                sub: sub,
                                onEdit: () => _openEditSheet(_stories[i]),
                                onRemove: () => _removeStory(_stories[i]),
                                onRestore: () => _restoreStory(_stories[i]),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}

class _StoryRow extends StatelessWidget {
  final Map story;
  final Color card, txt, sub;
  final VoidCallback onEdit, onRemove, onRestore;

  const _StoryRow({
    required this.story,
    required this.card,
    required this.txt,
    required this.sub,
    required this.onEdit,
    required this.onRemove,
    required this.onRestore,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'published': return Colors.green;
      case 'ongoing':   return Colors.blue;
      case 'draft':     return Colors.grey;
      case 'rejected':  return Colors.red;
      default:          return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cover  = story['cover_image'] as String?;
    final status = story['status'] as String? ?? '';
    final isRemoved = status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cover
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: cover != null && cover.isNotEmpty
              ? CustomImageView(
                  imagePath: cover, width: 52, height: 70,
                  fit: BoxFit.cover)
              : Container(width: 52, height: 70,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(story['title'] ?? '',
                style: TextStyle(color: txt, fontWeight: FontWeight.bold,
                    fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('by ${story['author'] ?? ''}',
                style: TextStyle(color: sub, fontSize: 11)),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(status,
                    style: TextStyle(color: _statusColor(status),
                        fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text('${story['total_chapters'] ?? 0} ch · '
                  '${story['total_views'] ?? 0} views',
                  style: TextStyle(color: sub, fontSize: 10)),
            ]),
          ]),
        ),
        // Actions
        Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20,
                color: Color(0xFF1976D2)),
            tooltip: 'Edit',
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 8),
          isRemoved
              ? IconButton(
                  icon: const Icon(Icons.restore, size: 20,
                      color: Colors.green),
                  tooltip: 'Restore',
                  onPressed: onRestore,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20,
                      color: Colors.red),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
        ]),
      ]),
    );
  }
}
