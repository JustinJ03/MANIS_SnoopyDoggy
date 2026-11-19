import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers.dart';

Future<void> decide(WidgetTester tester, String customer, String button) async {
  await tester.tap(inCard(customer, find.text(button)));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirm deposit removes the card; Schedule shows Confirmed', (
    tester,
  ) async {
    await pumpApp(tester);
    await goTab(tester, 'Requests');
    expect(inCard('Tan Mei Ling', find.text('Deposit unpaid')), findsOneWidget);

    await decide(tester, 'Tan Mei Ling', 'Confirm RM15 deposit');
    expect(find.text('Tan Mei Ling'), findsNothing);
    expect(
      find.text('Confirmed Tan Mei Ling. Deposit received.'),
      findsOneWidget,
    );

    await goTab(tester, 'Schedule');
    expect(inCard('Tan Mei Ling', find.text('Confirmed')), findsOneWidget);
    expect(find.text('2 of 5 slots free'), findsOneWidget); // still blocked
  });

  testWidgets('reject cancels the request and frees the slot', (tester) async {
    await pumpApp(tester);
    await goTab(tester, 'Requests');
    await decide(tester, 'Tan Mei Ling', 'Reject');
    expect(find.text('Tan Mei Ling'), findsNothing);

    await goTab(tester, 'Schedule');
    expect(inCard('Tan Mei Ling', find.text('Cancelled')), findsOneWidget);
    expect(find.text('3 of 5 slots free'), findsOneWidget);
  });

  testWidgets('cancelling the dialog changes nothing', (tester) async {
    await pumpApp(tester);
    await goTab(tester, 'Requests');
    await tester.tap(inCard('Priya Raj', find.text('Reject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Priya Raj'), findsOneWidget);
  });

  testWidgets('no pending requests shows the empty text', (tester) async {
    await pumpApp(tester);
    await goTab(tester, 'Requests');
    for (final name in ['Tan Mei Ling', 'Priya Raj', 'Sarah Lim']) {
      await decide(tester, name, 'Reject');
    }
    expect(find.text('No pending requests'), findsOneWidget);
  });
}
