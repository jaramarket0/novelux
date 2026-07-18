import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:novelux/config/iap_service.dart';

/// Visual identity for a VIP subscription tier — icon, tint and label.
/// Escalates in prestige with commitment length: Weekly (bronze medal) <
/// Monthly (silver award) < Quarterly (gold trophy) < Yearly (diamond).
class PlanBadge {
  final IconData icon;
  final Color color;
  final String label;
  const PlanBadge(this.icon, this.color, this.label);
}

PlanBadge planBadgeFor(String? subId) {
  switch (subId) {
    case kSubWeekly:
      return const PlanBadge(
        LucideIcons.medal400,
        Color(0xFFCD7F32),
        'Weekly',
      );
    case kSubMonthly:
      return const PlanBadge(
        LucideIcons.award400,
        Color(0xFFC0C4CC),
        'Monthly',
      );
    case kSubQuarterly:
      return const PlanBadge(
        LucideIcons.trophy400,
        Color(0xFFE8B613),
        'Quarterly',
      );
    case kSubYearly:
      return const PlanBadge(LucideIcons.gem400, Color(0xFF7DD3FC), 'Yearly');
    default:
      return const PlanBadge(
        Icons.diamond_outlined,
        Color(0xFFB67C2A),
        'VIP',
      );
  }
}
