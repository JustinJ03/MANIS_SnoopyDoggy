import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/enums.dart';
import '../models/inventory_item.dart';
import '../models/service.dart';
import '../utils/formatters.dart';
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

/// Queries are scoped to what a screen shows: never "every appointment ever",
/// which grows by ~1,800 rows a year at five bookings a day.
abstract interface class AppointmentRepository {
  /// Appointments starting on one Malaysia-time day (UI-02),
  /// e.g. `GET /appointments?date=2026-11-19`.
  Future<List<Appointment>> forDay(DateTime mytDay);

  /// Pending requests (UI-03 and the tab badge),
  /// e.g. `GET /appointments?status=pending`.
  Future<List<Appointment>> pending();

  /// Whether any appointment uses the service (BR-15).
  Future<bool> hasBookings(String serviceId);

  /// Applies BR-07 via [Appointment.moveTo]; throws [StateError] if not allowed.
  Future<Appointment> changeStatus(
    String appointmentId,
    AppointmentStatus next, {
    DepositStatus? depositStatus,
  });
}

abstract interface class CustomerRepository {
  /// Only the customers a screen shows, e.g. `GET /customers?ids=a,b`.
  /// Fetching by id (not caching the full list) also picks up customers the
  /// WhatsApp bot created since the last load.
  Future<List<Customer>> byIds(Set<String> customerIds);
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

/// One MYT day's bookings in startAt order (UI-02). Key: `mytDayOf(...)`.
final dayBookingsProvider = FutureProvider.family<List<Booking>, DateTime>(
  (ref, mytDay) =>
      _bookings(ref, ref.watch(appointmentRepositoryProvider).forDay(mytDay)),
);

/// Pending requests in startAt order (UI-03, tab badge).
final pendingBookingsProvider = FutureProvider<List<Booking>>(
  (ref) => _bookings(ref, ref.watch(appointmentRepositoryProvider).pending()),
);

/// After an appointment changes: refresh the requests list and that day.
void invalidateBookings(WidgetRef ref, Appointment changed) => ref
  ..invalidate(pendingBookingsProvider)
  ..invalidate(dayBookingsProvider(mytDayOf(changed.startAt)));

/// Joins appointments with their customers (fetched by id) and the cached
/// service list. All watches happen before the first await.
Future<List<Booking>> _bookings(
  Ref ref,
  Future<List<Appointment>> query,
) async {
  final customerRepo = ref.watch(customerRepositoryProvider);
  final servicesFuture = ref.watch(servicesProvider.future);
  final appointments = await query;
  final (customers, services) = await (
    customerRepo.byIds({for (final a in appointments) a.customerId}),
    servicesFuture,
  ).wait;
  final c = {for (final x in customers) x.customerId: x};
  final s = {for (final x in services) x.serviceId: x};
  final sorted = [...appointments]
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  // A dangling id (record removed on the backend) degrades one card instead
  // of failing the whole schedule.
  return [
    for (final a in sorted)
      Booking(
        a,
        c[a.customerId] ??
            Customer(
              customerId: a.customerId,
              whatsappPhone: '',
              name: 'Unknown customer',
            ),
        s[a.serviceId] ??
            Service(
              serviceId: a.serviceId,
              name: 'Unknown service',
              serviceType: '',
              priceRm: 0,
              durationMax: a.endAt.difference(a.startAt).inMinutes,
              isActive: false,
            ),
      ),
  ];
}

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
