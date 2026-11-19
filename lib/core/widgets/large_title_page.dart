import 'package:material_ui/material_ui.dart';

import '../../theme/manis_theme.dart';
import 'readable.dart';

/// A tab's root screen with an iOS large title that collapses to an inline
/// title on scroll. Pushed detail screens keep a plain inline [AppBar].
///
/// [body] should be one scroll view (rows like a date bar or filter go
/// inside it), so content scrolls under the pinned bar instead of hiding
/// behind it.
class LargeTitlePage extends StatelessWidget {
  const LargeTitlePage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, box) => NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // FlexibleSpaceBar keeps the title visible in both states, scaling
          // the 24 pt inline title (titleLarge) up to the 34 pt large title.
          SliverAppBar(
            pinned: true,
            expandedHeight: 112,
            actions: actions,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title),
              centerTitle: false,
              // Same left edge as the content column (wide on iPad).
              titlePadding: EdgeInsetsDirectional.only(
                start: readableInsets(box.maxWidth).left,
                bottom: ManisSpace.s3,
              ),
              expandedTitleScale: 34 / 24,
            ),
          ),
        ],
        body: body,
      ),
    ),
  );
}
