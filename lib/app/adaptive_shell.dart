import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/data/repositories.dart';
import '../theme/manis_theme.dart';

/// Bottom NavigationBar on phones, NavigationRail at ≥ 600 dp (SRS §3.1.1).
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: the shell (tab bar + every branch's chrome) rebuilds only when
    // the count changes, not on every booking reload.
    final pending = ref.watch(
      pendingBookingsProvider.select((v) => v.value?.length ?? 0),
    );
    final requestsIcon = Badge(
      isLabelVisible: pending > 0,
      label: Text('$pending'),
      child: const Icon(CupertinoIcons.tray),
    );
    final items = <(Widget, String)>[
      (const Icon(CupertinoIcons.calendar), 'Schedule'),
      (requestsIcon, 'Requests'),
      (const Icon(CupertinoIcons.cube_box), 'Inventory'),
      (const Icon(CupertinoIcons.person_2), 'Customers'),
      (const Icon(CupertinoIcons.ellipsis), 'More'),
    ];
    void go(int i) =>
        shell.goBranch(i, initialLocation: i == shell.currentIndex);

    final online = ref.watch(onlineProvider);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // full-width banner
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
        Expanded(
          // The banner already sits under the status bar; without this the
          // screen's AppBar would add the notch inset a second time.
          child: online
              ? shell
              : MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: shell,
                ),
        ),
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
