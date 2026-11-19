import 'package:flutter_application_1/core/data/mock/seed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> logIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(field('Email'), email);
  await tester.enterText(field('Password'), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validates empty fields and email format', (tester) async {
    await pumpApp(tester, signedIn: false);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await logIn(tester, 'owner-at-salon', 'x');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('wrong password shows the error and stays on Login', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: false);
    await logIn(tester, mockOwnerEmail, 'wrong-password');
    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('valid login lands on Schedule; log out returns to Login', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: false);
    await logIn(tester, mockOwnerEmail, mockOwnerPassword);
    expect(find.widgetWithText(AppBar, 'Schedule'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await goTab(tester, 'More');
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tapAlert(tester, 'Log out');
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets('NavigationRail at 800 dp, NavigationBar on phones', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(800, 1280));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Requests tab shows the pending count', (tester) async {
    await pumpApp(tester);
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('3')),
      findsOneWidget,
    );
  });
}
