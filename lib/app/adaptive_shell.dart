import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/data/repositories.dart';
import '../core/models/enums.dart';
import '../theme/manis_theme.dart';

/// Bottom NavigationBar on phones, NavigationRail at ≥ 600 dp (SRS §3.1.1).
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        ref
            .watch(bookingsProvider)
            .value
            ?.where((b) => b.appointment.status == AppointmentStatus.pending)
            .length ??
        0;
    final requestsIcon = Badge(
      isLabelVisible: pending > 0,
      label: Text('$pending'),
      child: const Icon(Icons.inbox_outlined),
    );
    final items = <(Widget, String)>[
      (const Icon(Icons.calendar_today_outlined), 'Schedule'),
      (requestsIcon, 'Requests'),
      (const Icon(Icons.inventory_2_outlined), 'Inventory'),
      (const Icon(Icons.people_outline), 'Customers'),
      (const Icon(Icons.more_horiz), 'More'),
    ];
    void go(int i) =>
        shell.goBranch(i, initialLocation: i == shell.currentIndex);

    final online = ref.watch(onlineProvider);
    final body = Column(
      children: [
        if (!online)
          Material(
            color: ManisColors.of(context).warningSoft,
            child: const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(ManisSpace.s3),
                child: Text(
                  "You're offline. Changes are disabled until you reconnect.",
                ),
              ),
            ),
          ),
        Expanded(child: shell),
      ],
    );

    if (MediaQuery.sizeOf(context).width >= 600) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: _navMaxTextScale,
                child: NavigationRail(
                  scrollable: true,
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final (icon, label) in items)
                      NavigationRailDestination(icon: icon, label: Text(label)),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _navMaxTextScale,
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: go,
          destinations: [
            for (final (icon, label) in items)
              NavigationDestination(icon: icon, label: label),
          ],
        ),
      ),
    );
  }
}

/// Like the iOS tab bar, labels don't grow with Dynamic Type (five labels
/// can't fit a 360 pt width otherwise); body text still scales fully.
const _navMaxTextScale = 1.0;
