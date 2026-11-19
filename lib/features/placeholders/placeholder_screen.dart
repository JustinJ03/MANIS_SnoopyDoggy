import 'package:material_ui/material_ui.dart';

import '../../core/widgets/async_view.dart';

/// Stub for screens outside M2 (UI-04 details, Customers, Help).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: EmptyState('Coming in a later milestone.')),
  );
}
