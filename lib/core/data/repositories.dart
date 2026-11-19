import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/enums.dart';
import '../models/inventory_item.dart';
import '../models/service.dart';
import 'mock/mock_repositories.dart';

enum AuthFailureKind { invalidCredentials, connection }

class AuthFailure implements Exception {
  const AuthFailure(this.kind);
  final AuthFailureKind kind;
}

abstract interface class AuthRepository {
  bool get isSignedIn;

  /// Throws [AuthFailure].
  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

abstract interface class AppointmentRepository {
  Future<List<Appointment>> all();

  /// Applies BR-07 via [Appointment.moveTo]; throws [StateError] if not allowed.
  Future<Appointment> changeStatus(
    String appointmentId,
    AppointmentStatus next, {
    DepositStatus? depositStatus,
  });
}

abstract interface class CustomerRepository {
  Future<List<Customer>> all();
}

abstract interface class ServiceRepository {
  Future<List<Service>> all();

  /// Adds when [Service.serviceId] is empty, otherwise updates.
  Future<Service> save(Service service);

  /// BR-15: returns false when the service has bookings and was only
  /// deactivated instead of deleted.
  Future<bool> delete(String serviceId);
}

abstract interface class InventoryRepository {
  Future<List<InventoryItem>> all();

  /// Throws [ArgumentError] for negative quantity or reorder level (AC-07.3).
  Future<InventoryItem> save(InventoryItem item);
}

// shortcut: mock repositories with seeded by.cashlyn data; override with API
// repositories once backend #7 is ready.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);
final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => MockAppointmentRepository(),
);
final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => MockCustomerRepository(),
);
final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => MockServiceRepository(ref.watch(appointmentRepositoryProvider)),
);
final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => MockInventoryRepository(),
);

/// An appointment joined with its customer and service, for UI-02 and UI-03.
class Booking {
  const Booking(this.appointment, this.customer, this.service);
  final Appointment appointment;
  final Customer customer;
  final Service service;
}

/// All bookings in startAt order. Invalidate after any appointment change.
final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final (appointments, customers, services) = await (
    ref.watch(appointmentRepositoryProvider).all(),
    ref.watch(customerRepositoryProvider).all(),
    ref.watch(serviceRepositoryProvider).all(),
  ).wait;
  final c = {for (final x in customers) x.customerId: x};
  final s = {for (final x in services) x.serviceId: x};
  appointments.sort((a, b) => a.startAt.compareTo(b.startAt));
  return [
    for (final a in appointments) Booking(a, c[a.customerId]!, s[a.serviceId]!),
  ];
});

final servicesProvider = FutureProvider<List<Service>>(
  (ref) => ref.watch(serviceRepositoryProvider).all(),
);

final inventoryProvider = FutureProvider<List<InventoryItem>>(
  (ref) => ref.watch(inventoryRepositoryProvider).all(),
);

class Online extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

// shortcut: nothing sets this to false yet; wire connectivity_plus when the
// real API repositories land (M3).
final onlineProvider = NotifierProvider<Online, bool>(Online.new);
