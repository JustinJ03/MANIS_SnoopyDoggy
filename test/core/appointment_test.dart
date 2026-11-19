import 'package:flutter_application_1/core/data/mock/seed.dart';
import 'package:flutter_application_1/core/models/appointment.dart';
import 'package:flutter_application_1/core/models/enums.dart';
import 'package:flutter_application_1/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

Appointment appt(AppointmentStatus s) => Appointment(
  appointmentId: 'a',
  customerId: 'c',
  serviceId: 's',
  startAt: DateTime.utc(2026, 11, 19, 2),
  endAt: DateTime.utc(2026, 11, 19, 4),
  status: s,
  depositStatus: DepositStatus.unpaid,
);

void main() {
  const p = AppointmentStatus.pending, c = AppointmentStatus.confirmed;
  const done = AppointmentStatus.completed, x = AppointmentStatus.cancelled;

  test('BR-07: only the allowed status changes', () {
    final allowed = {(p, c), (p, x), (c, done), (c, x)};
    for (final from in AppointmentStatus.values) {
      for (final to in AppointmentStatus.values) {
        expect(
          from.canMoveTo(to),
          allowed.contains((from, to)),
          reason: '$from → $to',
        );
      }
    }
    expect(() => appt(done).moveTo(x), throwsStateError);
    final confirmed = appt(p).moveTo(c, depositStatus: DepositStatus.received);
    expect(confirmed.status, c);
    expect(confirmed.depositStatus, DepositStatus.received);
  });

  test('BR-02: Pending and Confirmed count toward the 5-per-day cap', () {
    expect(freeSlots([]), 5);
    expect(freeSlots([appt(p), appt(c), appt(x), appt(done)]), 3);
    expect(freeSlots(List.filled(6, appt(c))), 0);
  });

  test('formatters show MYT and RM', () {
    final start = DateTime.utc(2026, 11, 19, 2); // 10:00 MYT
    expect(
      formatTimeRange(start, start.add(const Duration(hours: 2))),
      '10:00 AM – 12:00 PM',
    );
    expect(formatTime(DateTime.utc(2026, 11, 19, 16)), '12:00 AM');
    expect(formatRm(60), 'RM 60.00');
    expect(
      todayMyt(DateTime.utc(2026, 11, 19, 17)),
      DateTime.utc(2026, 11, 20),
    );
    expect(formatDate(DateTime.utc(2026, 11, 19)), 'Thu, 19 Nov 2026');
  });

  test('seeded schedule is stored in UTC and lands on today in MYT', () {
    final now = DateTime.utc(2026, 11, 19, 1);
    final today = seedAppointments(now)
        .where((a) => isSameMytDay(a.startAt, todayMyt(now)));
    expect(today.length, 3);
    expect(today.every((a) => a.startAt.isUtc), isTrue);
  });
}
