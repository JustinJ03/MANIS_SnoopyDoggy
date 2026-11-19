import 'package:flutter_application_1/core/data/mock/mock_repositories.dart';
import 'package:flutter_application_1/core/models/enums.dart';
import 'package:flutter_application_1/core/models/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const item = InventoryItem(
    itemId: 'inv-1',
    name: 'Gel polish – Blush Pink',
    unit: 'bottle',
    quantity: 4,
    reorderLevel: 2,
  );

  test('BR-13: low when quantity ≤ reorder level, out at 0', () {
    expect(item.level, StockLevel.inStock);
    expect(item.copyWith(quantity: 2).level, StockLevel.low);
    expect(item.copyWith(quantity: 0).level, StockLevel.out);
  });

  test('AC-07.3: repository rejects negative stock', () async {
    final repo = MockInventoryRepository();
    expect(repo.save(item.copyWith(quantity: -1)), throwsArgumentError);
    expect(repo.save(item.copyWith(reorderLevel: -1)), throwsArgumentError);
  });
}
