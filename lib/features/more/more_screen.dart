import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/confirm_dialog.dart';
import '../auth/auth_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.spa_outlined),
          title: const Text('Services'),
          subtitle: const Text('Prices, durations and designs'),
          onTap: () => context.go('/more/services'),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help'),
          onTap: () => context.go('/more/help'),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Log out'),
          onTap: () async {
            final ok = await confirmAction(
              context,
              title: 'Log out?',
              message: 'You will need to sign in again to use MANIS.',
              confirmLabel: 'Log out',
            );
            if (ok) await ref.read(authControllerProvider.notifier).signOut();
          },
        ),
      ],
    ),
  );
}
