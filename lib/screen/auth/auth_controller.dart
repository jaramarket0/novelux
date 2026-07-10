import 'dart:convert';
import 'dart:developer' as myLog;
import 'package:novelux/config/app_alerts.dart';
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:novelux/config/api_service.dart';
// // import 'package:novelux/config/local_storage.dart';

// // class AuthController extends GetxController {
// //   static AuthController get instance => Get.find();

// //   final DataBase _db = Get.find<DataBase>();

// //   final RxBool isLoading = false.obs;
// //   final RxBool isLoggedIn = false.obs;
// //   final RxString errorMessage = ''.obs;
// //   final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);

// //   // Form controllers
// //   final emailCtrl    = TextEditingController();
// //   final passwordCtrl = TextEditingController();
// //   final usernameCtrl = TextEditingController();
// //   final password2Ctrl= TextEditingController();

// //   @override
// //   void onInit() {
// //     super.onInit();
// //     _checkLoginStatus();
// //   }

// //   Future<void> _checkLoginStatus() async {
// //     final token = await _db.getToken();
// //     if (token.isNotEmpty) {
// //       isLoggedIn.value = true;
// //       await fetchMe();
// //     }
// //   }

// //   Future<void> login() async {
// //     if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
// //       errorMessage.value = 'Please fill in all fields';
// //       return;
// //     }
// //     isLoading.value = true;
// //     errorMessage.value = '';
// //     final res = await ApiService.login(
// //       email: emailCtrl.text.trim(),
// //       password: passwordCtrl.text,
// //     );
// //     isLoading.value = false;
// //     if (res['success']) {
// //       final data = res['data'];
// //       await _db.saveToken(data['access'] ?? '');
// //       // Save refresh token separately
// //       await _saveRefreshToken(data['refresh'] ?? '');
// //       isLoggedIn.value = true;
// //       await fetchMe();
// //       Get.offAllNamed('/main_screen');
// //     } else {
// //       errorMessage.value = res['error'] ?? 'Login failed';
// //     }
// //   }

// //   Future<void> register({String role = 'reader'}) async {
// //     if (usernameCtrl.text.isEmpty ||
// //         emailCtrl.text.isEmpty ||
// //         passwordCtrl.text.isEmpty ||
// //         password2Ctrl.text.isEmpty) {
// //       errorMessage.value = 'Please fill in all fields';
// //       return;
// //     }
// //     if (passwordCtrl.text != password2Ctrl.text) {
// //       errorMessage.value = 'Passwords do not match';
// //       return;
// //     }
// //     isLoading.value = true;
// //     errorMessage.value = '';
// //     final res = await ApiService.register(
// //       username: usernameCtrl.text.trim(),
// //       email: emailCtrl.text.trim(),
// //       password1: passwordCtrl.text,
// //       password2: password2Ctrl.text,
// //       role: role,
// //     );
// //     isLoading.value = false;
// //     if (res['success']) {
// //       final data = res['data'];
// //       if (data['access'] != null) {
// //         await _db.saveToken(data['access']);
// //         await _saveRefreshToken(data['refresh'] ?? '');
// //         isLoggedIn.value = true;
// //         await fetchMe();
// //         Get.offAllNamed('/main_screen');
// //       } else {
// //         // Registration succeeded but no token — redirect to login
// //         Get.offNamed('/login_screen');
// //         Get.snackbar('Success', 'Account created! Please log in.',
// //             backgroundColor: Colors.green, colorText: Colors.white);
// //       }
// //     } else {
// //       errorMessage.value = res['error'] ?? 'Registration failed';
// //     }
// //   }

// //   Future<void> fetchMe() async {
// //     final res = await ApiService.getMe();
// //     if (res['success']) {
// //       currentUser.value = res['data'];
// //       // Save key user info
// //       final data = res['data'];
// //       await _db.saveUserName(data['username'] ?? '');
// //       await _db.saveEmail(data['email'] ?? '');
// //       await _db.saveRole(data['role'] ?? 'reader');
// //     }
// //   }

// //   Future<void> logout() async {
// //     await _db.logOut();
// //     isLoggedIn.value = false;
// //     currentUser.value = null;
// //     Get.offAllNamed('/onboarding_screen');
// //   }

// //   Future<void> _saveRefreshToken(String refresh) async {
// //     // Reuse profileId field as temp refresh token storage
// //     await _db.saveProfileId(refresh);
// //   }

// //   Future<String> _getRefreshToken() async {
// //     return await _db.getProfileId();
// //   }

// //   // Getters for current user data
// //   String get username => currentUser.value?['username'] ?? '';
// //   String get email    => currentUser.value?['email'] ?? '';
// //   String get role     => currentUser.value?['role'] ?? 'reader';
// //   int    get coins    => currentUser.value?['coin_balance'] ?? 0;
// //   bool   get isVip    => currentUser.value?['is_vip'] ?? false;
// //   bool   get isAuthor => role == 'author';
// //   String? get avatar  => currentUser.value?['avatar'];
// //   int    get readingLevel => currentUser.value?['reading_level'] ?? 1;
// // }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:novelux/config/api_service.dart';
// import 'package:novelux/config/local_storage.dart';

// class AuthController extends GetxController {
//   static AuthController get instance => Get.find();

//   final DataBase _db = Get.find<DataBase>();

//   final RxBool isLoading = false.obs;
//   final RxBool isLoggedIn = false.obs;
//   final RxString errorMessage = ''.obs;
//   final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);

//   // Form controllers
//   final emailCtrl    = TextEditingController();
//   final passwordCtrl = TextEditingController();
//   final usernameCtrl = TextEditingController();
//   final password2Ctrl= TextEditingController();

//   @override
//   void onInit() {
//     super.onInit();
//     _checkLoginStatus();
//   }

//   Future<void> _checkLoginStatus() async {
//     final token = await _db.getToken();
//     if (token.isNotEmpty) {
//       isLoggedIn.value = true;
//       await fetchMe();
//     }
//   }

//   Future<void> login() async {
//     if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
//       errorMessage.value = 'Please fill in all fields';
//       return;
//     }
//     isLoading.value = true;
//     errorMessage.value = '';
//     final res = await ApiService.login(
//       email: emailCtrl.text.trim(),
//       password: passwordCtrl.text,
//     );
//     isLoading.value = false;
//     if (res['success']) {
//       final data = res['data'];
//       await _db.saveToken(data['access'] ?? '');
//       // Save refresh token separately
//       await _saveRefreshToken(data['refresh'] ?? '');
//       isLoggedIn.value = true;
//       await fetchMe();
//       Get.offAllNamed('/main_screen');
//     } else {
//       errorMessage.value = res['error'] ?? 'Login failed';
//     }
//   }

//   Future<void> register({String role = 'reader'}) async {
//     if (usernameCtrl.text.isEmpty ||
//         emailCtrl.text.isEmpty ||
//         passwordCtrl.text.isEmpty ||
//         password2Ctrl.text.isEmpty) {
//       errorMessage.value = 'Please fill in all fields';
//       return;
//     }
//     if (passwordCtrl.text != password2Ctrl.text) {
//       errorMessage.value = 'Passwords do not match';
//       return;
//     }
//     isLoading.value = true;
//     errorMessage.value = '';
//     final res = await ApiService.register(
//       username: usernameCtrl.text.trim(),
//       email: emailCtrl.text.trim(),
//       password1: passwordCtrl.text,
//       password2: password2Ctrl.text,
//       role: role,
//     );
//     isLoading.value = false;
//     if (res['success']) {
//       final data = res['data'];
//       if (data['access'] != null) {
//         await _db.saveToken(data['access']);
//         await _saveRefreshToken(data['refresh'] ?? '');
//         isLoggedIn.value = true;
//         await fetchMe();
//         // Go to preferences screen to pick categories
//         Get.offAllNamed('/preferences_screen');
//       } else {
//         // Registration succeeded but no token — redirect to login
//         Get.offNamed('/login_screen');
//         Get.snackbar('Success', 'Account created! Please log in.',
//             backgroundColor: Colors.green, colorText: Colors.white);
//       }
//     } else {
//       errorMessage.value = res['error'] ?? 'Registration failed';
//     }
//   }

//   Future<void> fetchMe() async {
//     final res = await ApiService.getMe();
//     if (res['success']) {
//       currentUser.value = res['data'];
//       // Save key user info
//       final data = res['data'];
//       await _db.saveUserName(data['username'] ?? '');
//       await _db.saveEmail(data['email'] ?? '');
//       await _db.saveRole(data['role'] ?? 'reader');
//     }
//   }

//   Future<void> logout() async {
//     await _db.logOut();
//     isLoggedIn.value = false;
//     currentUser.value = null;
//     Get.offAllNamed('/onboarding_screen');
//   }

//   Future<void> _saveRefreshToken(String refresh) async {
//     // Reuse profileId field as temp refresh token storage
//     await _db.saveProfileId(refresh);
//   }

//   Future<String> _getRefreshToken() async {
//     return await _db.getProfileId();
//   }

//   // Getters for current user data
//   String get username => currentUser.value?['username'] ?? '';
//   String get email    => currentUser.value?['email'] ?? '';
//   String get role     => currentUser.value?['role'] ?? 'reader';
//   int    get coins    => currentUser.value?['coin_balance'] ?? 0;
//   bool   get isVip    => currentUser.value?['is_vip'] ?? false;
//   bool   get isAuthor => role == 'author';
//   String? get avatar  => currentUser.value?['avatar'];
//   int    get readingLevel => currentUser.value?['reading_level'] ?? 1;
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/iap_service.dart';
import 'package:novelux/config/local_storage.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final DataBase _db = Get.find<DataBase>();

  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);

  // Form controllers
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  /// Returns {'device_id': '...', 'platform': 'android'|'ios'}
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return {'device_id': android.id, 'platform': 'android'};
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return {'device_id': ios.identifierForVendor ?? '', 'platform': 'ios'};
      }
    } catch (_) {}
    return {'device_id': '', 'platform': ''};
  }
  final usernameCtrl = TextEditingController();
  final password2Ctrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
    initGoogleSignIn();
  }

  Future<void> initGoogleSignIn() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '302060725266-8lm05k7jgm0dlbl1p2ht5hkfifdg1cq8.apps.googleusercontent.com',
    );
    _googleSignInInitialized = true;
  }

  Future<void> _checkLoginStatus() async {
    final token = await _db.getToken();
    if (token.isNotEmpty) {
      isLoggedIn.value = true;
      await fetchMe();
    }
  }

  Future<void> login() async {
    if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      errorMessage.value = 'Please fill in all fields';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    final deviceInfo = await _getDeviceInfo();
    final res = await ApiService.login(
      email: emailCtrl.text.trim(),
      password: passwordCtrl.text,
      deviceId: deviceInfo['device_id'],
      platform: deviceInfo['platform'],
    );
    isLoading.value = false;
    if (res['success']) {
      final data = res['data'];
      await _db.saveToken(data['access'] ?? '');
      // Save refresh token separately
      await _saveRefreshToken(data['refresh'] ?? '');
      isLoggedIn.value = true;
      TextInput.finishAutofillContext();
      await fetchMe();
      Get.offAllNamed('/main_screen');
    } else {
      errorMessage.value = res['error'] ?? 'Login failed';
    }
  }

  Future<void> register({String role = 'reader'}) async {
    if (usernameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        password2Ctrl.text.isEmpty) {
      errorMessage.value = 'Please fill in all fields';
      return;
    }
    if (passwordCtrl.text != password2Ctrl.text) {
      errorMessage.value = 'Passwords do not match';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    final deviceInfo = await _getDeviceInfo();
    final res = await ApiService.register(
      username: usernameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      password1: passwordCtrl.text,
      password2: password2Ctrl.text,
      role: role,
      deviceId: deviceInfo['device_id'],
      platform: deviceInfo['platform'],
    );
    isLoading.value = false;
    if (res['success']) {
      final data = res['data'];
      if (data['access'] != null) {
        await _db.saveToken(data['access']);
        await _saveRefreshToken(data['refresh'] ?? '');
        isLoggedIn.value = true;
        await fetchMe();
        // Go to preferences screen to pick categories
        Get.offAllNamed('/preferences_screen');
      } else {
        // Registration succeeded but no token — redirect to login
        Get.offNamed('/login_screen');
        AppAlert.success('Account created! Please log in.');
      }
    } else {
      errorMessage.value = res['error'] ?? 'Registration failed';
    }
  }

  Future<void> fetchMe() async {
    final res = await ApiService.getMe();
    if (res['success']) {
      currentUser.value = res['data'];
      // Save key user info
      final data = res['data'];
      await _db.saveUserName(data['username'] ?? '');
      await _db.saveEmail(data['email'] ?? '');
      await _db.saveRole(data['role'] ?? 'reader');
      // Tie RevenueCat purchases to this account so VIP restores across devices
      if (Get.isRegistered<IAPService>()) {
        final rcUserId = (data['id'] ?? data['username'])?.toString() ?? '';
        await IAPService.to.logIn(rcUserId);
      }
    }
  }

  /// Lightweight balance sync — call after any event that adds or removes
  /// coins (purchase, unlock, gift, reward, download…). Updates the reactive
  /// user map so every Obx showing auth.coins refreshes instantly.
  Future<void> refreshCoins() async {
    final res = await ApiService.getCoinBalance();
    final u = currentUser.value;
    if (res['success'] == true && u != null) {
      final data = res['data'];
      u['coin_balance'] =
          (data?['coin_balance'] as num?)?.toInt() ?? u['coin_balance'];
      u['is_vip'] = data?['is_vip'] ?? u['is_vip'];
      currentUser.refresh();
    }
  }

  Future<void> logout() async {
    if (Get.isRegistered<IAPService>()) {
      await IAPService.to.logOut();
    }
    await _db.logOut();
    isLoggedIn.value = false;
    currentUser.value = null;
    Get.offAllNamed('/onboarding_screen');
  }

  Future<void> _saveRefreshToken(String refresh) async {
    // Reuse profileId field as temp refresh token storage
    await _db.saveProfileId(refresh);
  }

  Future<String> _getRefreshToken() async {
    return await _db.getProfileId();
  }

  // Getters for current user data
  String get username => currentUser.value?['username'] ?? '';
  String get email => currentUser.value?['email'] ?? '';
  String get role => currentUser.value?['role'] ?? 'reader';
  int get coins => currentUser.value?['coin_balance'] ?? 0;
  bool get isVip => currentUser.value?['is_vip'] ?? false;
  String? get vipExpires    => currentUser.value?['vip_expires'] as String?;
  String? get adFreeExpires => currentUser.value?['ad_free_expires'] as String?;
  String? get audiobookExpires => currentUser.value?['audiobook_expires'] as String?;
  bool get isAuthor => role == 'author';
  String? get avatar => currentUser.value?['avatar'];
  int get readingLevel => currentUser.value?['reading_level'] ?? 1;
  // ── Google Sign-In ──────────────────────────────────────────────────────
  //final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;
  StreamSubscription? _authSubscription;

  // Future<void> loginWithGoogle() async {
  //   isLoading.value   = true;
  //   errorMessage.value = '';
  //   try {
  //     final account = await _googleSignIn.signIn();
  //     if (account == null) {
  //       // User cancelled
  //       isLoading.value = false;
  //       return;
  //     }
  //     final auth    = await account.authentication;
  //     final idToken = auth.idToken;
  //     if (idToken == null) {
  //       errorMessage.value = 'Google sign-in failed. Try again.';
  //       isLoading.value = false;
  //       return;
  //     }

  //     final res = await ApiService.googleSignIn(
  //       idToken:     idToken,
  //       email:       account.email,
  //       displayName: account.displayName,
  //       photoUrl:    account.photoUrl,
  //     );

  //     isLoading.value = false;

  //     if (res['success']) {
  //       final data = res['data'];
  //       // Save tokens — same flow as regular login
  //       await _db.saveToken(data['access']  ?? data['token'] ?? '');
  //       await _db.saveRefresh(data['refresh'] ?? '');
  //       await _db.saveUserName(data['username'] ?? account.displayName ?? '');
  //       await _db.saveEmail(data['email']    ?? account.email);
  //       isLoggedIn.value = true;
  //       await fetchMe();
  //       Get.offAllNamed('/main_screen');
  //     } else {
  //       errorMessage.value = res['error'] ?? 'Google sign-in failed.';
  //     }
  //   } catch (e) {
  //     isLoading.value    = false;
  //     errorMessage.value = 'Google sign-in error: \$e';
  //   }
  // }
  Future<void> loginWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await initGoogleSignIn();

      // Listen for the auth event (fires once on success)
      final completer = Completer<GoogleSignInAccount?>();

      final sub = GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          myLog.log(event.toString());
          if (!completer.isCompleted) completer.complete(event.user);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          myLog.log(event.toString());
          if (!completer.isCompleted) completer.complete(null);
        }
      }, onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      });

      try {
        myLog.log('[Google] calling authenticate()');
        await GoogleSignIn.instance.authenticate();
        myLog.log('[Google] authenticate() returned, waiting for account');
        final account = await completer.future;
        myLog.log('[Google] account: $account');

        if (account == null) {
          isLoading.value = false;
          myLog.log('[Google] account is null — user may have cancelled');
          return;
        }

        myLog.log('[Google] fetching idToken for ${account.email}');
        final GoogleSignInAuthentication auth = await account.authentication;
        final String? idToken = auth.idToken;
        myLog.log('[Google] idToken is ${idToken == null ? "NULL" : "present"}');

        if (idToken == null) {
          errorMessage.value = 'Google sign-in failed: no ID token. Check serverClientId.';
          isLoading.value = false;
          return;
        }

        final res = await ApiService.googleSignIn(
          idToken: idToken,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        );
        myLog.log('[Google] backend response: $res');
        isLoading.value = false;

        if (res['success']) {
          final data = res['data'];
          await _db.saveToken(data['access'] ?? data['token'] ?? '');
          await _db.saveRefresh(data['refresh'] ?? '');
          await _db.saveUserName(data['username'] ?? account.displayName ?? '');
          await _db.saveEmail(data['email'] ?? account.email);
          isLoggedIn.value = true;
          await fetchMe();
          if (data['code'] == 200) {
            Get.offAllNamed('/main_screen');
          } else {
            Get.offAllNamed('/preferences_screen');
          }
        } else {
          errorMessage.value = res['error'] ?? 'Google sign-in failed.';
        }
      } finally {
        await sub.cancel();
      }
    } catch (e) {
      isLoading.value = false;
      if (e is GoogleSignInException) {
        if (e.code != GoogleSignInExceptionCode.canceled) {
          errorMessage.value = 'Google sign-in error: ${e.description}';
        }
      } else {
        errorMessage.value = 'Google sign-in error: $e';
      }
    }
  }
}
