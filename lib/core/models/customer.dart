class Customer {
  const Customer({
    required this.customerId,
    required this.whatsappPhone,
    required this.name,
    this.profile = const CustomerProfile(),
  });

  final String customerId, whatsappPhone, name;
  final CustomerProfile profile;
}

class CustomerProfile {
  const CustomerProfile({
    this.allergyAlert,
    this.preferredNailShape,
    this.treatmentNotes,
  });

  final String? allergyAlert, preferredNailShape, treatmentNotes;
}
