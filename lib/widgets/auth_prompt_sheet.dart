import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/widgets/google_logo.dart';

/// Bottom sheet shown at the moment a guest touches something that genuinely
/// needs an account — never on entry to a screen.
///
/// Browsing, bookmarking, downloading and reading history all work signed out
/// and live on the device, so the only reasons to interrupt someone are the
/// ones listed in [AuthPromptReason]: things that move money, write to shared
/// state, or need the account to exist server-side.
enum AuthPromptReason {
  sync,
  comment,
  review,
  tip,
  subscribe,
  coins,
  rewards,
  follow,
  write,
  notifications,
}

extension _ReasonCopy on AuthPromptReason {
  String get message {
    switch (this) {
      case AuthPromptReason.sync:
        return 'Sign in to sync your novels and reading progress across your '
            'devices, and keep them if you change phone.';
      case AuthPromptReason.comment:
        return 'Sign in to post comments and join the conversation.';
      case AuthPromptReason.review:
        return 'Sign in to rate and review this story.';
      case AuthPromptReason.tip:
        return 'Sign in to send tips to authors you love.';
      case AuthPromptReason.subscribe:
        return 'Sign in to subscribe — your VIP benefits are tied to your '
            'account.';
      case AuthPromptReason.coins:
        return 'Sign in to buy and spend coins. Your balance is tied to your '
            'account.';
      case AuthPromptReason.rewards:
        return 'Sign in to earn and keep coins. Daily check-ins, reading '
            'rewards and your balance all live with your account.';
      case AuthPromptReason.follow:
        return 'Sign in to follow authors and hear about their new releases.';
      case AuthPromptReason.write:
        return 'Sign in to start writing and publish your own stories.';
      case AuthPromptReason.notifications:
        return 'Sign in to receive notifications about new chapters.';
    }
  }
}

/// Shows the sheet. Returns true when the user came back signed in, so the
/// caller can retry whatever the guest was trying to do:
///
/// ```dart
/// if (!auth.isLoggedIn.value) {
///   if (await promptSignIn(AuthPromptReason.tip) != true) return;
/// }
/// ```
Future<bool?> promptSignIn(AuthPromptReason reason) async {
  await Get.bottomSheet<void>(
    _AuthPromptSheet(reason: reason),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
  return Get.find<AuthController>().isLoggedIn.value;
}

class _AuthPromptSheet extends StatelessWidget {
  const _AuthPromptSheet({required this.reason});

  final AuthPromptReason reason;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final title = isDark ? Colors.white : const Color(0xFF111111);
    final body = isDark ? Colors.white70 : const Color(0xFF5F5F5F);
    final border = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6E6E6);
    final fill = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF6F6F6);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NoveluX',
              style: TextStyle(
                color: title,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              reason.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: body, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 22),
            _ProviderButton(
              label: 'Continue with Google',
              fill: fill,
              border: border,
              textColor: title,
              icon: const GoogleLogo(size: 20),
              onTap: () async {
                Get.back();
                await auth.loginWithGoogle();
              },
            ),
            if (Platform.isIOS || Platform.isMacOS) ...[
              const SizedBox(height: 10),
              _ProviderButton(
                label: 'Continue with Apple',
                fill: fill,
                border: border,
                textColor: title,
                icon: Icon(Icons.apple, color: title, size: 22),
                onTap: () async {
                  Get.back();
                  await auth.loginWithApple();
                },
              ),
            ],
            const SizedBox(height: 10),
            _ProviderButton(
              label: 'Sign in with email',
              fill: fill,
              border: border,
              textColor: title,
              icon: Icon(Icons.mail_outline, color: title, size: 21),
              onTap: () {
                Get.back();
                Get.toNamed('/login_screen');
              },
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: Get.back,
              child: Text(
                'Not now',
                style: TextStyle(color: body, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.fill,
    required this.border,
    required this.textColor,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final Color fill;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: fill,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 22, height: 22, child: Center(child: icon)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

