import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/inventory_item.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/status_label.dart';
import '../../theme/manis_theme.dart';

String _qty(InventoryItem i) =>
    '${i.quantity} ${i.unit}${i.quantity == 1 ? '' : 's'}';

/// UI-05 Inventory (FR-07, FR-08 label + filter, BR-13).
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  var _lowOnly = false;

  Future<void> _save(InventoryItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(inventoryRepositoryProvider).save(item);
      ref.invalidate(inventoryProvider);
      showSnack(messenger, 'Saved ${item.name}: ${_qty(item)}.');
    } on ArgumentError catch (e) {
      showSnack(messenger, '${e.message}');
    } catch (_) {
      showSnack(messenger, "Couldn't save. Try again.");
    }
  }

  Future<void> _edit(InventoryItem item) async {
    final edited = await showDialog<InventoryItem>(
      context: context,
      builder: (_) => _EditStockDialog(item),
    );
    if (edited != null) await _save(edited);
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(onlineProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ManisSpace.s4),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('All')),
                ButtonSegment(value: true, label: Text('Low stock')),
              ],
              selected: {_lowOnly},
              onSelectionChanged: (s) => setState(() => _lowOnly = s.first),
            ),
          ),
          Expanded(
            child: AsyncView(
              value: ref.watch(inventoryProvider),
              onRetry: () => ref.invalidate(inventoryProvider),
              builder: (all) {
                final items = _lowOnly
                    ? all.where((i) => i.level != StockLevel.inStock).toList()
                    : all;
                if (items.isEmpty) {
                  return EmptyState(
                    _lowOnly ? 'Nothing is low on stock' : 'No items yet',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(ManisSpace.s4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: ManisSpace.s3),
                  itemBuilder: (_, n) {
                    final i = items[n];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(ManisSpace.s4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: ManisSpace.s2,
                              runSpacing: ManisSpace.s1,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(i.name, style: text.titleSmall),
                                StatusLabel.stock(i.level),
                              ],
                            ),
                            Text(
                              '${_qty(i)} · reorder at ${i.reorderLevel}',
                              style: text.bodySmall,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Use one ${i.name}',
                                  icon: const Icon(Icons.remove),
                                  onPressed: online && i.quantity > 0
                                      ? () => _save(
                                          i.copyWith(quantity: i.quantity - 1),
                                        )
                                      : null,
                                ),
                                IconButton(
                                  tooltip: 'Add one ${i.name}',
                                  icon: const Icon(Icons.add),
                                  onPressed: online
                                      ? () => _save(
                                          i.copyWith(quantity: i.quantity + 1),
                                        )
                                      : null,
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Edit ${i.name}',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: online ? () => _edit(i) : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EditStockDialog extends StatefulWidget {
  const _EditStockDialog(this.item);
  final InventoryItem item;

  @override
  State<_EditStockDialog> createState() => _EditStockDialogState();
}

class _EditStockDialogState extends State<_EditStockDialog> {
  final _form = GlobalKey<FormState>();
  late final _quantity = TextEditingController(text: '${widget.item.quantity}');
  late final _reorder = TextEditingController(
    text: '${widget.item.reorderLevel}',
  );

  @override
  void dispose() {
    _quantity.dispose();
    _reorder.dispose();
    super.dispose();
  }

  static String? _wholeNumber(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Enter a whole number.';
    if (n < 0) return 'Cannot be below 0.';
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Edit ${widget.item.name}'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _quantity,
            decoration: InputDecoration(
              labelText: 'Quantity (${widget.item.unit}s)',
            ),
            keyboardType: TextInputType.number,
            validator: _wholeNumber,
          ),
          const SizedBox(height: ManisSpace.s4),
          TextFormField(
            controller: _reorder,
            decoration: const InputDecoration(labelText: 'Reorder level'),
            keyboardType: TextInputType.number,
            validator: _wholeNumber,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            widget.item.copyWith(
              quantity: int.parse(_quantity.text.trim()),
              reorderLevel: int.parse(_reorder.text.trim()),
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}
