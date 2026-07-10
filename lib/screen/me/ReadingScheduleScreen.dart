

import 'dart:developer' as myLog;
import 'dart:io';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/reward_screen/reward_screen.dart';
//import 'package:novelux/screen/rewards/rewards_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ── Notification service (singleton) ─────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
  if (_initialized) return;
  tz.initializeTimeZones();

  // ✅ Use .identifier — this is the IANA timezone string (e.g. "Africa/Lagos")
  final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
  final String timeZoneName = timeZoneInfo.identifier;

  tz.setLocalLocation(tz.getLocation(timeZoneName));

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await _plugin.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: _onNotificationTap,
  );
  _initialized = true;
}

  void _onNotificationTap(NotificationResponse response) {
    // Navigate to reading screen on tap
    Get.toNamed('/main_screen');
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> days, // 1=Mon … 7=Sun
  }) async {
    await cancelAll();
    for (final day in days) {
      final scheduled = _nextWeekday(day, hour, minute);
      await _plugin.zonedSchedule(
        id: id + day,
        title: title,
        body: body,
        scheduledDate: scheduled, // Ensure this is a TZDateTime
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'reading_schedule',
            'Reading Schedule',
            channelDescription: 'Daily reading reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFC15F3C),
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // This line below is what was causing the error - it is no longer needed
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> scheduleGoalReminder({
    required int goalMinutes,
    required int hour,
    required int minute,
  }) async {
    // Evening reminder if goal not met
    final reminderHour = hour > 1 ? hour - 1 : 20;
    final scheduled = _nextWeekday(
      DateTime.now().weekday,
      reminderHour,
      minute,
    );
    await _plugin.zonedSchedule(
      id: 999,
      title: '📚 Reading goal reminder',
      body: 'You still need to read $goalMinutes mins today. Start now!',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_goal',
          'Reading Goal',
          channelDescription: 'Reading goal reminders',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation:
      //     UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    var now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // Advance to correct weekday
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

// ── Reading Schedule Controller ───────────────────────────────────────────────
class ReadingScheduleController extends GetxController {
  // Schedule settings
  final RxBool scheduleEnabled = false.obs;
  final Rx<TimeOfDay> readingTime = const TimeOfDay(hour: 21, minute: 0).obs;
  final RxList<bool> selectedDays =
      [true, true, true, true, true, true, true].obs; // Mon–Sun
  final RxInt goalMinutes = 30.obs;
  final RxBool goalReminderEnabled = false.obs;

  // Today's reading stats
  final RxInt todayMinutes = 0.obs;
  final RxInt currentStreak = 0.obs;
  final RxBool goalMetToday = false.obs;

  // Reading sessions history (last 7 days)
  final RxList weekHistory = [].obs; // List<Map {date, minutes}>

  final _notif = NotificationService();
  final _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void onInit() {
    super.onInit();
    _notif.init();
    _load();
    print('checking for permission');
    myLog.log('checking for permission');
    checkAlarmPermission();
  }

  Future<void> checkAlarmPermission() async {
    if (Platform.isAndroid) {
      // Check if we already have it
      myLog.log('Checking scheduleExactAlarm permission...');
      var status = await Permission.scheduleExactAlarm.status;
      myLog.log(status.toString());
      if (status.isDenied || status.isPermanentlyDenied) {
        // Show a dialog explaining WHY Novelux needs this
        // (Google requires you to explain this to the user first)
        Get.defaultDialog(
          title: "Exact Reminders",
          middleText:
              "To remind you exactly when to read, Novelux needs 'Alarm & Reminders' permission.",
          textConfirm: "Allow",
          onConfirm: () async {
            Get.back();
            // This opens the specific system page for "Alarms & Reminders"
            await Permission.scheduleExactAlarm.request();
          },
        );
      }
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    scheduleEnabled.value = prefs.getBool('sched_enabled') ?? false;
    goalMinutes.value = prefs.getInt('sched_goal_mins') ?? 30;
    goalReminderEnabled.value = prefs.getBool('sched_goal_reminder') ?? false;
    currentStreak.value = prefs.getInt('reading_streak') ?? 0;

    final h = prefs.getInt('sched_hour') ?? 21;
    final m = prefs.getInt('sched_minute') ?? 0;
    readingTime.value = TimeOfDay(hour: h, minute: m);

    final daysJson = prefs.getString('sched_days');
    if (daysJson != null) {
      final list = List<bool>.from(jsonDecode(daysJson));
      selectedDays.value = list;
    }

    // Today's minutes (from rewards screen reading tracker)
    todayMinutes.value = prefs.getInt('reading_mins') ?? 0;
    goalMetToday.value = todayMinutes.value >= goalMinutes.value;

    // Build week history
    final history = <Map>[];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final mins =
          prefs.getInt('reading_mins_$key') ??
          (key == today ? todayMinutes.value : 0);
      history.add({
        'date': key,
        'minutes': mins,
        'dayLabel': _dayNames[d.weekday - 1],
      });
    }
    weekHistory.value = history;
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> toggleSchedule(bool value) async {
    scheduleEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sched_enabled', value);

    if (value) {
      await _applySchedule();
      AppAlert.info('📚 Schedule Set! — You\'ll be reminded to read at ${_formatTime(readingTime.value)}');
    } else {
      await _notif.cancelAll();
      AppAlert.info('Schedule Disabled — Reading reminders turned off');
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: readingTime.value,
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: const Color(0xFF1e1e22),
                hourMinuteTextColor: Colors.white,
                dialHandColor: depperBlue,
                dialBackgroundColor: const Color(0xFF2a2a2a),
                entryModeIconColor: Colors.grey,
              ),
              colorScheme: ColorScheme.dark(
                primary: depperBlue,
                onPrimary: Colors.white,
                surface: const Color(0xFF1e1e22),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) {
      readingTime.value = picked;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sched_hour', picked.hour);
      await prefs.setInt('sched_minute', picked.minute);
      if (scheduleEnabled.value) {
        await _applySchedule();
      }
    }
  }

  void toggleDay(int index) async {
    final updated = List<bool>.from(selectedDays);
    // Keep at least one day selected
    final willHaveNone = updated.where((d) => d).length == 1 && updated[index];
    if (willHaveNone) {
      AppAlert.warning('Select at least one day');
      return;
    }
    updated[index] = !updated[index];
    selectedDays.value = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sched_days', jsonEncode(updated));
    if (scheduleEnabled.value) {
      await _applySchedule();
    }
  }

  Future<void> setGoal(int mins) async {
    goalMinutes.value = mins;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sched_goal_mins', mins);
    goalMetToday.value = todayMinutes.value >= mins;
  }

  Future<void> toggleGoalReminder(bool value) async {
    goalReminderEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sched_goal_reminder', value);
    if (value && scheduleEnabled.value) {
      await _applySchedule();
    }
  }

  Future<void> _applySchedule() async {
    final activeDays = <int>[];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        activeDays.add(i + 1);
      } // 1=Mon
    }

    await _notif.scheduleDaily(
      id: 100,
      title: '📚 Time to read!',
      body: 'Your daily reading session is ready. Keep the streak going! 🔥',
      hour: readingTime.value.hour,
      minute: readingTime.value.minute,
      days: activeDays,
    );

    if (goalReminderEnabled.value) {
      await _notif.scheduleGoalReminder(
        goalMinutes: goalMinutes.value,
        hour: readingTime.value.hour,
        minute: readingTime.value.minute,
      );
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get formattedTime => _formatTime(readingTime.value);

  double get goalProgress =>
      goalMinutes.value == 0
          ? 0.0
          : (todayMinutes.value / goalMinutes.value).clamp(0.0, 1.0);

  String get goalProgressText =>
      '${todayMinutes.value} / ${goalMinutes.value} min';

  // Called from reading interface to track time
  Future<void> addReadingMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final current = prefs.getInt('reading_mins_$today') ?? 0;
    final updated = current + minutes;
    await prefs.setInt('reading_mins_$today', updated);
    await prefs.setInt('reading_mins', updated); // for rewards screen
    todayMinutes.value = updated;
    goalMetToday.value = updated >= goalMinutes.value;

    // Always keep RewardsController in sync so reading challenge updates live
    if (Get.isRegistered<RewardsController>()) {
      Get.find<RewardsController>().readingMinutesToday.value = updated;
    }

    // Update streak only the moment the goal is first met today
    if (goalMetToday.value && current < goalMinutes.value) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final yMins = prefs.getInt('reading_mins_$yKey') ?? 0;
      if (yMins >= goalMinutes.value) {
        currentStreak.value++;
      } else {
        currentStreak.value = 1;
      }
      await prefs.setInt('reading_streak', currentStreak.value);
      AppAlert.success('🎉 Goal Met! — You\'ve read ${goalMinutes.value} minutes today! Streak: ${currentStreak.value} days 🔥');
    }

    _load(); // refresh week history
  }

  List<String> get selectedDayNames {
    final names = <String>[];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        names.add(_dayNames[i]);
      }
    }
    return names;
  }
}

// ── Reading Schedule Screen ───────────────────────────────────────────────────
class ReadingScheduleScreen extends StatefulWidget {
  const ReadingScheduleScreen({super.key});

  @override
  State<ReadingScheduleScreen> createState() => _ReadingScheduleScreenState();
}

class _ReadingScheduleScreenState extends State<ReadingScheduleScreen> {
  Future<void> checkAlarmPermission() async {
    if (Platform.isAndroid) {
      // Check if we already have it
      print('Checking scheduleExactAlarm permission...');
      var status = await Permission.scheduleExactAlarm.status;

      if (status.isDenied || status.isPermanentlyDenied) {
        // Show a dialog explaining WHY Novelux needs this
        // (Google requires you to explain this to the user first)
        Get.defaultDialog(
          title: "Exact Reminders",
          middleText:
              "To remind you exactly when to read, Novelux needs 'Alarm & Reminders' permission.",
          textConfirm: "Allow",
          onConfirm: () async {
            Get.back();
            // This opens the specific system page for "Alarms & Reminders"
            await Permission.scheduleExactAlarm.request();
          },
        );
      }
    }
  }

  @override
  void
initState() {
    super.initState();
    print('checking for permission');

    checkAlarmPermission();
  }


  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ReadingScheduleController());
    final auth = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0d0d0f) : const Color(0xFFF2F2F7);
    final card = isDark ? const Color(0xFF1e1e22) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final sub = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: txt, size: 28),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Reading Schedule',
          style: TextStyle(
            color: txt,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temporary test button
// ElevatedButton(
//   onPressed: () async {
//     final plugin = FlutterLocalNotificationsPlugin(

//     );
//     await plugin.zonedSchedule(
//       id: 0,
//       title: 'Test',
//       body: 'Notifications are working!',
//       scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails('test', 'Test',
//         importance: Importance.max,
//         priority: Priority.max,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.alarmClock,
//     );
//     print('Test notification scheduled for 10 seconds');
//   },
//   child: const Text('Test Notification'),
// ),

            // ── Today's goal card ──────────────────────────────────────────
            Obx(
              () => _card(
                card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Today\'s Goal',
                          style: TextStyle(
                            color: txt,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (ctrl.goalMetToday.value)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Achieved!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Big progress circle
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 130,
                            height: 130,
                            child: CircularProgressIndicator(
                              value: ctrl.goalProgress,
                              strokeWidth: 10,
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF2a2a2a)
                                      : const Color(0xFFE0E0E0),
                              color:
                                  ctrl.goalMetToday.value
                                      ? Colors.green
                                      : depperBlue,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${ctrl.todayMinutes.value}',
                                style: TextStyle(
                                  color: txt,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '/ ${ctrl.goalMinutes.value} min',
                                style: TextStyle(color: sub, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Streak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${ctrl.currentStreak.value} day streak',
                          style: TextStyle(
                            color: txt,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Week history ────────────────────────────────────────────────
            _card(
              card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: TextStyle(
                      color: txt,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final max = ctrl.weekHistory.fold<int>(
                      1,
                      (m, d) =>
                          (d['minutes'] as int) > m ? d['minutes'] as int : m,
                    );
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children:
                          ctrl.weekHistory.map((day) {
                            final mins = day['minutes'] as int;
                            final met = mins >= ctrl.goalMinutes.value;
                            final barH =
                                max == 0
                                    ? 4.0
                                    : ((mins / max) * 80).clamp(4.0, 80.0);
                            final isToday = day['date'] == ctrl._todayKey();
                            return Column(
                              children: [
                                Text(
                                  '${mins}m',
                                  style: TextStyle(color: sub, fontSize: 9),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 28,
                                  height: barH,
                                  decoration: BoxDecoration(
                                    color:
                                        met
                                            ? Colors.green
                                            : isToday
                                            ? depperBlue
                                            : (isDark
                                                ? const Color(0xFF2a2a2a)
                                                : const Color(0xFFE0E0E0)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  day['dayLabel'] as String,
                                  style: TextStyle(
                                    color: isToday ? depperBlue : sub,
                                    fontSize: 10,
                                    fontWeight:
                                        isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    );
                  }),
                  const SizedBox(height: 12),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend(Colors.green, 'Goal met'),
                      const SizedBox(width: 16),
                      _legend(depperBlue, 'Today'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Schedule toggle ─────────────────────────────────────────────
            _card(
              card,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: depperBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.alarm, color: depperBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Reminder',
                              style: TextStyle(
                                color: txt,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Get notified when it\'s time to read',
                              style: TextStyle(color: sub, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => Switch(
                          value: ctrl.scheduleEnabled.value,
                          onChanged: ctrl.toggleSchedule,
                          activeColor: depperBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Time picker ─────────────────────────────────────────────────
            Obx(
              () => AnimatedOpacity(
                opacity: ctrl.scheduleEnabled.value ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: _card(
                  card,
                  child: Column(
                    children: [
                      // Time
                      InkWell(
                        onTap:
                            ctrl.scheduleEnabled.value
                                ? () => ctrl.pickTime(context)
                                : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.access_time,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Reading Time',
                                style: TextStyle(
                                  color: txt,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Obx(
                                () => Text(
                                  ctrl.formattedTime,
                                  style: TextStyle(
                                    color: depperBlue,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: sub, size: 18),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color:
                            isDark
                                ? const Color(0xFF2a2a2a)
                                : Colors.grey[200]!,
                      ),

                      // Days
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Days',
                            style: TextStyle(
                              color: txt,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (i) {
                            final sel = ctrl.selectedDays[i];
                            return GestureDetector(
                              onTap:
                                  ctrl.scheduleEnabled.value
                                      ? () => ctrl.toggleDay(i)
                                      : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color:
                                      sel
                                          ? depperBlue
                                          : isDark
                                          ? const Color(0xFF2a2a2a)
                                          : const Color(0xFFF0F0F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                    style: TextStyle(
                                      color: sel ? Colors.white : sub,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Daily reading goal ──────────────────────────────────────────
            _card(
              card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.flag_outlined,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Daily Reading Goal',
                        style: TextStyle(
                          color: txt,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Goal options
                  Obx(
                    () => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          [5, 10, 15, 20, 30, 45, 60, 90, 120].map((mins) {
                            final sel = ctrl.goalMinutes.value == mins;
                            return GestureDetector(
                              onTap: () => ctrl.setGoal(mins),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      sel
                                          ? depperBlue
                                          : isDark
                                          ? const Color(0xFF2a2a2a)
                                          : const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$mins min',
                                  style: TextStyle(
                                    color: sel ? Colors.white : sub,
                                    fontWeight:
                                        sel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Goal reminder toggle
                  Row(
                    children: [
                      Icon(Icons.notifications_outlined, color: sub, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Remind me if goal not met',
                          style: TextStyle(color: txt, fontSize: 13),
                        ),
                      ),
                      Obx(
                        () => Switch(
                          value: ctrl.goalReminderEnabled.value,
                          onChanged: ctrl.toggleGoalReminder,
                          activeColor: depperBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Tips card ───────────────────────────────────────────────────
            _card(
              card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading Tips',
                    style: TextStyle(
                      color: txt,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    [
                      '🌙',
                      'Best time to read',
                      'Evening reading improves retention by 23%',
                    ],
                    [
                      '🔥',
                      'Build a streak',
                      'Reading 7 days in a row earns 130 bonus coins',
                    ],
                    [
                      '⏱',
                      'Start small',
                      'Even 5 minutes a day keeps your streak alive',
                    ],
                    [
                      '🎧',
                      'Try audiobooks',
                      'Listen while commuting to hit your daily goal faster',
                    ],
                  ].map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip[0], style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tip[1],
                                  style: TextStyle(
                                    color: txt,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tip[2],
                                  style: TextStyle(
                                    color: sub,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _card(Color bg, {required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _legend(Color color, String label) => Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ],
  );
}
