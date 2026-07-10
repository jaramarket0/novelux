import 'package:flutter_test/flutter_test.dart';
import 'package:novelux/screen/redeem/redeem_screen.dart';

void main() {
  group('parseRedeemPackages', () {
    test('returns packages from a list payload', () {
      final packages = parseRedeemPackages([
        {'label': 'VIP', 'cost': 100, 'minutes': 60, 'benefit': 'vip'},
      ]);

      expect(packages, hasLength(1));
      expect(packages.first['label'], 'VIP');
    });

    test('returns packages from a wrapped map payload', () {
      final packages = parseRedeemPackages({
        'packages': [
          {'label': 'Ad-Free', 'cost': 50, 'minutes': 30, 'benefit': 'ad_free'},
        ],
      });

      expect(packages, hasLength(1));
      expect(packages.first['benefit'], 'ad_free');
    });
  });
}
