import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/manis_theme.dart';
import 'router.dart';

class ManisApp extends ConsumerWidget {
  const ManisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'MANIS',
    theme: manisTheme(Brightness.light),
    darkTheme: manisTheme(Brightness.dark),
    routerConfig: ref.watch(routerProvider),
  );
}
