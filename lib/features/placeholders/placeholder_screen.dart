import 'package:material_ui/material_ui.dart';

import '../../core/widgets/async_view.dart';
import '../../core/widgets/large_title_page.dart';

/// Stub for screens outside M2 (UI-04 details, Customers, Help).
/// [tabRoot] screens get the large title like the other tabs.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key, this.tabRoot = false});
  final String title;
  final bool tabRoot;

  static const _body = Center(
    child: EmptyState('Coming in a later milestone.'),
  );

  @override
  Widget build(BuildContext context) => tabRoot
      ? LargeTitlePage(title: title, body: _body)
      : Scaffold(
          appBar: AppBar(title: Text(title)),
          body: _body,
        );
}
