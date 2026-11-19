import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers.dart';

const wine = 'Gel polish – Wine Red';
const base = 'Base coat';
const remover = 'Acetone-free remover';

Future<void> openInventory(WidgetTester tester) async {
  await pumpApp(tester);
  await goTab(tester, 'Inventory');
}

void main() {
  testWidgets('stepping down to the reorder level shows Low stock', (
    tester,
  ) async {
    await openInventory(tester);
    expect(inCard(wine, find.text('In stock')), findsOneWidget);
    await tester.tap(find.byTooltip('Use one $wine'));
    await tester.pumpAndSettle();
    expect(inCard(wine, find.text('Low stock')), findsOneWidget);
    expect(find.text('Saved $wine: 2 bottles.'), findsOneWidget);
  });

  testWidgets('AC-07.3: cannot go below 0', (tester) async {
    await openInventory(tester);
    // Stepper is disabled at 0 …
    expect(
      tester
          .widget<IconButton>(
            inCard(remover, find.widgetWithIcon(IconButton, Icons.remove)),
          )
          .onPressed,
      isNull,
    );
    // … and the edit dialog rejects negatives.

    await tester.tap(find.byTooltip('Edit $base'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity (bottles)'),
      '-1',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Cannot be below 0.'), findsOneWidget);
  });

  testWidgets('Low stock filter shows only low and out-of-stock items', (
    tester,
  ) async {
    await openInventory(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(CupertinoSlidingSegmentedControl<bool>),
        matching: find.text('Low stock'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(base), findsOneWidget);
    expect(find.text(remover), findsOneWidget);
    expect(find.text('Top coat'), findsNothing);
  });

  testWidgets('AC-08.3: restocking clears the Low stock label', (tester) async {
    await openInventory(tester);
    expect(inCard(base, find.text('Low stock')), findsOneWidget);
    await tester.tap(find.byTooltip('Add one $base'));
    await tester.pumpAndSettle();
    expect(inCard(base, find.text('In stock')), findsOneWidget);
  });
}
