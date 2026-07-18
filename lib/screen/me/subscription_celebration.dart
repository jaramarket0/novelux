import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novelux/widgets/plan_badge.dart';

/// Shown right after a successful VIP purchase: reveals the tier badge
/// (bronze/silver/gold/diamond, matching the plan bought) then pops confetti.
class SubscriptionCelebrationDialog extends StatefulWidget {
  final String planId;
  const SubscriptionCelebrationDialog({super.key, required this.planId});

  @override
  State<SubscriptionCelebrationDialog> createState() =>
      _SubscriptionCelebrationDialogState();
}

class _SubscriptionCelebrationDialogState
    extends State<SubscriptionCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    // Reveal the badge first, then pop the confetti a beat later.
    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = planBadgeFor(widget.planId);

    return PopScope(
      canPop: true,
      child: Material(
        color: Colors.black.withOpacity(0.82),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: math.pi / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.04,
                  numberOfParticles: 24,
                  maxBlastForce: 22,
                  minBlastForce: 8,
                  gravity: 0.3,
                  colors: [
                    badge.color,
                    Colors.amber,
                    Colors.pinkAccent,
                    Colors.cyanAccent,
                    Colors.white,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: badge.color.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: badge.color, width: 3),
                      ),
                      child: Icon(badge.icon, color: badge.color, size: 46),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${badge.label} VIP Activated!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enjoy unlimited Ad-Free reading and your exclusive badge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: badge.color,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
