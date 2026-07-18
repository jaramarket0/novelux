import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:novelux/config/ThemeController.dart';
import 'package:novelux/config/app_route_observer.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/language_controller.dart';
import 'package:novelux/config/translations.dart';
import 'package:novelux/config/ad_service.dart';
import 'package:novelux/config/iap_service.dart';
import 'package:novelux/config/local_storage.dart';
import 'package:novelux/config/logger.dart';
import 'package:novelux/config/routes.dart';
import 'package:novelux/firebase_options.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/send_token_service.dart';
import 'dart:developer' as myLog;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ─── Globals ────────────────────────────────────────────────────────────────

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

const MethodChannel platform = MethodChannel(
  'dexterx.dev/flutter_local_notifications_example',
);

String? selectedNotificationPayload;

const String urlLaunchActionId = 'id_1';
const String navigationActionId = 'id_3';
const String darwinNotificationCategoryText = 'textCategory';
const String darwinNotificationCategoryPlain = 'plainCategory';

// ─── Background notification tap handler (must be top-level) ────────────────

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  myLog.log('Notification tapped in background: ${notificationResponse.id}');
}

// ─── FCM background handler (must be top-level) ─────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  myLog.log('Handling a background message: ${message.messageId}');

  final FlutterLocalNotificationsPlugin bgPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await bgPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  if (message.notification != null) {
    final notification = message.notification!;
    final android = message.notification?.android;

    if (android != null) {
      await bgPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            ticker: 'ticker',
            icon: 'ic_notification',
          ),
        ),
      );
    }
  }
}

// ─── FCM foreground message handler ─────────────────────────────────────────

void _handleForegroundMessage(RemoteMessage message) {
  myLog.log('Received a foreground message!');
  myLog.log('Message data: ${message.data}');

  if (message.notification != null) {
    myLog.log('Notification: ${message.notification}');
    final notification = message.notification!;
    if (message.notification?.android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Used for important notifications.',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            ticker: 'ticker',
            icon: 'ic_notification',
          ),
        ),
      );
    }
  }
}

// ─── Local notifications init ────────────────────────────────────────────────

Future<void> _initLocalNotifications() async {
  final List<DarwinNotificationCategory> darwinNotificationCategories = [
    DarwinNotificationCategory(
      darwinNotificationCategoryText,
      actions: [
        DarwinNotificationAction.text(
          'text_1',
          'Action 1',
          buttonTitle: 'Send',
          placeholder: 'Placeholder',
        ),
      ],
    ),
    DarwinNotificationCategory(
      darwinNotificationCategoryPlain,
      actions: [
        DarwinNotificationAction.plain('id_1', 'Action 1'),
        DarwinNotificationAction.plain(
          'id_2',
          'Action 2 (destructive)',
          options: {DarwinNotificationActionOption.destructive},
        ),
        DarwinNotificationAction.plain(
          navigationActionId,
          'Action 3 (foreground)',
          options: {DarwinNotificationActionOption.foreground},
        ),
        DarwinNotificationAction.plain(
          'id_4',
          'Action 4 (auth required)',
          options: {DarwinNotificationActionOption.authenticationRequired},
        ),
      ],
      options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
    ),
  ];

  await flutterLocalNotificationsPlugin.initialize(
    settings: InitializationSettings(
      android: const AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: darwinNotificationCategories,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: darwinNotificationCategories,
      ),
      linux: LinuxInitializationSettings(
        defaultActionName: 'Open notification',
        defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
      ),
    ),
    onDidReceiveNotificationResponse: selectNotificationStream.add,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

// ─── FCM background setup (runs after runApp, never blocks UI) ───────────────

Future<void> _setupFcmInBackground(SendTokenService sendTokenService) async {
  try {
    final fcm = FirebaseMessaging.instance;

    // Android heads-up channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            description: 'Used for important notifications.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

    // Handle notification that launched the app from terminated state
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      myLog.log('App launched from notification: ${initialMessage.messageId}');
    }

    // Register message listeners
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (msg) => myLog.log('Message clicked!: $msg'),
    );
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      myLog.log('FCM Token refreshed: $newToken');
      sendTokenService.registerToken(newToken, null, null);
    });

    // Request permission — shows iOS dialog, then fetch token.
    // Both are network calls that can be slow; they must never block runApp().
    final settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      myLog.log('Notification permission: ${settings.authorizationStatus}');
      String? token;
      if (!kIsWeb && Platform.isIOS && await fcm.getAPNSToken() == null) {
        myLog.log(
          'APNS token is not set yet (expected on iOS Simulator or if remote notification registration is pending). Skipping initial FCM token fetch.',
        );
      } else {
        token = await fcm
            .getToken()
            .timeout(const Duration(seconds: 20), onTimeout: () => null);
      }
      if (token != null) {
        myLog.log('FCM Token: $token');
        sendTokenService.registerToken(token, null, null);
      }
    } else {
      myLog.log('Notification permission denied');
    }
  } catch (e) {
    myLog.log('FCM setup error: $e');
  }
}

// ─── main() ─────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  // Desktop SQLite
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Get.put(DataBase());

  // IAPService: timeout on isAvailable() prevents iOS StoreKit from blocking startup
  await Get.putAsync<IAPService>(() async {
    final svc = IAPService();
    await svc.onInit();
    return svc;
  });

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications plugin init (fast, in-process — needed before any show())
  await _initLocalNotifications();

  // Register controllers
  final sendTokenService = Get.put(SendTokenService());
  Get.put(AuthController());
  Get.put(ThemeController());
  Get.put(LanguageController());

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    Logger.init(kReleaseMode ? LogMode.live : LogMode.debug);
    runApp(const MyApp());
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // FCM permission + token and ads run in the background after runApp fires.
  // They must never await before runApp — they make network calls that can hang.
  unawaited(_setupFcmInBackground(sendTokenService));
  unawaited(AdService.instance.initialize());
}

// ─── App widget ──────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final langController = Get.find<LanguageController>();
    return Obx(
      () => GetMaterialApp(
        title: 'NoveluX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        translations: AppTranslations(),
        locale: langController.locale,
        fallbackLocale: const Locale('en', 'US'),
        getPages: AppRoutes.pages,
        initialRoute: AppRoutes.splashScreen,
        navigatorObservers: [appRouteObserver],
      ),
    );
  }
}
