import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/core/ui/ui.dart';

void main() {
  double ratio(Color a, Color b) => AppThemeColors.contrastRatio(a, b);

  void expectReadable(AppThemeColors c, String name) {
    expect(ratio(c.text, c.background), greaterThanOrEqualTo(7), reason: '$name: text/background');
    expect(ratio(c.text, c.surface), greaterThanOrEqualTo(7), reason: '$name: text/surface');
    expect(ratio(c.textMuted, c.surface), greaterThanOrEqualTo(4.5), reason: '$name: textMuted/surface');
    expect(ratio(c.onAction, c.action), greaterThanOrEqualTo(4.5), reason: '$name: onAction/action');
    expect(ratio(c.primaryText, c.surface), greaterThanOrEqualTo(4.5), reason: '$name: primaryText/surface');
    expect(ratio(c.onSecondary, c.secondary), greaterThanOrEqualTo(4.5), reason: '$name: onSecondary/secondary');
  }

  test('os 8 temas têm contraste AA', () {
    for (final preset in AppThemePreset.values) {
      expectReadable(preset.colors, preset.label);
    }
  });

  test('cores de marca extremas continuam legíveis', () {
    for (final hex in ['#FFFF00', '#000000', '#FFFFFF', '#00FF00', '#FF69B4', '#1A237E']) {
      for (final base in AppThemePreset.values) {
        expectReadable(AppThemeColors.resolve(base, brandColor: hex), '$hex sobre ${base.label}');
      }
    }
  });

  test('fromKey aceita chave do backend e slug de URL', () {
    expect(AppThemePreset.fromKey('SUNSET_ORANGE'), AppThemePreset.sunsetOrange);
    expect(AppThemePreset.fromKey('midnight-blue'), AppThemePreset.midnightBlue);
    expect(AppThemePreset.fromKey('???'), AppThemePreset.freshGreen);
    expect(AppThemePreset.fromKey(null), AppThemePreset.freshGreen);
  });

  test('hex vai e volta', () {
    expect(AppThemeColors.toHex(AppThemeColors.parseHex('#00a878')!), '#00A878');
    expect(AppThemeColors.parseHex('00A878'), isNull);
  });
}
