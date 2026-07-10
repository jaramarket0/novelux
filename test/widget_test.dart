// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novelux/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}


///daniel@daniel-HP-EliteBook-8460p:~/Desktop/flutter apps/Novelux/NoveluX$ flutter run --release
// Launching lib/main.dart on TECNO BG6 in release mode...
// Running Gradle task 'assembleRelease'...                          436.4s
// ✓ Built build/app/outputs/flutter-apk/app-release.apk (59.6MB)
// Installing build/app/outputs/flutter-apk/app-release.apk...         5.4s

// Flutter run key commands.
// h List all available interactive commands.
// c Clear the screen
// q Quit (terminate the application on the device).

// I/flutter ( 3052): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
// I/flutter ( 3052): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
// E/flutter ( 3052): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(invalid_icon, The resource @drawable/ic_notification could not be found. Please make sure it has been added as a drawable resource to your Android head project., null, null)
// E/flutter ( 3052): #0      StandardMethodCodec.decodeEnvelope (package:flutter/src/services/message_codecs.dart:653)
// E/flutter ( 3052): #1      MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:367)
// E/flutter ( 3052): <asynchronous suspension>
// E/flutter ( 3052): #2      AndroidFlutterLocalNotificationsPlugin.initialize (package:flutter_local_notifications/src/platform_flutter_local_notifications.dart:167)
// E/flutter ( 3052): <asynchronous suspension>
// E/flutter ( 3052): #3      main (package:novelux/main.dart:202)
// E/flutter ( 3052): <asynchronous suspension>
// E/flutter ( 3052): 

// 9d604452ef662e2ed66805413575afff186eb023d3c05ab6c17430ae9d1.ttf: ClientException with SocketException: Failed host lookup: 'fonts.gstatic.com' (OS Error: No address associated with hostname, errno = 7), uri=https://fonts.gstatic.com/s/a/4711b9d604452ef662e2ed66805413575afff186eb023d3c05ab6c17430ae9d1.ttf
// E/flutter (27981): #0      _httpFetchFontAndSaveToDevice (package:google_fonts/src/google_fonts_base.dart:266)
// E/flutter (27981): <asynchronous suspension>
// E/flutter (27981): #1      loadFontIfNecessary (package:google_fonts/src/google_fonts_base.dart:173)
// E/flutter (27981): <asynchronous suspension>
// E/flutter (27981): #2      googleFontsTextStyle.<anonymous closure> (package:google_fonts/src/google_fonts_base.dart:110)
// E/flutter (27981): <asynchronous suspension>
// E/flutter (27981): 
// E/flutter (27981): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: GoogleSignInException(code GoogleSignInExceptionCode.canceled, activity is cancelled by the user., null)
// E/flutter (27981): 


// Variant: release
// Config: release
// Store: /home/daniel/Desktop/flutter apps/Novelux/NoveluX/android/novelux-upload-keystore.jks
// Alias: upload
// MD5: 9C:12:DE:1D:16:9C:C5:8B:F0:E6:E2:58:0B:DF:8C:0B
// SHA1: B7:15:E5:D8:30:33:BF:BA:74:90:AC:94:C1:6F:EA:87:6D:1E:81:2C
// SHA-256: 70:64:79:23:F9:DB:A6:7B:60:22:91:D2:4A:D4:68:36:F3:3A:BB:1D:39:D2:64:97:78:A8:DC:C3:2E:A8:B9:80
// Valid until: Saturday, October 25, 2053