import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'dart:developer' as myLog;

import 'package:novelux/config/app_style.dart';

// ── Controller ────────────────────────────────────────────────────────────────
class ReviewsAndCommentsController extends GetxController {
  final RxBool isLoadingReviews = false.obs;
  final RxList reviews = [].obs;
  final RxString reviewFilter = 'all'.obs;
  final RxInt totalReviews = 0.obs;
  final RxInt recommendCount = 0.obs;
  final RxInt averageCount = 0.obs;
  final RxInt notGoodCount = 0.obs;
  final RxDouble avgRating = 0.0.obs;

  void loadReviews(String slug, {String type = 'all'}) async {
    isLoadingReviews.value = true;
    final res = await ApiService.getStoryReviews(slug, type: type);
    isLoadingReviews.value = false;
    if (res['success']) {
      final data = res['data'];
      reviews.value = data is List ? data : (data['results'] ?? []);
      totalReviews.value = data['total_count'] ?? reviews.length;
      recommendCount.value = data['recommend_count'] ?? 0;
      averageCount.value = data['average_count'] ?? 0;
      notGoodCount.value = data['not_good_count'] ?? 0;
    }
  }

  // Recommend % for progress bars
  double get recommendPct =>
      totalReviews.value == 0 ? 0 : recommendCount.value / totalReviews.value;
  double get averagePct =>
      totalReviews.value == 0 ? 0 : averageCount.value / totalReviews.value;
  double get notGoodPct =>
      totalReviews.value == 0 ? 0 : notGoodCount.value / totalReviews.value;
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ReviewsAndCommentsScreen extends StatelessWidget {
  final String slug;
  final String storyTitle;
  final double avgRating;

  const ReviewsAndCommentsScreen({
    super.key,
    required this.slug,
    required this.storyTitle,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ReviewsAndCommentsController());
    ctrl.avgRating.value = avgRating;
    ctrl.loadReviews(slug);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Reviews & Comments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Rating overview ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big rating number
                      Column(
                        children: [
                          Obx(
                            () => Text(
                              ctrl.avgRating.value.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                Icons.star,
                                color:
                                    i < ctrl.avgRating.value.round()
                                        ? Colors.amber
                                        : Colors.grey[700],
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Progress bars
                      Expanded(
                        child: Obx(
                          () => Column(
                            children: [
                              _ratingBar(
                                'Recommend',
                                ctrl.recommendPct,
                                Colors.amber,
                              ),
                              const SizedBox(height: 8),
                              _ratingBar(
                                'Average',
                                ctrl.averagePct,
                                Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              _ratingBar(
                                'Not good',
                                ctrl.notGoodPct,
                                Colors.amber,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Review this novel label ────────────────────────────────
                  const Text(
                    'Review this novel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Rate buttons ───────────────────────────────────────────
                  Row(
                    children: [
                      _rateBtn(
                        '😊',
                        'Recommend',
                        () => _openReviewScreen(
                          context,
                          slug,
                          'recommend',
                          storyTitle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _rateBtn(
                        '😐',
                        'Average',
                        () => _openReviewScreen(
                          context,
                          slug,
                          'average',
                          storyTitle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _rateBtn(
                        '😒',
                        'Not good',
                        () => _openReviewScreen(
                          context,
                          slug,
                          'not_good',
                          storyTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Leave a comment ────────────────────────────────────────
                  GestureDetector(
                    onTap:
                        () => _openReviewScreen(
                          context,
                          slug,
                          'recommend',
                          storyTitle,
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a2a),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Leave a comment',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Comments count + sort ──────────────────────────────────
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${ctrl.totalReviews.value} comments',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Latest',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Filter tabs ────────────────────────────────────────────
                  Obx(
                    () => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All', 'all', ctrl, slug),
                          const SizedBox(width: 8),
                          _filterChip(
                            'Recommend ${ctrl.recommendCount.value}',
                            'recommend',
                            ctrl,
                            slug,
                          ),
                          const SizedBox(width: 8),
                          _filterChip(
                            'Average ${ctrl.averageCount.value}',
                            'average',
                            ctrl,
                            slug,
                          ),
                          const SizedBox(width: 8),
                          _filterChip(
                            'Not good ${ctrl.notGoodCount.value}',
                            'not_good',
                            ctrl,
                            slug,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Comments list ─────────────────────────────────────────────────
          Obx(() {
            if (ctrl.isLoadingReviews.value) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(color: depperBlue),
                  ),
                ),
              );
            }
            if (ctrl.reviews.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey[700],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No reviews yet. Be the first!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ReviewCard(review: ctrl.reviews[i]),
                childCount: ctrl.reviews.length,
              ),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  void _openReviewScreen(
    BuildContext ctx,
    String slug,
    String initialRating,
    String storyTitle,
  ) {
    Navigator.push(
      ctx,
      CupertinoPageRoute(
        builder:
            (_) => _ReviewWriteScreen(
              slug: slug,
              storyTitle: storyTitle,
              initialRating: initialRating,
            ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _ratingBar(String label, double pct, Color color) => Row(
    children: [
      SizedBox(
        width: 72,
        child: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFF2a2a2a),
            color: color,
            minHeight: 6,
          ),
        ),
      ),
    ],
  );

  Widget _rateBtn(String emoji, String label, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _filterChip(
    String label,
    String value,
    ReviewsAndCommentsController ctrl,
    String slug,
  ) => Obx(
    () => GestureDetector(
      onTap: () {
        ctrl.reviewFilter.value = value;
        ctrl.loadReviews(slug, type: value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              ctrl.reviewFilter.value == value
                  ? depperBlue
                  : const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                ctrl.reviewFilter.value == value ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight:
                ctrl.reviewFilter.value == value
                    ? FontWeight.bold
                    : FontWeight.normal,
          ),
        ),
      ),
    ),
  );
}

// ── Review card ───────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Map review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final user = review['user'] is Map ? review['user'] as Map : {};
    final username = user['username']?.toString() ?? 'Anonymous';
    final avatar = user['avatar']?.toString() ?? '';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final rating = review['rating']?.toString() ?? 'recommend';
    final content = review['content']?.toString() ?? '';
    final likes = review['likes_count'] ?? 0;
    final date = review['created_at']?.toString() ?? '';

    final ratingEmoji =
        rating == 'recommend'
            ? '😊'
            : rating == 'average'
            ? '😐'
            : '😒';
    final ratingLabel =
        rating == 'recommend'
            ? 'Recommend'
            : rating == 'average'
            ? 'Average'
            : 'Not good';

    String formattedDate = '';
    try {
      final dt = DateTime.parse(date);
      formattedDate =
          '${_month(dt.month)} ${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _avatarColor(username),
            backgroundImage:
                avatar.isNotEmpty
                    ? NetworkImage(
                      avatar.startsWith('http')
                          ? avatar
                          : 'http://10.0.2.2:8000$avatar',
                    )
                    : null,
            child:
                avatar.isEmpty
                    ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$ratingEmoji $ratingLabel',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (formattedDate.isNotEmpty)
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Reply',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Like
          Column(
            children: [
              const SizedBox(height: 4),
              Text(
                '$likes',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Icon(Icons.favorite_border, color: Colors.grey[600], size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String name) {
    final colors = [
      Colors.teal,
      Colors.purple,
      Colors.indigo,
      Colors.brown,
      Colors.green,
      Colors.pink,
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  String _month(int m) =>
      [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];
}

// ── Write Review Screen ───────────────────────────────────────────────────────
class _ReviewWriteScreen extends StatefulWidget {
  final String slug;
  final String storyTitle;
  final String initialRating;

  const _ReviewWriteScreen({
    required this.slug,
    required this.storyTitle,
    required this.initialRating,
  });

  @override
  State<_ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<_ReviewWriteScreen> {
  late String _rating;
  final _ctrl = TextEditingController();
  bool _submitting = false;
  bool _showEmoji = false;

  final _emojis = [
    '🤩',
    '💗',
    '😋',
    '😘',
    '🤔',
    '😜',
    '😂',
    '😝',
    '🍺',
    '😁',
    '🥂',
    '😄',
    '💗',
    '💘',
    '🔍',
    '👏',
    '✌',
    '🤙',
    '💋',
    '🌹',
    '💄',
    '😐',
    '😯',
    '😟',
    '💪',
    '🙏',
    '😢',
    '😶',
    '😡',
    '😼',
    '😿',
    '😰',
    '😲',
    '🙈',
    '🙉',
    '🙊',
    '😹',
    '😺',
    '🐾',
    '😾',
    '🥩',
    '🍔',
    '🍩',
    '🍺',
    '🌈',
    '☂',
    '😻',
    '🐱',
    '🐈',
    '👾',
  ];

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    final res = await ApiService.submitReview(
      widget.slug,
      rating: _rating,
      content: _ctrl.text.trim(),
    );
    myLog.log(res.toString());
    myLog.log(_ctrl.text.trim());
    myLog.log(_rating);

    setState(() => _submitting = false);
    if (res['success']) {
      Get.back();
      AppAlert.success('Review submitted! — Thanks for your feedback 😊');
    } else {
      AppAlert.error(res['error'] ?? 'Could not submit review');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review this novel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showEmoji = false),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Story title
                    Text(
                      widget.storyTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Rating buttons
                    Row(
                      children: [
                        _ratingOption('😊', 'Recommend', 'recommend'),
                        const SizedBox(width: 10),
                        _ratingOption('😐', 'Average', 'average'),
                        const SizedBox(width: 10),
                        _ratingOption('😒', 'Not good', 'not_good'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Text area
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a2a),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _ctrl,
                            maxLength: 2000,
                            maxLines: 10,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Leave a comment...',
                              hintStyle: TextStyle(color: Color(0xFF6b6b80)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              counterStyle: TextStyle(color: Color(0xFF6b6b80)),
                            ),
                            onTap: () => setState(() => _showEmoji = false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom bar ──────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji picker
                  if (_showEmoji)
                    Container(
                      height: 220,
                      color: const Color(0xFF1a1a1a),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: _emojis.length,
                        itemBuilder:
                            (_, i) => GestureDetector(
                              onTap: () {
                                _ctrl.text = _ctrl.text + _emojis[i];
                                _ctrl.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _ctrl.text.length),
                                );
                              },
                              child: Center(
                                child: Text(
                                  _emojis[i],
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                      ),
                    ),

                  // Emoji toggle + Submit
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 24,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _showEmoji = !_showEmoji),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2a2a2a),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Center(
                              child: Text(
                                _showEmoji ? '⌨️' : '😊',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: depperBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: _submitting ? null : _submit,
                              child:
                                  _submitting
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingOption(String emoji, String label, String value) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _rating = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _rating == value ? depperBlue : const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _rating == value ? depperBlue : const Color(0xFF3a3a3a),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _rating == value ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight:
                    _rating == value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
