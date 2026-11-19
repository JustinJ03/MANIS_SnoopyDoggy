import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/inventory_item.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/large_title_page.dart';
import '../../core/widgets/readable.dart';
import '../../core/widgets/sheet_bar.dart';
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

  /// Items with a save in flight. Their controls stay disabled until the list
  /// is re-read, so a quick second tap can't save from a stale quantity.
  final _saving = <String>{};

  Future<void> _save(InventoryItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving.add(item.itemId));
    try {
      await ref.read(inventoryRepositoryProvider).save(item);
      showSnack(messenger, 'Saved ${item.name}: ${_qty(item)}.');
      ref.invalidate(inventoryProvider);
      await ref.read(inventoryProvider.future);
    } on ArgumentError catch (e) {
      showSnack(messenger, '${e.message}');
    } catch (_) {
      showSnack(
        messenger,
        "Couldn't save. Check your connection and try again.",
      );
    } finally {
      if (mounted) setState(() => _saving.remove(item.itemId));
    }
  }

  Future<void> _edit(InventoryItem item) async {
    final edited = await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // sheets cover the tab bar on iOS
      useSafeArea: true,
      builder: (_) => _EditStockSheet(item),
    );
    if (edited != null) await _save(edited);
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(onlineProvider);
    final text = Theme.of(context).textTheme;
    // One scroll view: the filter is its first row, and loading/error states
    // sit below it.
    final value = ref.watch(inventoryProvider);
    final items = [
      for (final i in value.value ?? const <InventoryItem>[])
        if (!_lowOnly || i.level != StockLevel.inStock) i,
    ];
    return LargeTitlePage(
      title: 'Inventory',
      body: Readable(
        builder: (context, insets) => PullToRefresh(
          onRefresh: () => ref.refresh(inventoryProvider.future),
          child: ListView.separated(
            padding: insets,
            physics: const AlwaysScrollableScrollPhysics(),
            // Row 0 is the filter; row 1 the loading/error/empty state when
            // there are no items to show; otherwise one row per item.
            itemCount:
                1 + (value.hasValue && items.isNotEmpty ? items.length : 1),
            separatorBuilder: (_, _) => const SizedBox(height: ManisSpace.s3),
            itemBuilder: (_, n) {
              if (n == 0) {
                return SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<bool>(
                    groupValue: _lowOnly,
                    onValueChanged: (v) =>
                        setState(() => _lowOnly = v ?? false),
                    children: const {
                      false: Text('All'),
                      true: Text('Low stock'),
                    },
                  ),
                );
              }
              if (!value.hasValue || items.isEmpty) {
                return AsyncView(
                  value: value,
                  onRetry: () => ref.invalidate(inventoryProvider),
                  builder: (_) => Center(
                    child: EmptyState(
                      _lowOnly ? 'Nothing is low on stock' : 'No items yet',
                    ),
                  ),
                );
              }
              final i = items[n - 1];
              final can = online && !_saving.contains(i.itemId);
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
                            icon: const Icon(CupertinoIcons.minus),
                            onPressed: can && i.quantity > 0
                                ? () => _save(
                                    i.copyWith(quantity: i.quantity - 1),
                                  )
                                : null,
                          ),
                          IconButton(
                            tooltip: 'Add one ${i.name}',
                            icon: const Icon(CupertinoIcons.plus),
                            onPressed: can && i.quantity < maxStock
                                ? () => _save(
                                    i.copyWith(quantity: i.quantity + 1),
                                  )
                                : null,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Edit ${i.name}',
                            icon: const Icon(CupertinoIcons.pencil),
                            onPressed: can ? () => _edit(i) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Upper bound for a typed or stepped quantity; catches slips like 1000.
const maxStock = 999;

/// iOS-style sheet for editing quantity and reorder level.
class _EditStockSheet extends StatefulWidget {
  const _EditStockSheet(this.item);
  final InventoryItem item;

  @override
  State<_EditStockSheet> createState() => _EditStockSheetState();
}

class _EditStockSheetState extends State<_EditStockSheet> {
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
    if (n > maxStock) return 'Enter $maxStock or less.';
    return null;
  }

  void _done() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.item.copyWith(
        quantity: int.parse(_quantity.text.trim()),
        reorderLevel: int.parse(_reorder.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    // Keeps the fields above the keyboard.
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetBar(title: 'Edit stock', doneLabel: 'Save', onDone: _done),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ManisSpace.s4,
                0,
                ManisSpace.s4,
                ManisSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: ManisSpace.s4),
                  TextFormField(
                    controller: _quantity,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Quantity (${widget.item.unit}s)',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: _wholeNumber,
                  ),
                  const SizedBox(height: ManisSpace.s4),
                  TextFormField(
                    controller: _reorder,
                    decoration: const InputDecoration(
                      labelText: 'Reorder level',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _wholeNumber,
                    onFieldSubmitted: (_) => _done(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
