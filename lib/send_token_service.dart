import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';

import 'dart:developer' as myLog;

import 'package:novelux/config/api_service.dart';

class SendTokenService extends GetxService {
  // This class is intentionally left empty as the token refresh listener
  // has been moved to main.dart for better lifecycle management.
  ApiService apiClient = ApiService();

  ///devicetokens/register

  void registerToken(
    String token,
    String? deviceModel,
    String? appVersion,
  ) async {
    myLog.log('Registering token: $token');

    final deviceInfo = DeviceInfoPlugin();
    if (deviceModel == null || appVersion == null) {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceModel ??= androidInfo.model;
        appVersion ??= androidInfo.version.release;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceModel ??= iosInfo.utsname.machine;
        appVersion ??= iosInfo.systemVersion;
      }
    }
    var body = {
      "token": token,
      "platform": Platform.isAndroid ? "Android" : "iOS", // "iOS" or "Android"
      "device_model": deviceModel,
      "app_version": appVersion,
    };

    myLog.log('Request body: $body');

    var response = await apiClient.sendFcmToken(body);

    if (response.statusCode == 200) {
      myLog.log('Token registered successfully');
      var responseBody = jsonDecode(response.body);
      myLog.log('Response body: $responseBody');
      myLog.log('Message from server: ${responseBody['message']}');
    } else {
      myLog.log('Failed to register token: ${response.statusCode}');
    }

    // try {
    //   var response = await apiClient.postData('/register-token', {'token': token});
    //   if (response.statusCode == 200) {
    //     print('Token registered successfully');
    //   } else {
    //     print('Failed to register token: ${response.statusCode}');
    //   }
    // } catch (e) {
    //   print('Error registering token: $e');
    // }
  }
}
