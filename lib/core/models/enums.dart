enum AppointmentStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  completed('Completed'),
  cancelled('Cancelled');

  const AppointmentStatus(this.label);
  final String label;

  /// BR-01/BR-02: Pending and Confirmed both hold a slot against the daily cap.
  bool get holdsSlot => this == pending || this == confirmed;

  /// BR-07: Pending → Confirmed → Completed; Pending/Confirmed → Cancelled.
  /// Completed and Cancelled are final.
  bool canMoveTo(AppointmentStatus next) => switch (this) {
    pending => next == confirmed || next == cancelled,
    confirmed => next == completed || next == cancelled,
    completed || cancelled => false,
  };
}

enum DepositStatus {
  unpaid('Deposit unpaid'),
  received('Deposit received');

  const DepositStatus(this.label);
  final String label;
}

enum StockLevel {
  inStock('In stock'),
  low('Low stock'),
  out('Out of stock');

  const StockLevel(this.label);
  final String label;
}
