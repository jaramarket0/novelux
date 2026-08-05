import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/app_alerts.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/screen/auth/auth_controller.dart';

/// Shown once, right after login, to any account with no date_of_birth on
/// file yet — legacy accounts from before age assurance shipped, and every
/// Google/Apple sign-in (those providers never give us a birthdate).
/// Blocking: can't be dismissed or backed out of until a valid DOB is saved.
class DobGateScreen extends StatefulWidget {
  const DobGateScreen({super.key});

  @override
  State<DobGateScreen> createState() => _DobGateScreenState();
}

class _DobGateScreenState extends State<DobGateScreen> {
  DateTime? _dob;
  bool _loading = false;
  String? _error;

  String get _nextRoute {
    final args = Get.arguments;
    return args is String && args.isNotEmpty ? args : '/main_screen';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    final dob = _dob;
    if (dob == null) {
      setState(() => _error = 'Please select your date of birth.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.setDateOfBirth(dob);
    if (res['success'] == true) {
      final auth = Get.find<AuthController>();
      // Reflect locally so routePostAuth() never loops back here.
      final user = Map<String, dynamic>.from(auth.currentUser.value ?? {});
      user['date_of_birth'] =
          '${dob.year.toString().padLeft(4, '0')}-'
          '${dob.month.toString().padLeft(2, '0')}-'
          '${dob.day.toString().padLeft(2, '0')}';
      auth.currentUser.value = user;
      Get.offAllNamed(_nextRoute);
    } else {
      setState(() {
        _loading = false;
        _error = res['error']?.toString() ?? 'Could not save your date of birth.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cake_outlined, color: depperBlue, size: 40),
                const SizedBox(height: 20),
                const Text(
                  'Confirm your birthday',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We use this once to show age-appropriate content on your account. '
                  'It can\'t be changed afterwards.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _loading ? null : _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2a2a2a),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: Colors.grey[500], size: 18),
                        const SizedBox(width: 12),
                        Text(
                          _dob == null
                              ? 'Select your date of birth'
                              : '${_dob!.day.toString().padLeft(2, '0')}/'
                                  '${_dob!.month.toString().padLeft(2, '0')}/'
                                  '${_dob!.year}',
                          style: TextStyle(
                            color: _dob == null ? Colors.grey[500] : Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: depperBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed:
                        _loading
                            ? null
                            : () {
                              Get.find<AuthController>().logout();
                              AppAlert.info('Signed out.');
                            },
                    child: Text(
                      'Sign out instead',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
