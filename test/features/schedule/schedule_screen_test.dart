import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  testWidgets('cards are in start time order', (tester) async {
    await pumpApp(tester);
    final tops = [
      '10:00 AM – 12:00 PM',
      '1:00 PM – 3:30 PM',
      '4:00 PM – 7:00 PM',
    ].map((t) => tester.getTopLeft(find.text(t)).dy).toList();
    expect(tops, orderedEquals([...tops]..sort()));
  });

  testWidgets('AC-09.3: allergy badge and nail shape are visible', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(inCard('Aina Sofea', find.text('Allergy: Acetone')), findsOneWidget);
    expect(inCard('Aina Sofea', find.text('Shape: Almond')), findsOneWidget);
    expect(inCard('Tan Mei Ling', find.text('Pending')), findsOneWidget);
  });

  testWidgets('free slots count Pending and Confirmed against the cap', (
    tester,
  ) async {
    await pumpApp(tester);
    // Today: 2 Confirmed + 1 Pending.
    expect(find.text('2 of 5 slots free'), findsOneWidget);
  });

  testWidgets('empty day says "No appointments"', (tester) async {
    await pumpApp(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
    }
    expect(find.text('No appointments'), findsOneWidget);
    expect(find.text('5 of 5 slots free'), findsOneWidget);
  });
}
