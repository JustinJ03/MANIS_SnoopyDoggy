import 'enums.dart';

/// BR-01: at most five bookings per day.
const dailyCap = 5;

class Appointment {
  const Appointment({
    required this.appointmentId,
    required this.customerId,
    required this.serviceId,
    this.designId,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.depositStatus,
  });

  final String appointmentId, customerId, serviceId;
  final String? designId;

  /// Stored in UTC; shown in Malaysia time via formatters.dart.
  final DateTime startAt, endAt;
  final AppointmentStatus status;
  final DepositStatus depositStatus;

  /// The only way to change status, so BR-07 is enforced in one place.
  Appointment moveTo(AppointmentStatus next, {DepositStatus? depositStatus}) {
    if (!status.canMoveTo(next)) {
      throw StateError('Cannot change ${status.label} to ${next.label}.');
    }
    return Appointment(
      appointmentId: appointmentId,
      customerId: customerId,
      serviceId: serviceId,
      designId: designId,
      startAt: startAt,
      endAt: endAt,
      status: next,
      depositStatus: depositStatus ?? this.depositStatus,
    );
  }
}

/// Free slots for one day's appointments (BR-02: Pending and Confirmed count).
int freeSlots(Iterable<Appointment> day) =>
    (dailyCap - day.where((a) => a.status.holdsSlot).length).clamp(0, dailyCap);
