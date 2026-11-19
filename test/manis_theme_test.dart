import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/theme/manis_theme.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [
    ('light', ManisColors.light),
    ('dark', ManisColors.dark),
  ]) {
    test('$name: text pairs meet WCAG AA 4.5:1', () {
      final pairs = {
        'ink/surface': (c.ink, c.surface),
        'ink/surfaceRaised': (c.ink, c.surfaceRaised),
        'ink/blushSoft': (c.ink, c.blushSoft),
        'inkMuted/surface': (c.inkMuted, c.surface),
        'inkMuted/surfaceRaised': (c.inkMuted, c.surfaceRaised),
        'inkOnBlush/blush': (c.inkOnBlush, c.blush),
        'onAction/action': (c.onAction, c.action),
        'success/successSoft': (c.success, c.successSoft),
        'warning/warningSoft': (c.warning, c.warningSoft),
        'danger/dangerSoft': (c.danger, c.dangerSoft),
      };
      pairs.forEach(
        (k, p) =>
            expect(contrast(p.$1, p.$2), greaterThanOrEqualTo(4.5), reason: k),
      );
      expect(
        contrast(c.lineStrong, c.surface),
        greaterThanOrEqualTo(3),
        reason: 'lineStrong/surface',
      );
    });
  }

  test('theme builds for both brightnesses', () {
    expect(
      manisTheme(Brightness.light).colorScheme.primary,
      ManisColors.light.action,
    );
    expect(
      manisTheme(Brightness.dark).colorScheme.primary,
      ManisColors.dark.action,
    );
  });

  testWidgets('brand fonts are bundled for every weight the theme uses', (
    tester,
  ) async {
    final manifest = await rootBundle.loadString('FontManifest.json');
    for (final asset in [
      'assets/fonts/DMSans-Regular.ttf',
      'assets/fonts/DMSans-Medium.ttf',
      'assets/fonts/DMSans-SemiBold.ttf',
      'assets/fonts/DMSerifDisplay-Regular.ttf',
    ]) {
      expect(manifest, contains(asset));
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }
  });

  test('input and label roles stay on the token scale', () {
    final t = manisTheme(Brightness.light).textTheme;
    expect(t.bodyLarge?.fontFamily, 'DM Sans');
    expect(t.bodyLarge?.letterSpacing, 0);
    expect(t.labelMedium?.fontSize, 12);
    expect(t.labelMedium?.letterSpacing, 0);
  });
}
