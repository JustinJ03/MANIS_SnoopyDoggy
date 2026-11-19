import 'enums.dart';

class InventoryItem {
  const InventoryItem({
    required this.itemId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.reorderLevel,
  });

  final String itemId, name, unit;
  final int quantity, reorderLevel;

  /// FR-08 / BR-13: low when quantity ≤ reorderLevel.
  StockLevel get level => quantity <= 0
      ? StockLevel.out
      : quantity <= reorderLevel
      ? StockLevel.low
      : StockLevel.inStock;

  InventoryItem copyWith({int? quantity, int? reorderLevel}) => InventoryItem(
    itemId: itemId,
    name: name,
    unit: unit,
    quantity: quantity ?? this.quantity,
    reorderLevel: reorderLevel ?? this.reorderLevel,
  );
}
