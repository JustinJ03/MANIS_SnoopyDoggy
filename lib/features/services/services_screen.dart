import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/repositories.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/status_label.dart';
import '../../theme/manis_theme.dart';

/// UI-07 Service management (FR-05, FR-06, BR-15).
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final online = ref.watch(onlineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            tooltip: 'Add service',
            icon: const Icon(Icons.add),
            onPressed: online ? () => context.go('/more/services/new') : null,
          ),
        ],
      ),
      body: AsyncView(
        value: ref.watch(servicesProvider),
        onRetry: () => ref.invalidate(servicesProvider),
        builder: (all) {
          if (all.isEmpty) return const EmptyState('No services yet');
          final types = {for (final s in all) s.serviceType};
          return ListView(
            padding: const EdgeInsets.all(ManisSpace.s4),
            children: [
              for (final type in types) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    top: ManisSpace.s4,
                    bottom: ManisSpace.s2,
                  ),
                  child: Text(type, style: text.titleSmall),
                ),
                for (final s in all.where((s) => s.serviceType == type))
                  Card(
                    child: ListTile(
                      title: Text(s.name),
                      subtitle: Text(
                        '${formatRm(s.priceRm)} · ${s.durationMax} min',
                      ),
                      trailing: StatusLabel(
                        s.isActive ? 'Active' : 'Inactive',
                        tone: s.isActive ? Tone.success : Tone.neutral,
                      ),
                      onTap: () => context.go('/more/services/${s.serviceId}'),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
