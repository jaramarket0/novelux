// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:novelux/config/app_style.dart';
// // import 'package:novelux/screen/auth/auth_controller.dart';

// // // ─── Login Screen ─────────────────────────────────────────────────────────────
// // class LoginScreen extends StatelessWidget {
// //   const LoginScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     final ctrl = Get.put(AuthController());
// //     final obscure = true.obs;

// //     return Scaffold(
// //       backgroundColor: background,
// //       body: SafeArea(
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.symmetric(horizontal: 24),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               const SizedBox(height: 48),
// //               Center(
// //                 child: Text(
// //                   'NoveluX',
// //                   style: TextStyle(
// //                     fontSize: 32,
// //                     fontWeight: FontWeight.bold,
// //                     color: depperBlue,
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               const Center(
// //                 child: Text(
// //                   'Read. Write. Earn.',
// //                   style: TextStyle(color: Colors.grey, fontSize: 14),
// //                 ),
// //               ),
// //               const SizedBox(height: 48),
// //               Text(
// //                 'Welcome back',
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 24,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               const Text(
// //                 'Sign in to continue reading',
// //                 style: TextStyle(color: Colors.grey, fontSize: 14),
// //               ),
// //               const SizedBox(height: 32),

// //               // Email
// //               _label('Email'),
// //               const SizedBox(height: 8),
// //               TextField(
// //                 controller: ctrl.emailCtrl,
// //                 keyboardType: TextInputType.emailAddress,
// //                 style: const TextStyle(color: Colors.white),
// //                 decoration: _inputDec('Enter your email', Icons.email_outlined),
// //               ),
// //               const SizedBox(height: 20),

// //               // Password
// //               _label('Password'),
// //               const SizedBox(height: 8),
// //               Obx(
// //                 () => TextField(
// //                   controller: ctrl.passwordCtrl,
// //                   obscureText: obscure.value,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: _inputDec(
// //                     'Enter your password',
// //                     Icons.lock_outline,
// //                   ).copyWith(
// //                     suffixIcon: IconButton(
// //                       icon: Icon(
// //                         obscure.value
// //                             ? Icons.visibility_off_outlined
// //                             : Icons.visibility_outlined,
// //                         color: Colors.grey,
// //                       ),
// //                       onPressed: () => obscure.value = !obscure.value,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 12),

// //               // Error message
// //               Obx(
// //                 () =>
// //                     ctrl.errorMessage.value.isNotEmpty
// //                         ? Padding(
// //                           padding: const EdgeInsets.only(bottom: 12),
// //                           child: Text(
// //                             ctrl.errorMessage.value,
// //                             style: const TextStyle(
// //                               color: Colors.redAccent,
// //                               fontSize: 13,
// //                             ),
// //                           ),
// //                         )
// //                         : const SizedBox.shrink(),
// //               ),

// //               // Login button
// //               Obx(
// //                 () => SizedBox(
// //                   width: double.infinity,
// //                   height: 52,
// //                   child: ElevatedButton(
// //                     onPressed: ctrl.isLoading.value ? null : ctrl.login,
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: depperBlue,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                     ),
// //                     child:
// //                         ctrl.isLoading.value
// //                             ? const SizedBox(
// //                               width: 20,
// //                               height: 20,
// //                               child: CircularProgressIndicator(
// //                                 strokeWidth: 2,
// //                                 color: Colors.white,
// //                               ),
// //                             )
// //                             : const Text(
// //                               'Sign In',
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.bold,
// //                                 color: Colors.white,
// //                               ),
// //                             ),
// //                   ),
// //                 ),
// //               ),

// //               const SizedBox(height: 24),
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   const Text(
// //                     "Don't have an account? ",
// //                     style: TextStyle(color: Colors.grey),
// //                   ),
// //                   GestureDetector(
// //                     onTap: () => Get.toNamed('/register_screen'),
// //                     child: Text(
// //                       'Sign Up',
// //                       style: TextStyle(
// //                         color: depperBlue,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 40),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ─── Register Screen ──────────────────────────────────────────────────────────
// // class RegisterScreen extends StatelessWidget {
// //   const RegisterScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     final ctrl = Get.find<AuthController>();
// //     final obscure = true.obs;
// //     final obscure2 = true.obs;
// //     final selectedRole = 'reader'.obs;

// //     return Scaffold(
// //       backgroundColor: background,
// //       appBar: AppBar(
// //         backgroundColor: background,
// //         leading: IconButton(
// //           icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
// //           onPressed: () => Get.back(),
// //         ),
// //         elevation: 0,
// //       ),
// //       body: SafeArea(
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.symmetric(horizontal: 24),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               const Text(
// //                 'Create Account',
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 28,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               const Text(
// //                 'Join the NoveluX community',
// //                 style: TextStyle(color: Colors.grey, fontSize: 14),
// //               ),
// //               const SizedBox(height: 32),

// //               // Username
// //               _label('Username'),
// //               const SizedBox(height: 8),
// //               TextField(
// //                 controller: ctrl.usernameCtrl,
// //                 style: const TextStyle(color: Colors.white),
// //                 decoration: _inputDec(
// //                   'Choose a username',
// //                   Icons.person_outline,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),

// //               // Email
// //               _label('Email'),
// //               const SizedBox(height: 8),
// //               TextField(
// //                 controller: ctrl.emailCtrl,
// //                 keyboardType: TextInputType.emailAddress,
// //                 style: const TextStyle(color: Colors.white),
// //                 decoration: _inputDec('Enter your email', Icons.email_outlined),
// //               ),
// //               const SizedBox(height: 20),

// //               // Password
// //               _label('Password'),
// //               const SizedBox(height: 8),
// //               Obx(
// //                 () => TextField(
// //                   controller: ctrl.passwordCtrl,
// //                   obscureText: obscure.value,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: _inputDec(
// //                     'Create a password',
// //                     Icons.lock_outline,
// //                   ).copyWith(
// //                     suffixIcon: IconButton(
// //                       icon: Icon(
// //                         obscure.value
// //                             ? Icons.visibility_off_outlined
// //                             : Icons.visibility_outlined,
// //                         color: Colors.grey,
// //                       ),
// //                       onPressed: () => obscure.value = !obscure.value,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 20),

// //               // Confirm Password
// //               _label('Confirm Password'),
// //               const SizedBox(height: 8),
// //               Obx(
// //                 () => TextField(
// //                   controller: ctrl.password2Ctrl,
// //                   obscureText: obscure2.value,
// //                   style: const TextStyle(color: Colors.white),
// //                   decoration: _inputDec(
// //                     'Confirm your password',
// //                     Icons.lock_outline,
// //                   ).copyWith(
// //                     suffixIcon: IconButton(
// //                       icon: Icon(
// //                         obscure2.value
// //                             ? Icons.visibility_off_outlined
// //                             : Icons.visibility_outlined,
// //                         color: Colors.grey,
// //                       ),
// //                       onPressed: () => obscure2.value = !obscure2.value,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 20),

// //               // Role selection
// //               _label('I want to'),
// //               const SizedBox(height: 12),
// //               //Obx(() =>
// //               Row(
// //                 children: [
// //                   _roleChip('Read stories', 'reader', selectedRole),
// //                   const SizedBox(width: 12),
// //                   _roleChip('Write & publish', 'author', selectedRole),
// //                 ],
// //               ),
// //               //),
// //               const SizedBox(height: 24),

// //               // Error
// //               Obx(
// //                 () =>
// //                     ctrl.errorMessage.value.isNotEmpty
// //                         ? Padding(
// //                           padding: const EdgeInsets.only(bottom: 12),
// //                           child: Text(
// //                             ctrl.errorMessage.value,
// //                             style: const TextStyle(
// //                               color: Colors.redAccent,
// //                               fontSize: 13,
// //                             ),
// //                           ),
// //                         )
// //                         : const SizedBox.shrink(),
// //               ),

// //               // Register button
// //               Obx(
// //                 () => SizedBox(
// //                   width: double.infinity,
// //                   height: 52,
// //                   child: ElevatedButton(
// //                     onPressed:
// //                         ctrl.isLoading.value
// //                             ? null
// //                             : () => ctrl.register(role: selectedRole.value),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: depperBlue,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                     ),
// //                     child:
// //                         ctrl.isLoading.value
// //                             ? const SizedBox(
// //                               width: 20,
// //                               height: 20,
// //                               child: CircularProgressIndicator(
// //                                 strokeWidth: 2,
// //                                 color: Colors.white,
// //                               ),
// //                             )
// //                             : const Text(
// //                               'Create Account',
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.bold,
// //                                 color: Colors.white,
// //                               ),
// //                             ),
// //                   ),
// //                 ),
// //               ),

// //               const SizedBox(height: 24),
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   const Text(
// //                     'Already have an account? ',
// //                     style: TextStyle(color: Colors.grey),
// //                   ),
// //                   GestureDetector(
// //                     onTap: () => Get.back(),
// //                     child: Text(
// //                       'Sign In',
// //                       style: TextStyle(
// //                         color: depperBlue,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 40),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _roleChip(String label, String value, RxString selected) {
// //     return Obx(
// //       () => GestureDetector(
// //         onTap: () => selected.value = value,
// //         child: Container(
// //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //           decoration: BoxDecoration(
// //             color:
// //                 selected.value == value
// //                     ? depperBlue.withOpacity(0.2)
// //                     : const Color(0xFF2a2a2a),
// //             border: Border.all(
// //               color: selected.value == value ? depperBlue : Colors.grey[800]!,
// //               width: 1.5,
// //             ),
// //             borderRadius: BorderRadius.circular(10),
// //           ),
// //           child: Text(
// //             label,
// //             style: TextStyle(
// //               color: selected.value == value ? depperBlue : Colors.grey,
// //               fontWeight:
// //                   selected.value == value ? FontWeight.bold : FontWeight.normal,
// //               fontSize: 13,
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ─── Shared helpers ───────────────────────────────────────────────────────────
// // Widget _label(String text) => Text(
// //   text,
// //   style: const TextStyle(
// //     color: Colors.white70,
// //     fontSize: 13,
// //     fontWeight: FontWeight.w500,
// //   ),
// // );

// // InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
// //   hintText: hint,
// //   hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
// //   prefixIcon: Icon(icon, color: Colors.grey, size: 20),
// //   filled: true,
// //   fillColor: const Color(0xFF2a2a2a),
// //   border: OutlineInputBorder(
// //     borderRadius: BorderRadius.circular(12),
// //     borderSide: BorderSide.none,
// //   ),
// //   enabledBorder: OutlineInputBorder(
// //     borderRadius: BorderRadius.circular(12),
// //     borderSide: const BorderSide(color: Color(0xFF3a3a3a)),
// //   ),
// //   focusedBorder: OutlineInputBorder(
// //     borderRadius: BorderRadius.circular(12),
// //     borderSide: BorderSide(color: depperBlue, width: 1.5),
// //   ),
// // );

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:novelux/config/app_style.dart';
// import 'package:novelux/config/api_service.dart';
// import 'package:novelux/config/local_storage.dart';
// import 'package:novelux/screen/auth/auth_controller.dart';

// // ── Shared helpers ─────────────────────────────────────────────────────────────
// Widget _label(String text) => Text(text,
//     style: const TextStyle(color: Colors.white70, fontSize: 13,
//         fontWeight: FontWeight.w500));

// InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
//   hintText: hint,
//   hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
//   prefixIcon: Icon(icon, color: Colors.grey, size: 20),
//   filled: true,
//   fillColor: const Color(0xFF2a2a2a),
//   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
//       borderSide: BorderSide.none),
//   enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
//       borderSide: const BorderSide(color: Color(0xFF3a3a3a))),
//   focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
//       borderSide: BorderSide(color: depperBlue, width: 1.5)),
// );

// // ── Login Screen ──────────────────────────────────────────────────────────────
// class LoginScreen extends StatelessWidget {
//   const LoginScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl    = Get.put(AuthController());
//     final obscure = true.obs;

//     return Scaffold(
//       backgroundColor: background,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             const SizedBox(height: 48),
//             Center(child: Text('NoveluX', style: TextStyle(fontSize: 32,
//                 fontWeight: FontWeight.bold, color: depperBlue))),
//             const SizedBox(height: 8),
//             const Center(child: Text('Read. Write. Earn.',
//                 style: TextStyle(color: Colors.grey, fontSize: 14))),
//             const SizedBox(height: 48),
//             const Text('Welcome back', style: TextStyle(color: Colors.white,
//                 fontSize: 24, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             const Text('Sign in to continue reading',
//                 style: TextStyle(color: Colors.grey, fontSize: 14)),
//             const SizedBox(height: 32),

//             _label('Email'),
//             const SizedBox(height: 8),
//             TextField(controller: ctrl.emailCtrl,
//                 keyboardType: TextInputType.emailAddress,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: _inputDec('Enter your email', Icons.email_outlined)),
//             const SizedBox(height: 20),

//             _label('Password'),
//             const SizedBox(height: 8),
//             Obx(() => TextField(controller: ctrl.passwordCtrl,
//                 obscureText: obscure.value,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: _inputDec('Enter your password', Icons.lock_outline)
//                     .copyWith(suffixIcon: IconButton(
//                   icon: Icon(obscure.value
//                       ? Icons.visibility_off_outlined
//                       : Icons.visibility_outlined, color: Colors.grey),
//                   onPressed: () => obscure.value = !obscure.value)))),
//             const SizedBox(height: 12),

//             Obx(() => ctrl.errorMessage.value.isNotEmpty
//                 ? Padding(padding: const EdgeInsets.only(bottom: 12),
//                     child: Text(ctrl.errorMessage.value,
//                         style: const TextStyle(color: Colors.redAccent, fontSize: 13)))
//                 : const SizedBox.shrink()),

//             Obx(() => SizedBox(width: double.infinity, height: 52,
//                 child: ElevatedButton(
//                   onPressed: ctrl.isLoading.value ? null : ctrl.login,
//                   style: ElevatedButton.styleFrom(backgroundColor: depperBlue,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12))),
//                   child: ctrl.isLoading.value
//                       ? const SizedBox(width: 20, height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                       : const Text('Sign In', style: TextStyle(fontSize: 16,
//                           fontWeight: FontWeight.bold, color: Colors.white))))),

//             const SizedBox(height: 24),
//             Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//               const Text("Don't have an account? ",
//                   style: TextStyle(color: Colors.grey)),
//               GestureDetector(
//                 onTap: () => Get.toNamed('/register_screen'),
//                 child: Text('Sign Up', style: TextStyle(color: depperBlue,
//                     fontWeight: FontWeight.bold))),
//             ]),
//             const SizedBox(height: 40),
//           ]),
//         ),
//       ),
//     );
//   }
// }

// // ── Register Screen (no role selection — always reader) ───────────────────────
// class RegisterScreen extends StatelessWidget {
//   const RegisterScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ctrl     = Get.find<AuthController>();
//     final obscure  = true.obs;
//     final obscure2 = true.obs;

//     return Scaffold(
//       backgroundColor: background,
//       appBar: AppBar(
//         backgroundColor: background,
//         leading: IconButton(
//           icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
//           onPressed: () => Get.back()),
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             const Text('Create Account', style: TextStyle(color: Colors.white,
//                 fontSize: 28, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             const Text('Join the NoveluX community',
//                 style: TextStyle(color: Colors.grey, fontSize: 14)),
//             const SizedBox(height: 32),

//             _label('Username'),
//             const SizedBox(height: 8),
//             TextField(controller: ctrl.usernameCtrl,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: _inputDec('Choose a username', Icons.person_outline)),
//             const SizedBox(height: 20),

//             _label('Email'),
//             const SizedBox(height: 8),
//             TextField(controller: ctrl.emailCtrl,
//                 keyboardType: TextInputType.emailAddress,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: _inputDec('Enter your email', Icons.email_outlined)),
//             const SizedBox(height: 20),

//             _label('Password'),
//             const SizedBox(height: 8),
//             Obx(() => TextField(controller: ctrl.passwordCtrl,
//                 obscureText: obscure.value,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: _inputDec('Create a password', Icons.lock_outline)
//                     .copyWith(suffixIcon: IconButton(
//                   icon: Icon(obscure.value
//                       ? Icons.visibility_off_outlined
//                       : Icons.visibility_outlined, color: Colors.grey),
//                   onPressed: () => obscure.value = !obscure.value)))),
//             const SizedBox(height: 20),

//             _label('Confirm Password'),
//             const SizedBox(height: 8),
//             Obx(() => TextField(controller: ctrl.password2Ctrl,
//                 obscureText: obscure2.value,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: _inputDec('Confirm your password', Icons.lock_outline)
//                     .copyWith(suffixIcon: IconButton(
//                   icon: Icon(obscure2.value
//                       ? Icons.visibility_off_outlined
//                       : Icons.visibility_outlined, color: Colors.grey),
//                   onPressed: () => obscure2.value = !obscure2.value)))),
//             const SizedBox(height: 24),

//             // Info note — no role selection
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//               decoration: BoxDecoration(
//                 color: depperBlue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: depperBlue.withOpacity(0.3))),
//               child: Row(children: [
//                 Icon(Icons.info_outline, color: depperBlue, size: 16),
//                 const SizedBox(width: 8),
//                 Expanded(child: Text(
//                   'You\'ll join as a Reader. You can apply to become an Author anytime from your profile.',
//                   style: TextStyle(color: depperBlue.withOpacity(0.9),
//                       fontSize: 12, height: 1.5))),
//               ]),
//             ),
//             const SizedBox(height: 24),

//             Obx(() => ctrl.errorMessage.value.isNotEmpty
//                 ? Padding(padding: const EdgeInsets.only(bottom: 12),
//                     child: Text(ctrl.errorMessage.value,
//                         style: const TextStyle(color: Colors.redAccent, fontSize: 13)))
//                 : const SizedBox.shrink()),

//             // Register button — always reader role
//             Obx(() => SizedBox(width: double.infinity, height: 52,
//                 child: ElevatedButton(
//                   onPressed: ctrl.isLoading.value
//                       ? null : () => ctrl.register(role: 'reader'),
//                   style: ElevatedButton.styleFrom(backgroundColor: depperBlue,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12))),
//                   child: ctrl.isLoading.value
//                       ? const SizedBox(width: 20, height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                       : const Text('Create Account', style: TextStyle(fontSize: 16,
//                           fontWeight: FontWeight.bold, color: Colors.white))))),

//             const SizedBox(height: 24),
//             Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//               const Text('Already have an account? ',
//                   style: TextStyle(color: Colors.grey)),
//               GestureDetector(
//                 onTap: () => Get.back(),
//                 child: Text('Sign In', style: TextStyle(color: depperBlue,
//                     fontWeight: FontWeight.bold))),
//             ]),
//             const SizedBox(height: 40),
//           ]),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/api_service.dart';
import 'package:novelux/config/local_storage.dart';
import 'package:novelux/screen/auth/auth_controller.dart';

// ── Shared helpers ─────────────────────────────────────────────────────────────
Widget _label(String text) => Text(
  text,
  style: const TextStyle(
    color: Colors.white70,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  ),
);

InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
  prefixIcon: Icon(icon, color: Colors.grey, size: 20),
  filled: true,
  fillColor: const Color(0xFF2a2a2a),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF3a3a3a)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: depperBlue, width: 1.5),
  ),
);

// ── Login Screen ──────────────────────────────────────────────────────────────
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AuthController());
    final obscure = true.obs;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'NoveluX',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: depperBlue,
                    fontFamily: kFontFamily,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Premium stories, just for you.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: kFontFamily,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Welcome back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: kFontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue reading',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: kFontFamily,
                ),
              ),
              const SizedBox(height: 32),

              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Email'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrl.emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDec(
                        'Enter your email',
                        Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _label('Password'),
                    const SizedBox(height: 8),
                    Obx(
                      () => TextField(
                        controller: ctrl.passwordCtrl,
                        obscureText: obscure.value,
                        autofillHints: const [AutofillHints.password],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDec(
                          'Enter your password',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => obscure.value = !obscure.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Obx(
                () =>
                    ctrl.errorMessage.value.isNotEmpty
                        ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            ctrl.errorMessage.value,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontFamily: kFontFamily,
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: ctrl.isLoading.value ? null : ctrl.login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: depperBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        ctrl.isLoading.value
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: kFontFamily,
                              ),
                            ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed('/register_screen'),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: depperBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[800])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[800])),
                ],
              ),
              const SizedBox(height: 20),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed:
                        ctrl.isLoading.value ? null : ctrl.loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF2a2a2a),
                      side: BorderSide(color: Colors.grey[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          child: CustomPaint(painter: _GoogleLogoPainter()),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign In with Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Register Screen (no role selection — always reader) ───────────────────────
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();
    final obscure = true.obs;
    final obscure2 = true.obs;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join the NoveluX community',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Username'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrl.usernameCtrl,
                      autofillHints: const [AutofillHints.newUsername],
                      style: const TextStyle(color: Colors.white),
                      autocorrect: false,
                      decoration: _inputDec(
                        'Choose a username',
                        Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _label('Email'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrl.emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDec(
                        'Enter your email',
                        Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _label('Password'),
                    const SizedBox(height: 8),
                    Obx(
                      () => TextField(
                        controller: ctrl.passwordCtrl,
                        obscureText: obscure.value,
                        autofillHints: const [AutofillHints.newPassword],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDec(
                          'Create a password',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => obscure.value = !obscure.value,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _label('Confirm Password'),
                    const SizedBox(height: 8),
                    Obx(
                      () => TextField(
                        controller: ctrl.password2Ctrl,
                        obscureText: obscure2.value,
                        autofillHints: const [AutofillHints.newPassword],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDec(
                          'Confirm your password',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure2.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => obscure2.value = !obscure2.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info note — no role selection
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: depperBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: depperBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: depperBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'ll join as a Reader. You can apply to become an Author anytime from your profile.',
                        style: TextStyle(
                          color: depperBlue.withOpacity(0.9),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Obx(
                () =>
                    ctrl.errorMessage.value.isNotEmpty
                        ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            ctrl.errorMessage.value,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),

              // Register button — always reader role
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        ctrl.isLoading.value
                            ? null
                            : () => ctrl.register(role: 'reader'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: depperBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        ctrl.isLoading.value
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: depperBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[800])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[800])),
                ],
              ),
              const SizedBox(height: 20),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed:
                        ctrl.isLoading.value ? null : ctrl.loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF2a2a2a),
                      side: BorderSide(color: Colors.grey[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          child: CustomPaint(painter: _GoogleLogoPainter()),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign up with Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google G logo painter ─────────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Blue arc (top-right)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.3,
      1.7,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18
        ..strokeCap = StrokeCap.butt,
    );
    // Red arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0.4,
      1.35,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18
        ..strokeCap = StrokeCap.butt,
    );
    // Yellow arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.75,
      1.35,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18
        ..strokeCap = StrokeCap.butt,
    );
    // Green arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.1,
      0.85,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18
        ..strokeCap = StrokeCap.butt,
    );
    // Horizontal bar of the G
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.85, cy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.width * 0.17
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
