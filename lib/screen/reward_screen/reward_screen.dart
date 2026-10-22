import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:novelux/config/ad_service.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/coins/coin_store_screen.dart';
import 'package:novelux/screen/redeem/redeem_screen.dart';
import 'package:novelux/widgets/auth_prompt_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:novelux/core/constants/app_constants.dart';

// ── Controller ────────────────────────────────────────────────────────────────
class RewardsController extends GetxController {
  final auth = Get.find<AuthController>();

  // check-in (backend-driven)
  final RxBool checkedInToday    = false.obs;
  final RxBool isClaimingCheckin = false.obs;
  final RxInt  currentStreak     = 0.obs;
  final RxInt  longestStreak     = 0.obs;
  final RxInt  totalCheckins     = 0.obs;
  final RxInt  nextReward        = 5.obs;
  final RxList<int> rewardSchedule = <int>[5, 8, 10, 12, 15, 18, 20].obs;

  // tasks (backend-driven). Response tasks show under "Tasks"; action tasks
  // (Go → wait → Claim) show under "General benefits".
  final RxList tasks          = [].obs;
  final RxBool isLoadingTasks = false.obs;
  final Map<int, TextEditingController> answerControllers = {};
  /// When each started action task can be claimed (server time, local copy).
  final RxMap<int, DateTime> claimReadyAt = <int, DateTime>{}.obs;
  /// Ticks every second while any action task is counting down.
  final RxInt clock = 0.obs;
  Timer? _ticker;

  List<Map<String, dynamic>> get responseTasks => tasks
      .map((t) => Map<String, dynamic>.from(t as Map))
      .where((t) => t['task_type'] == 'response').toList();
  List<Map<String, dynamic>> get actionTasks => tasks
      .map((t) => Map<String, dynamic>.from(t as Map))
      .where((t) => t['task_type'] != 'response').toList();

  // Rewards — the server sets the amounts; these are for display.
  static const int signInBonus       = 5;
  static const int notificationBonus = 10;
  static const int adBonus           = 1;   // per rewarded ad
  static const int checkinAdBonus    = 5;   // watch an ad after checking in

  // Ad rewards (backend-driven): watch N ads → bonus, resets daily.
  final RxList adTasks           = [].obs;
  final RxBool isWatchingAdTask  = false.obs;
  static const int adTasksPreview = 4;   // shown on this screen; "See more" shows all

  // local-only
  final RxInt  adsWatchedToday       = 0.obs;
  final int    maxAdsPerDay          = 10;
  final RxBool checkinAdClaimed      = false.obs;
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
    // Streaks and tasks are server-side and 401 without a token. A guest sees
    // the same layout with sign-in prompts on every action, so there is
    // nothing to fetch until they have an account.
    if (Get.find<AuthController>().isLoggedIn.value) {
      loadCheckinStatus();
      loadTasks();
      loadAdTasks();
    }
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = prefs.getString('checkin_date') ?? '';
    adsWatchedToday.value      = saved == today ? (prefs.getInt('ads_today') ?? 0) : 0;
    readingMinutesToday.value  = prefs.getInt('reading_mins') ?? 0;
    signInClaimed.value        = prefs.getBool('signin_claimed') ?? false;
    notificationsClaimed.value = prefs.getBool('notif_claimed') ?? false;
    checkinAdClaimed.value     = prefs.getString('checkin_ad_date') == today;

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
    // Only offer the ad when one has actually loaded.
    final adAvailable =
        !checkinAdClaimed.value && AdService.instance.isRewardedReady;
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
              "You've earned $coinsEarned bonus coins! Come back tomorrow to keep your streak going.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (adAvailable) ...[
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
                  label: const Text('Watch an ad for +$checkinAdBonus more',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    Get.back();
                    watchCheckinAd();
                  },
                ),
              ),
            ],
            TextButton(
              onPressed: () => Get.back(),
              child: Text(adAvailable ? 'Not now' : 'OK',
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }

  /// The ad offered after checking in: +[checkinAdBonus], once a day.
  Future<void> watchCheckinAd() async {
    if (checkinAdClaimed.value) return;
    if (!AdService.instance.isRewardedReady) {
      AppAlert.info('No ad available right now — try again later.');
      return;
    }
    await AdService.instance.showRewarded(onRewarded: (_) async {
      final res = await ApiService.claimDailyReward(checkinAdBonus, claimType: 'checkin_ad');
      if (res['success'] == true) {
        checkinAdClaimed.value = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('checkin_ad_date', DateTime.now().toIso8601String().substring(0, 10));
        auth.refreshCoins();
        AppAlert.success('🎉 +$checkinAdBonus bonus coins!');
      } else {
        AppAlert.error(res['error'] ?? 'Could not add the ad bonus');
      }
    });
  }

  Future<void> loadTasks() async {
    isLoadingTasks.value = true;
    final res = await ApiService.getTasks();
    isLoadingTasks.value = false;
    if (res['success'] == true) {
      final d = res['data'] as Map? ?? {};
      tasks.value = (d['results'] as List? ?? []);
      // Restore countdowns for action tasks started earlier.
      for (final t in actionTasks) {
        final at = DateTime.tryParse(t['claim_available_at'] ?? '');
        if (at != null) claimReadyAt[t['id'] as int] = at.toLocal();
      }
      _syncTicker();
    }
  }

  TextEditingController answerFor(int taskId) =>
      answerControllers.putIfAbsent(taskId, () => TextEditingController());

  Future<void> completeTask(Map task, {String? response}) async {
    final id  = task['id'] as int;
    final res = await ApiService.completeTask(id, response: response);
    if (res['success'] == true) {
      final d      = res['data'] as Map? ?? {};
      final reward = (d['coins_earned'] ?? task['reward_coins'] ?? 0 as dynamic) as num;
      claimReadyAt.remove(id);
      answerControllers[id]?.clear();
      await loadTasks();
      auth.refreshCoins();
      AppAlert.success('✅ +${reward.toInt()} bonus coins — task completed!');
    } else {
      AppAlert.error(res['error'] ?? 'Could not complete task');
      await loadTasks();   // refresh tries left / claim time
    }
  }

  /// Opens a task's link (if it has one) in the browser / its app.
  Future<void> launchTaskUrl(Map task) async {
    final url = (task['launch_url'] ?? '').toString();
    if (url.isEmpty) return;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) AppAlert.error('Could not open the link');
  }

  /// General-benefit task: open its link and start the wait before Claim.
  Future<void> startActionTask(Map task) async {
    final id = task['id'] as int;
    await launchTaskUrl(task);
    final res = await ApiService.startTask(id);
    if (res['success'] == true) {
      final at = DateTime.tryParse((res['data'] as Map?)?['claim_available_at'] ?? '');
      claimReadyAt[id] = (at ?? DateTime.now()).toLocal();
      _syncTicker();
    } else {
      AppAlert.error(res['error'] ?? 'Could not start the task');
    }
  }

  /// Seconds left before an action task can be claimed (0 = ready, -1 = not started).
  int secondsUntilClaim(int taskId) {
    clock.value;   // rebuild every tick
    final at = claimReadyAt[taskId];
    if (at == null) return -1;
    final left = at.difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  void _syncTicker() {
    final counting = claimReadyAt.values.any((t) => t.isAfter(DateTime.now()));
    if (counting && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        clock.value++;
        if (!claimReadyAt.values.any((t) => t.isAfter(DateTime.now()))) {
          _ticker?.cancel();
          _ticker = null;
        }
      });
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    for (final c in answerControllers.values) {
      c.dispose();
    }
    super.onClose();
  }

  // today's position in the 7-day cycle (0-indexed)
  int get todayPosInCycle {
    if (checkedInToday.value) {
      // Today is already counted in the streak. (The old code clamped to 6
      // before taking % 7, so from day 8 on it stuck on the last box.)
      return currentStreak.value <= 0 ? 0 : (currentStreak.value - 1) % 7;
    }
    return currentStreak.value % 7;
  }

  Future<void> loadAdTasks() async {
    final res = await ApiService.getAdTasks();
    if (res['success'] == true) {
      adTasks.value = ((res['data'] as Map?)?['results'] as List? ?? []);
    }
  }

  /// Ad rewards: show one rewarded ad and count it toward [task]. One-ad
  /// tasks end with a coin toast; 2+ ad tasks show the progress popup.
  Future<void> watchAdTask(Map task) async {
    if (isWatchingAdTask.value) return;
    if (task['completed'] == true) return;
    if (!AdService.instance.isRewardedReady) {
      AppAlert.info('No ad available right now — please try again in a moment.');
      return;
    }
    isWatchingAdTask.value = true;
    try {
      await AdService.instance.showRewarded(onRewarded: (_) async {
        final res = await ApiService.adTaskWatched(task['id'] as int);
        if (res['success'] != true) {
          AppAlert.error(res['error'] ?? 'Could not record the ad');
          await loadAdTasks();
          return;
        }
        final d = Map<String, dynamic>.from(res['data'] as Map? ?? {});
        await loadAdTasks();
        if (d['completed'] == true) auth.refreshCoins();
        if ((d['ads_required'] as num? ?? 1) <= 1) {
          if (d['completed'] == true) {
            _bonusToast((d['coins_earned'] as num? ?? 0).toInt(),
                (d['valid_days'] as num? ?? 7).toInt());
          }
        } else {
          _adProgressPopup(d);
        }
      });
    } finally {
      isWatchingAdTask.value = false;
    }
  }

  /// Toast with a coin, for one-ad tasks.
  void _bonusToast(int coins, int validDays) {
    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 14,
      backgroundColor: const Color(0xFF2A251F),
      duration: const Duration(seconds: 3),
      icon: Container(
        margin: const EdgeInsets.only(left: 8),
        width: 30, height: 30,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE5A823)),
        child: const Icon(LucideIcons.sparkle, color: Color(0xFF2A251F), size: 16),
      ),
      titleText: Text('Congratulations! +$coins bonus coin${coins == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      messageText: Text('Your bonus is valid for $validDays days — use it before it expires.',
          style: const TextStyle(color: Color(0xFFE8E2D8), fontSize: 12.5)),
    );
  }

  /// Progress popup for 2+ ad tasks: after each ad, and the reward at the end.
  void _adProgressPopup(Map<String, dynamic> d) {
    final done      = d['completed'] == true;
    final watched   = (d['ads_watched'] as num? ?? 0).toInt();
    final required  = (d['ads_required'] as num? ?? 1).toInt();
    final reward    = (d['reward_coins'] as num? ?? 0).toInt();
    final validDays = (d['valid_days'] as num? ?? 7).toInt();
    final adReady   = AdService.instance.isRewardedReady;
    const ink = Color(0xFF3A2614);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
          Container(
            margin: const EdgeInsets.only(top: 70),
            padding: const EdgeInsets.fromLTRB(22, 70, 22, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF1DA), Color(0xFFFFFBF0)]),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(done ? "You've got" : 'Ad watched!',
                  style: const TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(color: const Color(0x14E5A823),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 38, height: 38,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE5A823)),
                      child: const Icon(LucideIcons.sparkle, color: Colors.white, size: 20)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('+$reward Bonus', style: const TextStyle(color: ink, fontSize: 17,
                        fontWeight: FontWeight.w700)),
                    Text(done ? 'Valid for $validDays days' : 'After ${required - watched} more ad${required - watched == 1 ? '' : 's'}',
                        style: const TextStyle(color: Color(0xFF8A7A66), fontSize: 12.5)),
                  ]),
                ]),
              ),
              const SizedBox(height: 18),
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: watched / required, minHeight: 8,
                    backgroundColor: const Color(0x22E5A823), color: const Color(0xFFE5A823))),
              const SizedBox(height: 8),
              Text('Progress: $watched/$required',
                  style: const TextStyle(color: Color(0xFF8A7A66), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),
              if (!done) SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5A823), foregroundColor: ink,
                      elevation: 0, shape: const StadiumBorder()),
                  onPressed: adReady ? () { Get.back(); watchAdTask(d); } : null,
                  child: Text(adReady ? 'Watch next ad' : 'No ad available right now',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              if (done) Text('Bonus coins are spent before your purchased coins.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8A7A66), fontSize: 12)),
              const SizedBox(height: 6),
              TextButton(onPressed: () => Get.back(),
                  child: Text(done ? 'Great!' : 'Later', style: const TextStyle(color: Color(0xFF8A7A66)))),
            ]),
          ),
          Image.asset('assets/images/rewards_gift_coins.png', width: 170, height: 140, fit: BoxFit.contain),
        ]),
      ),
    );
  }

  Future<void> watchAd() async {
    if (adsWatchedToday.value >= maxAdsPerDay) {
      AppAlert.info('Limit reached — come back tomorrow for more rewards!');
      return;
    }
    if (!AdService.instance.isRewardedReady) {
      AppAlert.info('No ad available right now — please try again in a moment.');
      return;
    }
    await AdService.instance.showRewarded(
      onRewarded: (_) async {
        final res = await ApiService.claimDailyReward(adBonus, claimType: 'ad');
        if (res['success'] == true) {
          final d = res['data'] as Map? ?? {};
          adsWatchedToday.value =
              (d['claimed_today'] as num?)?.toInt() ?? adsWatchedToday.value + 1;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('ads_today', adsWatchedToday.value);
          auth.refreshCoins();
          AppAlert.success('+$adBonus bonus coin — ad ${adsWatchedToday.value}/$maxAdsPerDay');
        } else {
          AppAlert.error(res['error'] ?? 'Could not add the ad reward');
        }
      },
    );
  }

  /// Sign-in (+5) and notifications (+10). Marked done only when the
  /// server confirms the coins were added.
  Future<void> claimBenefit(String key, String claimType, int coins, RxBool flag) async {
    if (flag.value) return;
    if (claimType == 'notification') {
      final settings = await FirebaseMessaging.instance.requestPermission();
      final ok = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!ok) {
        AppAlert.info('Turn on notifications for HuxNovel in your phone settings, then claim again.');
        return;
      }
    }
    final res = await ApiService.claimDailyReward(coins, claimType: claimType);
    final already = (res['error'] ?? '').toString().toLowerCase().contains('already');
    if (res['success'] == true || already) {
      flag.value = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
      auth.refreshCoins();
      if (!already) AppAlert.success('✅ +$coins bonus coins — reward claimed!');
    } else {
      AppAlert.error(res['error'] ?? 'Could not claim the reward');
    }
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

    final res = await ApiService.claimDailyReward(totalCoins, claimType: 'reading');
    if (res['success'] != true) {
      await _loadLocal();   // undo the optimistic ticks
      AppAlert.error(res['error'] ?? 'Could not claim the reading reward');
      return;
    }
    await prefs.setString('milestone_date', today);
    await prefs.setString(
      'milestones_claimed',
      claimedMilestones.asMap().entries
          .where((e) => e.value)
          .map((e) => '${e.key}')
          .join(','),
    );
    auth.refreshCoins();
    AppAlert.success('🎉 +$totalCoins bonus coins — reading milestone claimed!');
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
/// Coin balances, streaks, milestones and claims all live server-side, so
/// every action on this screen needs an account. Guests get the sign-in sheet
/// rather than a silent 401.
bool _requireAccount() {
  if (Get.find<AuthController>().isLoggedIn.value) return true;
  promptSignIn(AuthPromptReason.rewards);
  return false;
}

bool get _isGuest => !Get.find<AuthController>().isLoggedIn.value;

/// Colours for the reward screen (light design + matching dark variant).
class _RewardTheme {
  final bool dark;
  const _RewardTheme(this.dark);

  Color get page     => dark ? const Color(0xFF0F0F12) : const Color(0xFFF6F4EF);
  Color get hero     => dark ? const Color(0xFF16161A) : Colors.white;
  Color get card     => dark ? const Color(0xFF1E1E22) : Colors.white;
  Color get ink      => dark ? Colors.white : const Color(0xFF1F1B16);
  Color get sub      => dark ? const Color(0xFFA19B92) : const Color(0xFF7A746B);
  Color get line     => dark ? const Color(0xFF2C2C32) : const Color(0xFFEEEBE5);
  Color get gold     => const Color(0xFFE5A823);
  Color get goldText => dark ? const Color(0xFFF0BE4E) : const Color(0xFFB07A12);
  Color get cream    => dark ? const Color(0x24E5A823) : const Color(0xFFFDF3D8);
  Color get tile     => dark ? const Color(0xFF2A2A30) : const Color(0xFFF3F2EF);
  Color get todayBg  => dark ? const Color(0xFFE5A823) : const Color(0xFF2A251F);
  Color get todayFg  => dark ? const Color(0xFF1F1B16) : Colors.white;
  Color get todayAcc => dark ? const Color(0xFF1F1B16) : const Color(0xFFE5A823);
  Color get greenBg  => dark ? const Color(0xFF1C2A20) : const Color(0xFFEBF2EC);
  Color get greenFg  => dark ? const Color(0xFF8FB79A) : const Color(0xFF6E8C76);
  Color get field    => dark ? const Color(0xFF2A2A30) : const Color(0xFFF6F4EF);
  Color get submitBg => dark ? const Color(0xFFE5A823) : const Color(0xFF2A251F);
  Color get submitFg => dark ? const Color(0xFF1F1B16) : Colors.white;
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(RewardsController());
    final auth = Get.find<AuthController>();
    final t    = _RewardTheme(Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: t.page,
      appBar: AppBar(
        backgroundColor: t.hero,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: t.ink, size: 24),
            onPressed: () => Get.back()),
        title: Text(AppConstants.appName,
            style: TextStyle(color: t.ink, fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [IconButton(icon: Icon(LucideIcons.ellipsisVertical, color: t.ink, size: 20),
            onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _hero(ctrl, auth, t),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _checkInSection(ctrl, t),
              const SizedBox(height: 26),
              _dailyRewardsSection(ctrl, t),
              const SizedBox(height: 26),
              _adRewardsSection(ctrl, t),
              const SizedBox(height: 26),
              _tasksSection(ctrl, t),
              const SizedBox(height: 26),
              _generalBenefitsSection(ctrl, t),
              const SizedBox(height: 26),
              Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Terms and Conditions', style: TextStyle(color: t.sub, fontSize: 13)),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, color: t.sub, size: 14),
              ])),
              const SizedBox(height: 32),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Top: title, bonus, redeem, coin balance ─────────────────────────────
  Widget _hero(RewardsController ctrl, AuthController auth, _RewardTheme t) => Container(
    width: double.infinity,
    color: t.hero,
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Earn rewards', style: TextStyle(color: t.ink, fontSize: 28, fontWeight: FontWeight.w400)),
      const SizedBox(height: 4),
      Text('Coins can only be used on ${AppConstants.appName}',
          style: TextStyle(color: t.sub, fontSize: 13)),
      const SizedBox(height: 22),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () { if (_requireAccount()) Get.to(() => const CoinHistoryScreen()); },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Bonus', style: TextStyle(color: t.sub, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, color: t.sub, size: 15),
            ]),
          ),
          const SizedBox(height: 2),
          Row(children: [
            Obx(() => Text('${auth.bonus}', style: TextStyle(color: t.ink,
                fontSize: 52, fontWeight: FontWeight.w500, height: 1.1))),
            const SizedBox(width: 10),
            _coinBadge(t, size: 26),
          ]),
          const SizedBox(height: 4),
          Obx(() => Text('≈ ${((auth.bonus + auth.coins) / 100).toStringAsFixed(0)} hours Ad-Free',
              style: TextStyle(color: t.sub, fontSize: 13))),
        ])),
        Image.asset('assets/images/rewards_gift_coins.png', width: 132, height: 106, fit: BoxFit.contain),
      ]),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: t.gold, foregroundColor: const Color(0xFF1F1B16),
            elevation: 0, shape: const StadiumBorder()),
          onPressed: () { if (_requireAccount()) Get.to(() => const RedeemScreen()); },
          child: const Text('Redeem', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ),
      const SizedBox(height: 14),
      Text('Bonus coins are earned here and spent before your purchased coins.',
          style: TextStyle(color: t.sub, fontSize: 12.5, height: 1.45)),
      const SizedBox(height: 14),
      Divider(color: t.line, height: 1),
      InkWell(
        onTap: () { if (_requireAccount()) Get.to(() => const CoinStoreScreen()); },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            _coinBadge(t, size: 20),
            const SizedBox(width: 10),
            Obx(() => Text('Coin balance: ${auth.coins}',
                style: TextStyle(color: t.ink, fontSize: 15))),
            const Spacer(),
            Text('Get coins', style: TextStyle(color: t.goldText, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, color: t.goldText, size: 15),
          ]),
        ),
      ),
    ]),
  );

  // ── Daily check-in ──────────────────────────────────────────────────────
  Widget _checkInSection(RewardsController ctrl, _RewardTheme t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _sectionTitle('Daily check-in', t),
        const Spacer(),
        Obx(() => Text('7-day streak: ${ctrl.rewardSchedule.fold(0, (a, b) => a + b)} coins',
            style: TextStyle(color: t.goldText, fontSize: 12.5, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 12),
      _card(t, child: Column(children: [
        Obx(() {
          final schedule = ctrl.rewardSchedule;
          final todayPos = ctrl.todayPosInCycle;
          final claimed  = ctrl.checkedInToday.value;
          return Row(children: List.generate(7, (i) {
            final reward  = i < schedule.length ? schedule[i] : 0;
            final isDone  = claimed ? i <= todayPos : i < todayPos;
            final isToday = i == todayPos;
            final bg  = isToday ? t.todayBg : (isDone ? t.cream : t.tile);
            final acc = isToday ? t.todayAcc : (isDone ? t.goldText : t.sub);
            return Expanded(child: Container(
              margin: EdgeInsets.only(right: i < 6 ? 5 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Text('+$reward', style: TextStyle(color: acc, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Icon(isDone ? LucideIcons.circleCheck : LucideIcons.star,
                    color: isDone ? acc : t.sub.withValues(alpha: 0.6), size: 18),
                const SizedBox(height: 8),
                Text(isToday ? 'Today' : 'Day ${i + 1}',
                    style: TextStyle(color: isToday ? t.todayFg : t.sub, fontSize: 10)),
              ]),
            ));
          }));
        }),
        const SizedBox(height: 14),
        Obx(() {
          final claimed  = ctrl.checkedInToday.value;
          final loading  = ctrl.isClaimingCheckin.value;
          final remaining = ctrl.rewardSchedule.skip(ctrl.todayPosInCycle + 1).fold(0, (a, b) => a + b);
          final label = _isGuest ? 'Sign in to check in'
              : claimed ? 'Earn $remaining more coins this week'
              : 'Claim +${ctrl.nextReward.value} coins today';
          final active = _isGuest || !claimed;
          return GestureDetector(
            onTap: _isGuest
                ? () => promptSignIn(AuthPromptReason.rewards)
                : (claimed || loading ? null : ctrl.claimDailyCheckIn),
            child: Container(
              width: double.infinity, height: 46,
              decoration: BoxDecoration(
                  color: active ? t.gold : t.cream, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: loading
                  ? SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: t.ink))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.sparkles, size: 16,
                          color: active ? const Color(0xFF1F1B16) : t.goldText),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(
                          color: active ? const Color(0xFF1F1B16) : t.goldText,
                          fontSize: 14, fontWeight: FontWeight.w500)),
                    ]),
            ),
          );
        }),
        const SizedBox(height: 14),
        Obx(() => Row(children: [
          Icon(LucideIcons.flame, color: t.sub, size: 15),
          const SizedBox(width: 6),
          Text('${ctrl.currentStreak.value}-day streak', style: TextStyle(color: t.sub, fontSize: 12.5)),
          const Spacer(),
          Icon(LucideIcons.circleCheck, color: t.sub, size: 15),
          const SizedBox(width: 6),
          Text('${ctrl.totalCheckins.value} total check-ins', style: TextStyle(color: t.sub, fontSize: 12.5)),
        ])),
      ])),
    ]);

  // ── Daily rewards: reading challenge + ads ──────────────────────────────
  Widget _dailyRewardsSection(RewardsController ctrl, _RewardTheme t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Daily rewards', t),
      const SizedBox(height: 12),
      _card(t, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.bookOpen, color: t.ink, size: 20),
          const SizedBox(width: 10),
          Text('Reading challenge', style: TextStyle(color: t.ink, fontSize: 15.5)),
          const Spacer(),
          Obx(() {
            final can = ctrl.canClaimMilestone;
            return _pill(can ? 'Claim' : 'Claim', t,
                style: can ? _PillStyle.solid : _PillStyle.muted,
                onTap: _isGuest
                    ? () => promptSignIn(AuthPromptReason.rewards)
                    : (can ? ctrl.claimReadingMilestones : null));
          }),
        ]),
        const SizedBox(height: 16),
        Obx(() {
          final reachedIdx = ctrl.readingMilestoneIndex;
          return Column(children: [
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ctrl.readingMilestones.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final m         = ctrl.readingMilestones[i];
                  final isReached = i <= reachedIdx;
                  final isClaimed = i < ctrl.claimedMilestones.length && ctrl.claimedMilestones[i];
                  final bg  = isClaimed ? t.greenBg : (isReached ? t.cream : t.tile);
                  final fg  = isClaimed ? t.greenFg : (isReached ? t.goldText : t.sub);
                  return Column(children: [
                    Container(
                      width: 62, height: 62,
                      decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(12),
                        border: isReached && !isClaimed ? Border.all(color: t.gold, width: 1.5) : null),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('+${m['coins']}', style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Icon(isClaimed ? LucideIcons.circleCheck : LucideIcons.star,
                            color: isClaimed ? fg : (isReached ? t.gold : t.sub.withValues(alpha: 0.6)),
                            size: 15),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text('${m['mins']} min', style: TextStyle(
                        color: isReached && !isClaimed ? t.goldText : t.sub, fontSize: 11.5)),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ctrl.readingProgress.clamp(0.0, 1.0),
                backgroundColor: t.line, color: t.gold, minHeight: 4)),
          ]);
        }),
        const SizedBox(height: 16),
        Divider(color: t.line, height: 1),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Obx(() => Text.rich(TextSpan(children: [
              TextSpan(text: 'Watch ads  ', style: TextStyle(color: t.ink, fontSize: 15.5, fontWeight: FontWeight.w600)),
              TextSpan(text: '${ctrl.adsWatchedToday.value}/${ctrl.maxAdsPerDay}',
                  style: TextStyle(color: t.sub, fontSize: 13)),
            ]))),
            const SizedBox(height: 6),
            _rewardLine('+${RewardsController.adBonus} bonus coin each', t),
          ])),
          Obx(() {
            final done = ctrl.adsWatchedToday.value >= ctrl.maxAdsPerDay;
            return _pill(done ? 'Done' : 'Go', t,
                style: done ? _PillStyle.muted : _PillStyle.soft,
                onTap: done ? null : () { if (_requireAccount()) ctrl.watchAd(); });
          }),
        ]),
      ])),
    ]);

  // ── Ad rewards ───────────────────────────────────────────────────────────
  Widget _adRewardsSection(RewardsController ctrl, _RewardTheme t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _sectionTitle('Ad rewards', t),
        const Spacer(),
        GestureDetector(
          onTap: () { if (_requireAccount()) Get.to(() => const AdRewardsScreen()); },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('See more', style: TextStyle(color: t.goldText, fontSize: 13.5, fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            Icon(LucideIcons.chevronRight, color: t.goldText, size: 15),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      _card(t, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _adRewardsHeader(t),
        Obx(() {
          final list = ctrl.adTasks.take(RewardsController.adTasksPreview)
              .map((e) => Map<String, dynamic>.from(e as Map)).toList();
          if (list.isEmpty) {
            return Padding(padding: const EdgeInsets.only(top: 16),
                child: Text(_isGuest ? 'Sign in to earn ad rewards.' : 'No ad rewards right now.',
                    style: TextStyle(color: t.sub, fontSize: 13)));
          }
          return Column(children: [
            for (final task in list) ...[
              Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: t.line, height: 1)),
              _adTaskTile(ctrl, task, t),
            ],
          ]);
        }),
      ])),
    ]);

  // ── Tasks (questions with an answer) ────────────────────────────────────
  Widget _tasksSection(RewardsController ctrl, _RewardTheme t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _sectionTitle('Tasks', t),
        const Spacer(),
        GestureDetector(
          onTap: () { if (_requireAccount()) ctrl.loadTasks(); },
          child: Icon(LucideIcons.refreshCw, color: t.sub, size: 20)),
      ]),
      const SizedBox(height: 12),
      _card(t, child: Obx(() {
        if (ctrl.isLoadingTasks.value) {
          return Padding(padding: const EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: t.gold, strokeWidth: 2)));
        }
        final list = ctrl.responseTasks;
        if (list.isEmpty) {
          return Padding(padding: const EdgeInsets.all(16),
              child: Center(child: Text('No tasks available right now.',
                  style: TextStyle(color: t.sub, fontSize: 13))));
        }
        return Column(children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) Padding(padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: t.line, height: 1)),
            _responseTask(ctrl, list[i], t),
          ],
        ]);
      })),
    ]);

  Widget _responseTask(RewardsController ctrl, Map<String, dynamic> task, _RewardTheme t) {
    final id          = task['id'] as int;
    final done        = task['status'] == 'claimed';
    final description = (task['description'] ?? '').toString();
    final hasLink     = (task['launch_url'] ?? '').toString().isNotEmpty;
    final triesLeft   = task['attempts_left'] as int?;
    final locked      = !done && triesLeft == 0;
    final input       = ctrl.answerFor(id);

    void submit() {
      if (!_requireAccount()) return;
      final text = input.text.trim();
      if (text.isEmpty) {
        AppAlert.info('Type your answer first');
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      ctrl.completeTask(task, response: text);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task['title'] ?? '', style: TextStyle(color: t.ink, fontSize: 15.5)),
          const SizedBox(height: 6),
          _rewardLine('+${task['reward_coins'] ?? 0} bonus coins', t),
        ])),
        if (done || locked)
          _pill(done ? 'Done' : 'Locked', t, style: _PillStyle.muted)
        else if (hasLink)
          _pill('Launch', t, style: _PillStyle.soft, onTap: () => ctrl.launchTaskUrl(task)),
      ]),
      if (description.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(description, style: TextStyle(color: t.sub, fontSize: 13, height: 1.45)),
      ],
      if (!done && !locked) ...[
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: TextField(
            controller: input,
            style: TextStyle(color: t.ink, fontSize: 14),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Your answer…',
              hintStyle: TextStyle(color: t.sub),
              filled: true,
              fillColor: t.field,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.gold)),
            ),
          )),
          const SizedBox(width: 8),
          _pill('Submit', t, style: _PillStyle.dark, onTap: submit),
        ]),
        if (triesLeft != null && triesLeft < 5) ...[
          const SizedBox(height: 8),
          Text('$triesLeft tr${triesLeft == 1 ? 'y' : 'ies'} left',
              style: TextStyle(color: t.sub, fontSize: 12)),
        ],
      ],
    ]);
  }

  // ── General benefits ────────────────────────────────────────────────────
  Widget _generalBenefitsSection(RewardsController ctrl, _RewardTheme t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('General benefits', t),
      const SizedBox(height: 12),
      _card(t, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Little actions.\nMore rewards.', style: TextStyle(color: t.ink,
                fontSize: 18, fontWeight: FontWeight.w700, height: 1.25)),
            const SizedBox(height: 8),
            Text('Make the most of ${AppConstants.appName}.',
                style: TextStyle(color: t.sub, fontSize: 13)),
          ])),
          Image.asset('assets/images/rewards_gift_box.png', width: 104, height: 80, fit: BoxFit.contain),
        ]),
        Obx(() => Column(children: [
          for (final task in ctrl.actionTasks) ...[
            _benefitDivider(t),
            _actionTask(ctrl, task, t),
          ],
        ])),
        _benefitDivider(t),
        Obx(() => _benefitItem(
          icon: Icon(LucideIcons.logIn, color: t.ink, size: 18),
          title: 'Sign in',
          reward: '+${RewardsController.signInBonus} bonus coins',
          trailing: ctrl.signInClaimed.value
              ? _pill('Done', t, style: _PillStyle.muted)
              : _pill('Claim', t, style: _PillStyle.soft, onTap: _isGuest
                  ? () => promptSignIn(AuthPromptReason.rewards)
                  : () => ctrl.claimBenefit('signin_claimed', 'signin',
                      RewardsController.signInBonus, ctrl.signInClaimed)),
          t: t)),
        _benefitDivider(t),
        Obx(() => _benefitItem(
          icon: Icon(LucideIcons.bell, color: t.ink, size: 18),
          title: 'Enable notifications',
          reward: '+${RewardsController.notificationBonus} bonus coins',
          trailing: ctrl.notificationsClaimed.value
              ? _pill('Done', t, style: _PillStyle.muted)
              : _pill('Claim', t, style: _PillStyle.soft, onTap: _isGuest
                  ? () => promptSignIn(AuthPromptReason.rewards)
                  : () => ctrl.claimBenefit('notif_claimed', 'notification',
                      RewardsController.notificationBonus, ctrl.notificationsClaimed)),
          t: t)),
      ])),
    ]);

  Widget _benefitDivider(_RewardTheme t) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: t.line, height: 1));

  /// Title on its own line (with icon), reward + button on the line below.
  Widget _benefitItem({required Widget icon, required String title, required String reward,
      required Widget trailing, required _RewardTheme t}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        icon,
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(color: t.ink, fontSize: 15))),
      ]),
      const SizedBox(height: 10),
      Row(children: [_rewardLine(reward, t), const Spacer(), trailing]),
    ]);

  Widget _actionTask(RewardsController ctrl, Map<String, dynamic> task, _RewardTheme t) {
    final id   = task['id'] as int;
    final done = task['status'] == 'claimed';
    return _benefitItem(
      icon: _taskIcon(task, t),
      title: (task['title'] ?? '').toString(),
      reward: '+${task['reward_coins'] ?? 0} bonus coins',
      trailing: Obx(() {
        if (done) return _pill('Done', t, style: _PillStyle.muted);
        final left = ctrl.secondsUntilClaim(id);
        if (left < 0) {
          return _pill('Go', t, style: _PillStyle.soft,
              onTap: () { if (_requireAccount()) ctrl.startActionTask(task); });
        }
        if (left > 0) {
          return _pill('Claim in ${left}s', t, style: _PillStyle.muted,
              onTap: () => ctrl.launchTaskUrl(task));
        }
        return _pill('Claim', t, style: _PillStyle.soft, onTap: () => ctrl.completeTask(task));
      }),
      t: t,
    );
  }

  /// Picks a line icon from the task's link or title.
  Widget _taskIcon(Map<String, dynamic> task, _RewardTheme t) {
    final hint = '${task['launch_url'] ?? ''} ${task['title'] ?? ''}'.toLowerCase();
    if (hint.contains('instagram')) return _InstagramGlyph(color: t.ink);
    final icon = hint.contains('whatsapp') || hint.contains('telegram') ? LucideIcons.messageCircle
        : hint.contains('rate') || hint.contains('review') || hint.contains('store') ? LucideIcons.star
        : hint.contains('share') ? LucideIcons.share2
        : LucideIcons.sparkles;
    return Icon(icon, color: t.ink, size: 18);
  }

  // ── Small pieces ────────────────────────────────────────────────────────
  Widget _sectionTitle(String text, _RewardTheme t) =>
      Text(text, style: TextStyle(color: t.ink, fontSize: 19, fontWeight: FontWeight.w700));

  Widget _card(_RewardTheme t, {required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20)),
    child: child,
  );

  Widget _coinBadge(_RewardTheme t, {double size = 22}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.gold, width: 1.6)),
    child: Icon(LucideIcons.sparkle, color: t.gold, size: size * 0.55),
  );

  Widget _rewardLine(String text, _RewardTheme t) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(LucideIcons.star, color: t.gold, size: 15),
    const SizedBox(width: 6),
    Text(text, style: TextStyle(color: t.goldText, fontSize: 13, fontWeight: FontWeight.w600)),
  ]);

  Widget _pill(String label, _RewardTheme t, {_PillStyle style = _PillStyle.soft, VoidCallback? onTap}) {
    final (bg, fg) = switch (style) {
      _PillStyle.solid => (t.gold, const Color(0xFF1F1B16)),
      _PillStyle.soft  => (t.cream, t.goldText),
      _PillStyle.dark  => (t.submitBg, t.submitFg),
      _PillStyle.muted => (t.tile, t.sub),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
        child: Text(label, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

enum _PillStyle { solid, soft, dark, muted }

/// Simple camera glyph for Instagram tasks (Lucide no longer ships brand icons).
class _InstagramGlyph extends StatelessWidget {
  final Color color;
  const _InstagramGlyph({required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18, height: 18,
    child: Stack(alignment: Alignment.center, children: [
      Container(decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5), border: Border.all(color: color, width: 1.6))),
      Container(width: 7, height: 7, decoration: BoxDecoration(
          shape: BoxShape.circle, border: Border.all(color: color, width: 1.6))),
      Positioned(top: 3, right: 3, child: Container(width: 2, height: 2,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
    ]),
  );
}

/// Header for the Ad rewards card. Uses rewards_ad_gift.png when it is in
/// assets/images/, otherwise the gift-and-coins illustration.
Widget _adRewardsHeader(_RewardTheme t) => Row(children: [
  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Watch ads.\nEarn bonus.', style: TextStyle(color: t.ink,
        fontSize: 18, fontWeight: FontWeight.w700, height: 1.25)),
    const SizedBox(height: 8),
    Text('New ad rewards every day. Bonus is valid for 7 days.',
        style: TextStyle(color: t.sub, fontSize: 13)),
  ])),
  Image.asset('assets/images/rewards_ad_gift.png', width: 96, height: 96, fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset('assets/images/rewards_gift_coins.png',
          width: 96, height: 80, fit: BoxFit.contain)),
]);

/// One ad task: coin, "+N Bonus", progress, and Go / Done.
Widget _adTaskTile(RewardsController ctrl, Map<String, dynamic> task, _RewardTheme t) {
  final watched  = (task['ads_watched'] as num? ?? 0).toInt();
  final required = (task['ads_required'] as num? ?? 1).toInt();
  final reward   = (task['reward_coins'] as num? ?? 0).toInt();
  final done     = task['completed'] == true;
  return Row(children: [
    Container(width: 34, height: 34,
        decoration: BoxDecoration(shape: BoxShape.circle, color: t.cream),
        child: Icon(LucideIcons.sparkle, color: t.gold, size: 17)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('+$reward Bonus', style: TextStyle(color: t.ink, fontSize: 15.5, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text('${task['title'] ?? 'Watch ads, earn rewards'} ($watched/$required)',
          style: TextStyle(color: t.sub, fontSize: 12.5)),
    ])),
    Obx(() {
      final busy = ctrl.isWatchingAdTask.value;
      final (bg, fg, label) = done
          ? (t.tile, t.sub, 'Done')
          : (t.cream, t.goldText, busy ? '…' : 'Go');
      return GestureDetector(
        onTap: done || busy ? null : () { if (_requireAccount()) ctrl.watchAdTask(task); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
          child: Text(label, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      );
    }),
  ]);
}

/// "See more": every ad task, same tiles as on the rewards screen.
class AdRewardsScreen extends StatelessWidget {
  const AdRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<RewardsController>();
    final t    = _RewardTheme(Theme.of(context).brightness == Brightness.dark);
    return Scaffold(
      backgroundColor: t.page,
      appBar: AppBar(
        backgroundColor: t.hero,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.chevronLeft, color: t.ink, size: 24),
            onPressed: () => Get.back()),
        title: Text('Ad rewards', style: TextStyle(color: t.ink, fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: t.gold,
        onRefresh: ctrl.loadAdTasks,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              _adRewardsHeader(t),
              Obx(() => Column(children: [
                for (final e in ctrl.adTasks) ...[
                  Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: t.line, height: 1)),
                  _adTaskTile(ctrl, Map<String, dynamic>.from(e as Map), t),
                ],
              ])),
            ]),
          ),
          const SizedBox(height: 14),
          Text('Ad rewards reset every day. Bonus coins are valid for 7 days and are spent before your purchased coins.',
              textAlign: TextAlign.center, style: TextStyle(color: t.sub, fontSize: 12, height: 1.5)),
        ]),
      ),
    );
  }
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
