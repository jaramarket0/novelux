import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ad_service.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/redeem/redeem_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Controller ────────────────────────────────────────────────────────────────
class RewardsController extends GetxController {
  final auth = Get.find<AuthController>();

  // check-in (backend-driven)
  final RxBool checkedInToday    = false.obs;
  final RxBool isClaimingCheckin = false.obs;
  final RxInt  currentStreak     = 0.obs;
  final RxInt  longestStreak     = 0.obs;
  final RxInt  totalCheckins     = 0.obs;
  final RxInt  nextReward        = 10.obs;
  final RxList<int> rewardSchedule = <int>[10, 15, 20, 25, 30, 35, 40].obs;

  // tasks (backend-driven)
  final RxList tasks          = [].obs;
  final RxBool isLoadingTasks = false.obs;

  // local-only
  final RxInt  adsWatchedToday       = 0.obs;
  final int    maxAdsPerDay          = 10;
  final int    adCompletionBonus     = 100;
  final RxBool signInClaimed         = false.obs;
  final RxBool notificationsClaimed  = false.obs;
  final RxInt  readingMinutesToday   = 0.obs;
  // tracks which reading milestones have been claimed today (by index)
  final RxList<bool> claimedMilestones = <bool>[].obs;

  final List<Map<String, dynamic>> readingMilestones = [
    {'mins': 5,   'coins': 5},
    {'mins': 10,  'coins': 5},
    {'mins': 30,  'coins': 10},
    {'mins': 60,  'coins': 20},
    {'mins': 120, 'coins': 35},
    {'mins': 180, 'coins': 50},
  ];

  @override
  void onInit() {
    super.onInit();
    _loadLocal();
    loadCheckinStatus();
    loadTasks();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = prefs.getString('checkin_date') ?? '';
    adsWatchedToday.value      = saved == today ? (prefs.getInt('ads_today') ?? 0) : 0;
    readingMinutesToday.value  = prefs.getInt('reading_mins') ?? 0;
    signInClaimed.value        = prefs.getBool('signin_claimed') ?? false;
    notificationsClaimed.value = prefs.getBool('notif_claimed') ?? false;

    // Load claimed milestones — reset each day
    final milestoneDate = prefs.getString('milestone_date') ?? '';
    final count = readingMilestones.length;
    if (milestoneDate == today) {
      final raw = prefs.getString('milestones_claimed') ?? '';
      claimedMilestones.value = List.generate(
        count,
        (i) => raw.split(',').contains('$i'),
      );
    } else {
      claimedMilestones.value = List.generate(count, (_) => false);
    }
  }

  Future<void> loadCheckinStatus() async {
    final res = await ApiService.getCheckinStatus();
    if (res['success'] == true) {
      final d = res['data'] as Map? ?? {};
      checkedInToday.value = d['claimed_today'] == true;
      currentStreak.value  = (d['current_streak'] as num?)?.toInt() ?? 0;
      longestStreak.value  = (d['longest_streak'] as num?)?.toInt() ?? 0;
      totalCheckins.value  = (d['total_checkins'] as num?)?.toInt() ?? 0;
      nextReward.value     = (d['next_reward'] as num?)?.toInt() ?? 10;
      final sched = d['reward_schedule'];
      if (sched is List) {
        rewardSchedule.value = sched.map((e) => (e as num).toInt()).toList();
      }
    }
  }

  Future<void> claimDailyCheckIn() async {
    if (checkedInToday.value || isClaimingCheckin.value) return;
    isClaimingCheckin.value = true;
    final res = await ApiService.claimCheckin();
    isClaimingCheckin.value = false;
    if (res['success'] == true) {
      final d = res['data'] as Map? ?? {};
      final reward = (d['coins_earned'] ?? d['coins_awarded'] ?? d['reward'] ?? nextReward.value as dynamic) as num;
      checkedInToday.value = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('checkin_date',
          DateTime.now().toIso8601String().substring(0, 10));
      await loadCheckinStatus();
      auth.fetchMe();
      _showCheckinSuccessDialog(reward.toInt());
    } else {
      AppAlert.error(res['error'] ?? 'Could not claim check-in');
    }
  }

  void _showCheckinSuccessDialog(int coinsEarned) {
    final nextAdBonus = coinsEarned * 25; // boost shown in the popup
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🪙', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text('Check-in successful',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "You've earned $coinsEarned coins! Come back tomorrow to get another $coinsEarned coins!",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    const Text('Now', style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Icon(Icons.star, color: Colors.yellow, size: 20),
                    const SizedBox(height: 4),
                    Text('+$coinsEarned', style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold,
                        fontSize: 20)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                      color: Colors.orange[400],
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    const Text('Watch Ad', style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Icon(Icons.star, color: Colors.yellow, size: 20),
                    const SizedBox(height: 4),
                    Text('+$nextAdBonus', style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold,
                        fontSize: 20)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                icon: const Icon(Icons.play_circle_fill, size: 20),
                label: Text('Earn ${nextAdBonus - coinsEarned} more coins',
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15)),
                onPressed: () {
                  Get.back();
                  watchAd();
                },
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Not now',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> loadTasks() async {
    isLoadingTasks.value = true;
    final res = await ApiService.getTasks();
    isLoadingTasks.value = false;
    if (res['success'] == true) {
      final d = res['data'] as Map? ?? {};
      tasks.value = (d['results'] as List? ?? []);
    }
  }

  Future<void> completeTask(Map task, {String? response}) async {
    final id  = task['id'] as int;
    final res = await ApiService.completeTask(id, response: response);
    if (res['success'] == true) {
      final d      = res['data'] as Map? ?? {};
      final reward = (d['coins_earned'] ?? d['coins_awarded'] ?? task['reward_coins'] ?? 0 as dynamic) as num;
      await loadTasks();
      auth.fetchMe();
      AppAlert.success('✅ +${reward.toInt()} Coins — Task completed!');
    } else {
      AppAlert.error(res['error'] ?? 'Could not complete task');
    }
  }

  // today's position in the 7-day cycle (0-indexed)
  int get todayPosInCycle {
    if (checkedInToday.value) {
      return (currentStreak.value - 1).clamp(0, 6) % 7;
    }
    return currentStreak.value % 7;
  }

  Future<void> watchAd() async {
    if (adsWatchedToday.value >= maxAdsPerDay) {
      AppAlert.info('Limit reached — Come back tomorrow for more rewards!');
      return;
    }
    if (!AdService.instance.isRewardedReady) {
      AppAlert.info('Ad not ready — Please try again in a moment.');
      return;
    }
    await AdService.instance.showRewarded(
      onRewarded: (_) async {
        adsWatchedToday.value++;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('ads_today', adsWatchedToday.value);

        if (adsWatchedToday.value >= maxAdsPerDay) {
          // All ads watched — grant the full 100-coin bonus
          await ApiService.claimDailyReward(adCompletionBonus);
          auth.fetchMe();
          AppAlert.success('🎉 +$adCompletionBonus Coins! — You watched all $maxAdsPerDay ads today!');
        } else {
          final remaining = maxAdsPerDay - adsWatchedToday.value;
          AppAlert.info('Ad $adsWatchedToday/$maxAdsPerDay watched — Watch $remaining more to earn $adCompletionBonus coins!');
        }
      },
    );
  }

  Future<void> claimBenefit(String key, int coins, RxBool flag) async {
    if (flag.value) return;
    await ApiService.claimDailyReward(coins);
    flag.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
    auth.fetchMe();
    AppAlert.success('✅ +$coins Coins — Reward claimed!');
  }

  // Returns true if there is at least one unclaimed reached milestone
  bool get canClaimMilestone {
    for (int i = 0; i < readingMilestones.length; i++) {
      final reached = readingMinutesToday.value >= (readingMilestones[i]['mins'] as int);
      if (reached && (i >= claimedMilestones.length || !claimedMilestones[i])) {
        return true;
      }
    }
    return false;
  }

  Future<void> claimReadingMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    int totalCoins = 0;
    for (int i = 0; i < readingMilestones.length; i++) {
      final reached = readingMinutesToday.value >= (readingMilestones[i]['mins'] as int);
      final alreadyClaimed = i < claimedMilestones.length && claimedMilestones[i];
      if (reached && !alreadyClaimed) {
        totalCoins += readingMilestones[i]['coins'] as int;
        if (i < claimedMilestones.length) {
          claimedMilestones[i] = true;
        }
      }
    }

    if (totalCoins == 0) {
      AppAlert.info('Nothing to claim — Keep reading to reach a milestone!');
      return;
    }

    await ApiService.claimDailyReward(totalCoins);
    await prefs.setString('milestone_date', today);
    await prefs.setString(
      'milestones_claimed',
      claimedMilestones.asMap().entries
          .where((e) => e.value)
          .map((e) => '${e.key}')
          .join(','),
    );
    auth.fetchMe();
    AppAlert.success('🎉 +$totalCoins Coins! — Reading milestone reward claimed!');
  }

  int get readingMilestoneIndex {
    for (int i = readingMilestones.length - 1; i >= 0; i--) {
      if (readingMinutesToday.value >= readingMilestones[i]['mins']) return i;
    }
    return -1;
  }

  double get readingProgress {
    final mi   = readingMilestoneIndex;
    final prev = mi >= 0 ? readingMilestones[mi]['mins'] as int : 0;
    final next = readingMilestones.firstWhere(
      (m) => readingMinutesToday.value < m['mins'],
      orElse: () => readingMilestones.last,
    )['mins'] as int;
    if (next == prev) return 1.0;
    return (readingMinutesToday.value - prev) / (next - prev);
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl  = Get.put(RewardsController());
    final auth  = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
    final card   = isDark ? const Color(0xFF1e1e22) : Colors.white;
    final txt    = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub    = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final chip   = isDark ? const Color(0xFF2a2a30) : const Color(0xFFF0F0F0);
    final gold   = const Color(0xFF3d3800);
    final divClr = isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: txt, size: 28),
          onPressed: () => Get.back()),
        title: Column(children: [
          Text('Earn rewards', style: TextStyle(color: txt,
              fontSize: 16, fontWeight: FontWeight.w600)),
          Text('Coins can only be used on NoveluX',
              style: TextStyle(color: sub, fontSize: 11)),
        ]),
        centerTitle: true,
        actions: [IconButton(
          icon: Icon(Icons.more_vert, color: txt), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Balance card ──────────────────────────────────────────────────
          _card(card, child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => Get.to(() => const CoinHistoryScreen()),
                  child: Text('My coins ›', style: TextStyle(color: txt,
                      fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 2),
                Obx(() => Text('${auth.coins}', style: TextStyle(color: txt,
                    fontSize: 48, fontWeight: FontWeight.bold))),
                Obx(() => Text(
                  '≈ ${(auth.coins / 100).toStringAsFixed(0)} hours Ad-Free',
                  style: TextStyle(color: sub, fontSize: 12))),
              ]),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                    color: gold, borderRadius: BorderRadius.circular(24)),
                child: TextButton(
                  onPressed: () => Get.to(() => const RedeemScreen()),
                  child: const Text('Redeem', style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: chip, borderRadius: BorderRadius.circular(8)),
              child: Text('Use your coins before they expire.',
                  style: TextStyle(color: sub, fontSize: 12)),
            ),
          ])),
          const SizedBox(height: 14),

          // ── Daily check-in ────────────────────────────────────────────────
          _card(card, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Daily check-in', style: TextStyle(color: txt,
                  fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              Obx(() {
                final total = ctrl.rewardSchedule.fold(0, (a, b) => a + b);
                return Text('7-day streak: $total coins',
                    style: const TextStyle(color: Colors.orange, fontSize: 12));
              }),
            ]),
            const SizedBox(height: 14),

            // Day boxes
            Obx(() {
              final schedule = ctrl.rewardSchedule;
              final todayPos = ctrl.todayPosInCycle;
              final claimed  = ctrl.checkedInToday.value;
              return Row(children: List.generate(7, (i) {
                final reward  = i < schedule.length ? schedule[i] : 0;
                final isDone  = claimed ? i <= todayPos : i < todayPos;
                final isToday = i == todayPos;
                return Expanded(child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDone ? gold : chip,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !claimed
                        ? Border.all(color: Colors.orange, width: 1.5) : null,
                  ),
                  child: Column(children: [
                    Text('+$reward', style: TextStyle(
                        color: isDone ? Colors.orange : sub,
                        fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    isDone
                        ? const Icon(Icons.check_circle,
                            color: Colors.orange, size: 20)
                        : const Icon(Icons.star, color: Colors.orange, size: 20),
                    const SizedBox(height: 4),
                    Text(isToday ? 'Today' : 'Day ${i + 1}',
                        style: TextStyle(color: sub, fontSize: 9)),
                  ]),
                ));
              }));
            }),
            const SizedBox(height: 14),

            // Claim button
            Obx(() {
              final claimed = ctrl.checkedInToday.value;
              final loading = ctrl.isClaimingCheckin.value;
              final sched   = ctrl.rewardSchedule;
              final todayPos = ctrl.todayPosInCycle;
              // sum of unclaimed days in this 7-day cycle
              final remaining = claimed
                  ? sched.skip(todayPos + 1).fold(0, (a, b) => a + b)
                  : sched.skip(todayPos + 1).fold(0, (a, b) => a + b);
              return SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: claimed ? gold : Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: claimed ? null : ctrl.claimDailyCheckIn,
                  child: loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : claimed
                          ? Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Text('Earn $remaining more coins this week',
                                    style: const TextStyle(color: Colors.orange,
                                        fontWeight: FontWeight.bold)),
                              ])
                          : Text('Claim +${ctrl.nextReward.value} coins today',
                              style: const TextStyle(color: Colors.black,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              );
            }),

            const SizedBox(height: 10),
            Obx(() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text('${ctrl.currentStreak.value}-day streak',
                  style: TextStyle(color: sub, fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.check_circle_outline, color: sub, size: 15),
              const SizedBox(width: 4),
              Text('${ctrl.totalCheckins.value} total check-ins',
                  style: TextStyle(color: sub, fontSize: 12)),
            ])),
          ])),
          const SizedBox(height: 14),

          // ── Tasks ─────────────────────────────────────────────────────────
          _card(card, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Tasks', style: TextStyle(color: txt,
                  fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: ctrl.loadTasks,
                child: Icon(Icons.refresh, color: sub, size: 20)),
            ]),
            const SizedBox(height: 14),

            Obx(() {
              if (ctrl.isLoadingTasks.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        color: Colors.orange, strokeWidth: 2)));
              }
              if (ctrl.tasks.isEmpty) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No tasks available right now.',
                      style: TextStyle(color: sub, fontSize: 13))));
              }
              return Column(
                children: ctrl.tasks.asMap().entries.map((e) {
                  final i    = e.key;
                  final task = Map<String, dynamic>.from(e.value as Map);
                  final done = task['status'] == 'claimed';
                  return Column(children: [
                    if (i > 0) Divider(color: divClr, height: 1),
                    if (i > 0) const SizedBox(height: 14),
                    _taskRow(task, done, sub, chip, gold, txt,
                        (t, {response}) => ctrl.completeTask(t, response: response)),
                    const SizedBox(height: 14),
                  ]);
                }).toList(),
              );
            }),
          ])),
          const SizedBox(height: 14),

          // ── Daily rewards ─────────────────────────────────────────────────
          _card(card, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Daily rewards', style: TextStyle(color: txt,
                fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // Reading challenge
            Row(children: [
              Text('Reading challenge', style: TextStyle(color: txt, fontSize: 14)),
              const Spacer(),
              Obx(() {
                final canClaim = ctrl.canClaimMilestone;
                return GestureDetector(
                  onTap: canClaim ? ctrl.claimReadingMilestones : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                        color: canClaim ? Colors.orange : chip,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('Claim', style: TextStyle(
                        color: canClaim ? Colors.black : Colors.grey,
                        fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                );
              }),
            ]),
            const SizedBox(height: 14),

            // Milestone row
            Obx(() {
              final reachedIdx = ctrl.readingMilestoneIndex;
              return Column(children: [
                SizedBox(
                  height: 78,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ctrl.readingMilestones.length,
                    itemBuilder: (_, i) {
                      final m       = ctrl.readingMilestones[i];
                      final isReached  = i <= reachedIdx;
                      final isClaimed  = i < ctrl.claimedMilestones.length && ctrl.claimedMilestones[i];
                      final bgColor = isClaimed
                          ? const Color(0xFF1a3a1a)
                          : isReached ? gold : chip;
                      final labelColor = isClaimed
                          ? Colors.green
                          : isReached ? Colors.orange : sub;
                      return Container(
                        width: 68, margin: const EdgeInsets.only(right: 8),
                        child: Column(children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('+${m['coins']}', style: TextStyle(
                                    color: labelColor,
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                                isClaimed
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green, size: 16)
                                    : const Icon(Icons.star,
                                        color: Colors.orange, size: 16),
                              ]),
                          ),
                          const SizedBox(height: 4),
                          Text('${m['mins']}min',
                              style: TextStyle(color: sub, fontSize: 10)),
                        ]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ctrl.readingProgress.clamp(0.0, 1.0),
                    backgroundColor: chip,
                    color: Colors.orange,
                    minHeight: 5)),
              ]);
            }),
            const SizedBox(height: 18),
            Divider(color: divClr, height: 1),
            const SizedBox(height: 14),

            // Watch ads
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Obx(() => Text(
                  'Watch ads (${ctrl.adsWatchedToday.value}/${ctrl.maxAdsPerDay})',
                  style: TextStyle(color: txt, fontSize: 14))),
                const SizedBox(height: 4),
                const Row(children: [
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text('+100 coins', style: TextStyle(color: Colors.orange,
                      fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ]),
              const Spacer(),
              Obx(() {
                final done = ctrl.adsWatchedToday.value >= ctrl.maxAdsPerDay;
                return GestureDetector(
                  onTap: ctrl.watchAd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                        color: done ? chip : gold,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('Go', style: TextStyle(
                        color: done ? Colors.grey : Colors.orange,
                        fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                );
              }),
            ]),
          ])),
          const SizedBox(height: 14),

          // ── General benefits ──────────────────────────────────────────────
          _card(card, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('General benefits', style: TextStyle(color: txt,
                fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Obx(() => _benefitRow('Sign in', '+30 coins', txt, sub, chip, gold,
                ctrl.signInClaimed.value,
                () => ctrl.claimBenefit('signin_claimed', 30, ctrl.signInClaimed))),
            const SizedBox(height: 14),
            Divider(color: divClr, height: 1),
            const SizedBox(height: 14),
            Obx(() => _benefitRow('Enable notifications', '+200 coins',
                txt, sub, chip, gold,
                ctrl.notificationsClaimed.value,
                () => ctrl.claimBenefit(
                    'notif_claimed', 200, ctrl.notificationsClaimed))),
          ])),
          const SizedBox(height: 30),

          Center(child: Text('Terms and Conditions',
              style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _card(Color bg, {required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
    child: child,
  );

  Widget _taskRow(
    Map<String, dynamic> task,
    bool done,
    Color sub,
    Color chip,
    Color gold,
    Color txt,
    void Function(Map, {String? response}) onComplete,
  ) {
    final isResponse  = task['task_type'] == 'response';
    final reward      = task['reward_coins'] ?? 0;
    final description = task['description'] ?? '';

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(task['title'] ?? '', style: TextStyle(color: txt, fontSize: 14)),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(description, style: TextStyle(color: sub, fontSize: 12)),
        ],
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.star, color: Colors.orange, size: 15),
          const SizedBox(width: 4),
          Text('+$reward coins', style: const TextStyle(color: Colors.orange,
              fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ])),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: done ? null : () {
          if (isResponse) {
            _showResponseDialog(task, onComplete);
          } else {
            onComplete(task);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
              color: done ? chip : gold,
              borderRadius: BorderRadius.circular(20)),
          child: Text(done ? 'Done' : 'Go', style: TextStyle(
              color: done ? Colors.grey : Colors.orange,
              fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    ]);
  }

  void _showResponseDialog(
    Map<String, dynamic> task,
    void Function(Map, {String? response}) onComplete,
  ) {
    final controller = TextEditingController();
    Get.dialog(AlertDialog(
      backgroundColor: const Color(0xFF1e1e22),
      title: Text(task['title'] ?? 'Complete task',
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if ((task['prompt'] ?? '').isNotEmpty) ...[
          Text(task['prompt'], style: const TextStyle(
              color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Your answer…',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF2a2a30),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Get.back();
            onComplete(task, response: text);
          },
          child: const Text('Submit',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  Widget _benefitRow(String title, String reward, Color txt, Color sub,
      Color chip, Color gold, bool claimed, VoidCallback onClaim) =>
    Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: txt, fontSize: 14)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.star, color: Colors.orange, size: 16),
          const SizedBox(width: 4),
          Text(reward, style: const TextStyle(color: Colors.orange,
              fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: claimed ? null : onClaim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
              color: claimed ? chip : gold,
              borderRadius: BorderRadius.circular(20)),
          child: Text(claimed ? 'Done' : 'Claim',
              style: TextStyle(
                  color: claimed ? Colors.grey : Colors.orange,
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    ]);
}

// ── Coin History Screen ───────────────────────────────────────────────────────
class CoinHistoryScreen extends StatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  State<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends State<CoinHistoryScreen> {
  List _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getCoinHistory();
    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'];
      setState(() {
        _transactions = (data is List ? data : (data['results'] as List? ?? []));
        _loading = false;
      });
    } else {
      setState(() { _error = res['error'] ?? 'Failed to load'; _loading = false; });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour.toString().padLeft(2,'0');
      final m = dt.minute.toString().padLeft(2,'0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $h:$m';
    } catch (_) { return raw; }
  }

  String _label(Map txn) {
    final reason = txn['reason'] as String? ?? '';
    final type   = txn['transaction_type'] as String? ?? '';
    if (reason.isNotEmpty) return reason;
    return type.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg  = isDark ? const Color(0xFF0d0d0f) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: txt, size: 28),
          onPressed: () => Get.back(),
        ),
        title: Column(children: [
          Text('Coin History', style: TextStyle(color: txt,
              fontSize: 16, fontWeight: FontWeight.w600)),
          Text('Only displaying past 30 days\' records',
              style: TextStyle(color: sub, fontSize: 11)),
        ]),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: sub)))
              : _transactions.isEmpty
                  ? Center(child: Text('No coin activity in the last 30 days.',
                      style: TextStyle(color: sub)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, __) => Divider(
                          color: isDark
                              ? const Color(0xFF2a2a2a)
                              : Colors.grey[200]!,
                          height: 1),
                      itemBuilder: (_, i) {
                        final t = _transactions[i] as Map;
                        final amount = (t['amount'] as num?) ?? 0;
                        final isCredit = amount >= 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(_label(t),
                                    style: TextStyle(color: txt,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(_formatDate(t['created_at'] as String?),
                                    style: TextStyle(color: sub, fontSize: 12)),
                              ]),
                            ),
                            Text(
                              '${isCredit ? '+' : ''}$amount coins',
                              style: TextStyle(
                                color: isCredit
                                    ? Colors.orange
                                    : Colors.red[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
    );
  }
}
