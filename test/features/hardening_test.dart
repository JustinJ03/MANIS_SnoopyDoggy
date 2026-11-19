import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_application_1/core/data/mock/mock_repositories.dart';
import 'package:flutter_application_1/core/data/repositories.dart';
import 'package:flutter_application_1/core/models/appointment.dart';
import 'package:flutter_application_1/core/models/customer.dart';
import 'package:flutter_application_1/core/models/enums.dart';
import 'package:flutter_application_1/core/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

class _Offline extends Online {
  @override
  bool build() => false;
}

/// Simulates the bot (or another device) having already handled the request.
class _AlreadyHandled extends MockAppointmentRepository {
  @override
  Future<Appointment> changeStatus(
    String appointmentId,
    AppointmentStatus next, {
    DepositStatus? depositStatus,
  }) async => throw StateError('Cannot change Cancelled to Confirmed.');
}

class _CountingAppointments extends MockAppointmentRepository {
  var loads = 0;
  final days = <DateTime>[];
  @override
  Future<List<Appointment>> pending() {
    loads++;
    return super.pending();
  }

  @override
  Future<List<Appointment>> forDay(DateTime mytDay) {
    days.add(mytDay);
    return super.forDay(mytDay);
  }
}

class _CountingCustomers extends MockCustomerRepository {
  final requested = <Set<String>>[];
  @override
  Future<List<Customer>> byIds(Set<String> customerIds) {
    requested.add(customerIds);
    return super.byIds(customerIds);
  }
}

const offlineText = "You're offline. Changes are disabled until you reconnect.";

void main() {
  testWidgets('offline banner does not double the notch inset', (tester) async {
    await pumpApp(
      tester,
      viewPadding: const EdgeInsets.only(top: 47),
      overrides: [onlineProvider.overrideWith(_Offline.new)],
    );
    final banner = find
        .ancestor(of: find.text(offlineText), matching: find.byType(Material))
        .first;
    expect(
      tester.getTopLeft(find.byType(AppBar)).dy,
      tester.getBottomLeft(banner).dy,
    );
  });

  testWidgets('schedule card is one VoiceOver button', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);
    expect(
      tester.getSemantics(find.text('Aina Sofea')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('rapid stepper taps cannot save from a stale quantity', (
    tester,
  ) async {
    await pumpApp(tester);
    await goTab(tester, 'Inventory');
    mockLatency = const Duration(milliseconds: 300);
    const wine = 'Gel polish – Wine Red';
    await tester.tap(find.byTooltip('Use one $wine'));
    await tester.pump();
    final minus = tester.widget<IconButton>(
      inCard(wine, find.widgetWithIcon(IconButton, CupertinoIcons.minus)),
    );
    expect(minus.onPressed, isNull, reason: 'locked while saving');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // One decrement from 3, not a lost or doubled update.
    expect(inCard(wine, find.text('2 bottles · reorder at 2')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            inCard(wine, find.widgetWithIcon(IconButton, CupertinoIcons.minus)),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a request already handled elsewhere says so, not "try again"', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        appointmentRepositoryProvider.overrideWithValue(_AlreadyHandled()),
      ],
    );
    await goTab(tester, 'Requests');
    await tester.tap(inCard('Tan Mei Ling', find.text('Confirm RM15 deposit')));
    await tester.pumpAndSettle();
    await tapAlert(tester, 'Confirm');
    expect(
      find.text(
        "Tan Mei Ling's request was already updated. The list is refreshed.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('pull to refresh works on an empty request list', (tester) async {
    final repo = _CountingAppointments();
    await pumpApp(
      tester,
      overrides: [appointmentRepositoryProvider.overrideWithValue(repo)],
    );
    await goTab(tester, 'Requests');
    for (final name in ['Tan Mei Ling', 'Priya Raj', 'Sarah Lim']) {
      await tester.tap(inCard(name, find.text('Reject')));
      await tester.pumpAndSettle();
      await tapAlert(tester, 'Reject');
    }
    expect(find.text('Pull down to check for new requests.'), findsOneWidget);
    final before = repo.loads;
    await tester.drag(find.text('No pending requests'), const Offset(0, 300));
    await tester.pump(); // release → refresh starts
    await tester.pump(const Duration(seconds: 1)); // indicator settles
    await tester.pumpAndSettle();
    expect(repo.loads, greaterThan(before));
  });

  testWidgets('screens load one day and pending only, customers by id', (
    tester,
  ) async {
    final appointments = _CountingAppointments();
    final customers = _CountingCustomers();
    await pumpApp(
      tester,
      overrides: [
        appointmentRepositoryProvider.overrideWithValue(appointments),
        customerRepositoryProvider.overrideWithValue(customers),
      ],
    );
    expect(appointments.days, [todayMyt()]);
    expect(appointments.loads, 1); // tab badge
    // Today's 3 customers and the 3 pending customers, never the full list.
    expect(customers.requested.every((ids) => ids.length <= 3), isTrue);

    // Confirming a request reloads pending and that one day, nothing else.
    await goTab(tester, 'Requests');
    await tester.tap(inCard('Priya Raj', find.text('Confirm RM15 deposit')));
    await tester.pumpAndSettle();
    await tapAlert(tester, 'Confirm');
    expect(appointments.loads, 2);
    // Priya's day (tomorrow) is marked stale but not fetched until viewed;
    // today's schedule isn't refetched at all.
    expect(appointments.days, [todayMyt()]);

    await goTab(tester, 'Schedule');
    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(appointments.days.last, todayMyt().add(const Duration(days: 1)));
    expect(inCard('Priya Raj', find.text('Confirmed')), findsOneWidget);
  });

  test('a booking with a missing customer or service still loads', () async {
    mockLatency = Duration.zero;
    final start = DateTime.utc(2026, 11, 19, 2);
    final container = ProviderContainer(
      overrides: [
        appointmentRepositoryProvider.overrideWithValue(
          MockAppointmentRepository([
            Appointment(
              appointmentId: 'apt-x',
              customerId: 'cus-gone',
              serviceId: 'svc-gone',
              startAt: start,
              endAt: start.add(const Duration(minutes: 150)),
              status: AppointmentStatus.pending,
              depositStatus: DepositStatus.unpaid,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final [booking] = await container.read(pendingBookingsProvider.future);
    expect(booking.customer.name, 'Unknown customer');
    expect(booking.service.name, 'Unknown service');
  });
}
