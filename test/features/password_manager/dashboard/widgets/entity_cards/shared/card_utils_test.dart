import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_cards/shared/card_utils.dart';

void main() {
  group('CardUtils.parseColor', () {
    test('should parse decimal int as opaque color', () {
      // 9052659 is 0x8A21F3
      const colorInt = 9052659;
      final color = CardUtils.parseColor(colorInt);
      
      expect(color.a, 1.0); // Should be opaque
      expect(color.r, 0x8A / 255.0);
      expect(color.g, 0x21 / 255.0);
      expect(color.b, 0xF3 / 255.0);
    });

    test('should parse decimal string as opaque color', () {
      final color = CardUtils.parseColor('9052659');
      expect(color.a, 1.0);
      expect(color.r, 0x8A / 255.0);
    });

    test('should parse hex string without hash as opaque color', () {
      final color = CardUtils.parseColor('8A21F3');
      expect(color.a, 1.0);
      expect(color.r, 0x8A / 255.0);
    });

    test('should handle null and empty', () {
      expect(CardUtils.parseColor(null), Colors.grey);
      expect(CardUtils.parseColor(''), Colors.grey);
    });
  });
}
