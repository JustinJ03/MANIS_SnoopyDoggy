import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/data/mock/mock_repositories.dart';
import 'package:flutter_application_1/core/data/repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps the whole app on fresh mock data.
Future<void> pumpApp(
  WidgetTester tester, {
  bool signedIn = true,
  Size size = const Size(390, 1600),
  double textScale = 1,
  EdgeInsets viewPadding = EdgeInsets.zero,
  List<Override> overrides = const [],
}) async {
  mockLatency = Duration.zero;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(
    top: viewPadding.top,
    bottom: viewPadding.bottom,
  );
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(signedIn: signedIn),
        ),
        ...overrides,
      ],
      child: const ManisApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps a bottom-navigation destination.
Future<void> goTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Taps an action in the open iOS alert.
Future<void> tapAlert(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(CupertinoAlertDialog),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

/// The card containing [text].
Finder cardOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Card)).first;

Finder inCard(String cardText, Finder matching) =>
    find.descendant(of: cardOf(cardText), matching: matching);
