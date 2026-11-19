import 'package:flutter_application_1/core/widgets/readable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// DoD: 360 dp and 800 dp render without overflow, at 2× text.
/// Any RenderFlex overflow is reported as a test failure by flutter_test.
void main() {
  for (final size in [const Size(360, 740), const Size(800, 1280)]) {
    testWidgets('every M2 screen fits at ${size.width.toInt()} dp, 2× text', (
      tester,
    ) async {
      await pumpApp(tester, size: size, textScale: 2);
      final rail = size.width >= 600;
      Future<void> tab(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(rail ? NavigationRail : NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      for (final label in ['Requests', 'Inventory', 'Customers', 'More']) {
        await tab(label);
      }
      await tester.tap(find.text('Services'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gel Manicure'));
      await tester.pumpAndSettle();
      await tab('Schedule');
    });
  }

  testWidgets('tab labels ignore Dynamic Type, body text does not', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(360, 740), textScale: 2);
    double scaleOf(Finder f) =>
        MediaQuery.textScalerOf(tester.element(f)).scale(10) / 10;
    expect(scaleOf(find.text('Customers')), 1);
    expect(scaleOf(find.text('2 of 5 slots free')), 2);
  });

  testWidgets('iPad keeps content in a readable column', (tester) async {
    await pumpApp(tester, size: const Size(1180, 820));
    expect(
      tester.getSize(cardOf('Aina Sofea')).width,
      lessThanOrEqualTo(readableWidth),
    );
  });

  testWidgets('login fits at 360 dp, 2× text', (tester) async {
    await pumpApp(
      tester,
      signedIn: false,
      size: const Size(360, 740),
      textScale: 2,
    );
  });
}
