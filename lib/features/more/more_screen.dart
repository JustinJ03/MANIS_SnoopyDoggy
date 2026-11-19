import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/large_title_page.dart';
import '../../core/widgets/readable.dart';
import '../../theme/manis_theme.dart';
import '../auth/auth_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LargeTitlePage(
    title: 'More',
    body: Readable(
      // ListTiles carry their own 16 pt gutter.
      builder: (_, insets) => ListView(
        padding: EdgeInsets.symmetric(horizontal: insets.left - ManisSpace.s4),
        children: [
          // Rows that open a screen get the iOS disclosure chevron;
          // Log out is an action, so it doesn't.
          ListTile(
            leading: const Icon(CupertinoIcons.sparkles),
            title: const Text('Services'),
            subtitle: const Text('Prices, durations and designs'),
            trailing: const Icon(CupertinoIcons.chevron_forward),
            onTap: () => context.go('/more/services'),
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.question_circle),
            title: const Text('Help'),
            trailing: const Icon(CupertinoIcons.chevron_forward),
            onTap: () => context.go('/more/help'),
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.square_arrow_right),
            title: const Text('Log out'),
            onTap: () async {
              final ok = await confirmAction(
                context,
                title: 'Log out?',
                message: 'You will need to sign in again to use MANIS.',
                confirmLabel: 'Log out',
                destructive: true,
              );
              if (ok) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
    ),
  );
}
