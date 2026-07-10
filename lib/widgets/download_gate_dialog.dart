import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Gate shown before an offline download starts.
///
/// Pops with:
///   'ad'    — user chose (or countdown auto-chose) the rewarded ad
///   'coins' — user pays 120 coins
///   null    — cancelled
class DownloadGateDialog extends StatefulWidget {
  final String storyTitle;
  final int coinCost;

  const DownloadGateDialog({
    super.key,
    required this.storyTitle,
    this.coinCost = 120,
  });

  @override
  State<DownloadGateDialog> createState() => _DownloadGateDialogState();
}

class _DownloadGateDialogState extends State<DownloadGateDialog> {
  static const _countdownStart = 5;
  int _secondsLeft = _countdownStart;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        _choose('ad'); // countdown finished — start the ad automatically
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _choose(String? method) {
    _timer?.cancel();
    if (mounted) Get.back(result: method);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF232220),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded,
                color: Color(0xFFF5D9A8), size: 42),
            const SizedBox(height: 14),
            const Text(
              'Download for offline reading',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.storyTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 22),

            // ── Watch ad (auto-starts when the countdown ends) ──────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _choose('ad'),
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: Text(
                  'Watch Ad · ${_secondsLeft}s',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Skip with coins ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF5D9A8),
                  side: const BorderSide(color: Color(0xFFF5D9A8)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _choose('coins'),
                child: Text(
                  '🪙 Skip for ${widget.coinCost} Coins',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // ── Cancel ──────────────────────────────────────────────────
            TextButton(
              onPressed: () => _choose(null),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
