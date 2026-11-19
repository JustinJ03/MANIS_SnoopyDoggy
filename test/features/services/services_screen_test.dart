import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> openServices(WidgetTester tester) async {
  await pumpApp(tester);
  await goTab(tester, 'More');
  await tester.tap(find.text('Services'));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC-06.4: price ≤ 0 is rejected and values are kept', (
    tester,
  ) async {
    await openServices(tester);
    await tester.tap(find.byTooltip('Add service'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Chrome Powder');
    await tester.enterText(field('Price'), '0');
    await save(tester);
    expect(find.text('Price must be more than RM 0.'), findsOneWidget);
    expect(find.text('Chrome Powder'), findsOneWidget);

    await tester.enterText(field('Duration (minutes)'), '200');
    await save(tester);
    expect(find.text('Duration must be 120–180 minutes.'), findsOneWidget);
  });

  testWidgets('prices that parse but are not money are rejected', (
    tester,
  ) async {
    await openServices(tester);
    await tester.tap(find.byTooltip('Add service'));
    await tester.pumpAndSettle();
    for (final bad in ['NaN', 'Infinity', '1e3', '60.555', '-5']) {
      await tester.enterText(field('Price'), bad);
      await save(tester);
      expect(
        find.text('Enter a price like 60 or 60.50.'),
        findsOneWidget,
        reason: bad,
      );
    }
  });

  testWidgets('duplicate check ignores extra spaces', (tester) async {
    await openServices(tester);
    await tester.tap(find.byTooltip('Add service'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), '  gel   manicure ');
    await tester.enterText(field('Price'), '60');
    await save(tester);
    expect(
      find.text('A service called "gel manicure" already exists.'),
      findsOneWidget,
    );
  });

  testWidgets('duplicate name is flagged', (tester) async {
    await openServices(tester);
    await tester.tap(find.byTooltip('Add service'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'gel manicure');
    await tester.enterText(field('Price'), '60');
    await save(tester);
    expect(
      find.text('A service called "gel manicure" already exists.'),
      findsOneWidget,
    );
  });

  testWidgets('editing a price updates the list', (tester) async {
    await openServices(tester);
    await tester.tap(find.text('Gel Manicure'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Price'), '65');
    await save(tester);
    expect(find.text('RM 65.00 · 120 min'), findsOneWidget);
  });

  testWidgets('BR-15: deleting a booked service only deactivates it', (
    tester,
  ) async {
    await openServices(tester);
    expect(inCard('Gel Manicure', find.text('Active')), findsOneWidget);
    await tester.tap(find.text('Gel Manicure'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete service'));
    await tester.pumpAndSettle();
    await tapAlert(tester, 'Delete');
    expect(inCard('Gel Manicure', find.text('Inactive')), findsOneWidget);
    expect(
      find.text(
        'Gel Manicure has bookings, so it was deactivated instead of deleted.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('deleting an unbooked service removes it', (tester) async {
    await openServices(tester);
    await tester.tap(find.text('French Tips'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete service'));
    await tester.pumpAndSettle();
    await tapAlert(tester, 'Delete');
    expect(find.text('French Tips'), findsNothing);
  });

  testWidgets('service type is chosen from an iOS action sheet', (
    tester,
  ) async {
    await openServices(tester);
    await tester.tap(find.text('Gel Manicure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nail art'));
    await tester.pumpAndSettle();
    await save(tester);
    // Gel Manicure now sits under the "Nail art" group.
    expect(
      tester.getTopLeft(find.text('Gel Manicure')).dy,
      greaterThan(tester.getTopLeft(find.text('Nail art')).dy),
    );
  });
}
