import '../../models/appointment.dart';
import '../../models/customer.dart';
import '../../models/enums.dart';
import '../../models/inventory_item.dart';
import '../../models/service.dart';
import '../../utils/formatters.dart';

/// Test login for the mock AuthRepository only (not a real account).
const mockOwnerEmail = 'owner@bycashlyn.test';
const mockOwnerPassword = 'manis-demo-2026';

const seedCustomers = [
  Customer(
    customerId: 'cus-1',
    whatsappPhone: '+60123456701',
    name: 'Aina Sofea',
    profile: CustomerProfile(
      allergyAlert: 'Acetone',
      preferredNailShape: 'Almond',
      treatmentNotes: 'Use acetone-free remover.',
    ),
  ),
  Customer(
    customerId: 'cus-2',
    whatsappPhone: '+60123456702',
    name: 'Tan Mei Ling',
    profile: CustomerProfile(preferredNailShape: 'Square'),
  ),
  Customer(
    customerId: 'cus-3',
    whatsappPhone: '+60123456703',
    name: 'Nurul Izzah',
    profile: CustomerProfile(
      allergyAlert: 'Latex',
      preferredNailShape: 'Coffin',
    ),
  ),
  Customer(
    customerId: 'cus-4',
    whatsappPhone: '+60123456704',
    name: 'Priya Raj',
    profile: CustomerProfile(preferredNailShape: 'Oval'),
  ),
  Customer(
    customerId: 'cus-5',
    whatsappPhone: '+60123456705',
    name: 'Sarah Lim',
  ),
];

List<Service> seedServices() => const [
  Service(
    serviceId: 'svc-1',
    name: 'Gel Manicure',
    serviceType: 'Gel',
    priceRm: 60,
    durationMax: 120,
  ),
  Service(
    serviceId: 'svc-2',
    name: 'Gel Pedicure',
    serviceType: 'Gel',
    priceRm: 70,
    durationMax: 120,
  ),
  Service(
    serviceId: 'svc-3',
    name: 'Acrylic Extensions',
    serviceType: 'Extensions',
    priceRm: 120,
    durationMax: 180,
  ),
  Service(
    serviceId: 'svc-4',
    name: 'Polygel Extensions',
    serviceType: 'Extensions',
    priceRm: 110,
    durationMax: 150,
  ),
  Service(
    serviceId: 'svc-5',
    name: 'Custom Nail Art',
    serviceType: 'Nail art',
    priceRm: 90,
    durationMax: 150,
  ),
  Service(
    serviceId: 'svc-6',
    name: 'French Tips',
    serviceType: 'Nail art',
    priceRm: 75,
    durationMax: 120,
    isActive: false,
  ),
];

/// Seeded around "today" in MYT so the demo always has a live schedule.
List<Appointment> seedAppointments([DateTime? now]) {
  final today = todayMyt(now);
  // MYT wall-clock → UTC.
  DateTime at(int dayOffset, int hour, [int minute = 0]) => DateTime.utc(
    today.year,
    today.month,
    today.day + dayOffset,
    hour - 8,
    minute,
  );
  Appointment a(
    String id,
    String customer,
    String service,
    DateTime start,
    int minutes,
    AppointmentStatus status,
    DepositStatus deposit,
  ) => Appointment(
    appointmentId: id,
    customerId: customer,
    serviceId: service,
    startAt: start,
    endAt: start.add(Duration(minutes: minutes)),
    status: status,
    depositStatus: deposit,
  );
  const p = AppointmentStatus.pending, c = AppointmentStatus.confirmed;
  const u = DepositStatus.unpaid, r = DepositStatus.received;
  // Deliberately out of time order, to exercise sorting.
  return [
    a('apt-3', 'cus-3', 'svc-3', at(0, 16), 180, c, r),
    a('apt-1', 'cus-1', 'svc-1', at(0, 10), 120, c, r),
    a('apt-2', 'cus-2', 'svc-5', at(0, 13), 150, p, u),
    a('apt-4', 'cus-4', 'svc-4', at(1, 11), 150, p, u),
    a('apt-5', 'cus-5', 'svc-1', at(1, 14), 120, p, u),
    a(
      'apt-6',
      'cus-2',
      'svc-2',
      at(-1, 10),
      120,
      AppointmentStatus.completed,
      r,
    ),
    a(
      'apt-7',
      'cus-4',
      'svc-1',
      at(-1, 14),
      120,
      AppointmentStatus.cancelled,
      u,
    ),
  ];
}

List<InventoryItem> seedInventory() => const [
  InventoryItem(
    itemId: 'inv-1',
    name: 'Gel polish – Blush Pink',
    unit: 'bottle',
    quantity: 4,
    reorderLevel: 2,
  ),
  InventoryItem(
    itemId: 'inv-2',
    name: 'Gel polish – Wine Red',
    unit: 'bottle',
    quantity: 3,
    reorderLevel: 2,
  ),
  InventoryItem(
    itemId: 'inv-3',
    name: 'Base coat',
    unit: 'bottle',
    quantity: 2,
    reorderLevel: 2,
  ),
  InventoryItem(
    itemId: 'inv-4',
    name: 'Top coat',
    unit: 'bottle',
    quantity: 5,
    reorderLevel: 2,
  ),
  InventoryItem(
    itemId: 'inv-5',
    name: 'Acetone-free remover',
    unit: 'bottle',
    quantity: 0,
    reorderLevel: 1,
  ),
  InventoryItem(
    itemId: 'inv-6',
    name: 'Nail tips (coffin)',
    unit: 'pack',
    quantity: 6,
    reorderLevel: 2,
  ),
];
