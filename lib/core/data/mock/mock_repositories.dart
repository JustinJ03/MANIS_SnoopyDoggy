import '../../models/appointment.dart';
import '../../models/customer.dart';
import '../../models/enums.dart';
import '../../models/inventory_item.dart';
import '../../models/service.dart';
import '../../utils/formatters.dart';
import '../repositories.dart';
import 'seed.dart';

/// Small delay so loading states are visible in the demo. Tests set it to
/// zero because pumpAndSettle does not wait for timers.
var mockLatency = const Duration(milliseconds: 250);
Future<void> _wait() =>
    mockLatency == Duration.zero ? Future.value() : Future.delayed(mockLatency);

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.signedIn = false});
  bool signedIn;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> signIn(String email, String password) async {
    await _wait();
    if (email.toLowerCase() != mockOwnerEmail ||
        password != mockOwnerPassword) {
      throw const AuthFailure(AuthFailureKind.invalidCredentials);
    }
    signedIn = true;
  }

  @override
  Future<void> signOut() async => signedIn = false;
}

class MockAppointmentRepository implements AppointmentRepository {
  MockAppointmentRepository([List<Appointment>? items])
    : _items = List.of(items ?? seedAppointments());
  final List<Appointment> _items;

  @override
  Future<List<Appointment>> forDay(DateTime mytDay) async {
    await _wait();
    return [
      for (final a in _items)
        if (isSameMytDay(a.startAt, mytDay)) a,
    ];
  }

  @override
  Future<List<Appointment>> pending() async {
    await _wait();
    return [
      for (final a in _items)
        if (a.status == AppointmentStatus.pending) a,
    ];
  }

  @override
  Future<bool> hasBookings(String serviceId) async {
    await _wait();
    return _items.any((a) => a.serviceId == serviceId);
  }

  @override
  Future<Appointment> changeStatus(
    String appointmentId,
    AppointmentStatus next, {
    DepositStatus? depositStatus,
  }) async {
    await _wait();
    final i = _items.indexWhere((a) => a.appointmentId == appointmentId);
    if (i < 0) throw StateError('Appointment not found.');
    return _items[i] = _items[i].moveTo(next, depositStatus: depositStatus);
  }
}

class MockCustomerRepository implements CustomerRepository {
  @override
  Future<List<Customer>> byIds(Set<String> customerIds) async {
    if (customerIds.isEmpty) return const [];
    await _wait();
    return [
      for (final c in seedCustomers)
        if (customerIds.contains(c.customerId)) c,
    ];
  }
}

class MockServiceRepository implements ServiceRepository {
  MockServiceRepository(this._appointments, [List<Service>? items])
    : _items = List.of(items ?? seedServices());
  final AppointmentRepository _appointments;
  final List<Service> _items;
  var _nextId = 100;

  @override
  Future<List<Service>> all() async {
    await _wait();
    return List.of(_items);
  }

  @override
  Future<Service> save(Service service) async {
    await _wait();
    if (service.serviceId.isEmpty) {
      final added = Service(
        serviceId: 'svc-${_nextId++}',
        name: service.name,
        serviceType: service.serviceType,
        priceRm: service.priceRm,
        durationMax: service.durationMax,
        isActive: service.isActive,
      );
      _items.add(added);
      return added;
    }
    final i = _items.indexWhere((s) => s.serviceId == service.serviceId);
    if (i < 0) throw StateError('Service not found.');
    return _items[i] = service;
  }

  @override
  Future<bool> delete(String serviceId) async {
    final booked = await _appointments.hasBookings(serviceId);
    final i = _items.indexWhere((s) => s.serviceId == serviceId);
    if (i < 0) throw StateError('Service not found.');
    if (booked) {
      _items[i] = _items[i].copyWith(isActive: false);
      return false;
    }
    _items.removeAt(i);
    return true;
  }
}

class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository([List<InventoryItem>? items])
    : _items = List.of(items ?? seedInventory());
  final List<InventoryItem> _items;

  @override
  Future<List<InventoryItem>> all() async {
    await _wait();
    return List.of(_items);
  }

  @override
  Future<InventoryItem> save(InventoryItem item) async {
    await _wait();
    if (item.quantity < 0 || item.reorderLevel < 0) {
      throw ArgumentError('Stock cannot go below 0.');
    }
    final i = _items.indexWhere((x) => x.itemId == item.itemId);
    if (i < 0) throw StateError('Item not found.');
    return _items[i] = item;
  }
}
