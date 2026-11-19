import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/manis_theme.dart';

/// iOS readable-content width: on wide windows (iPad) content sits in a
/// centred column instead of stretching edge to edge.
const readableWidth = 720.0;

/// Padding that centres content in a [readableWidth] column, never less than
/// the phone gutter. Use on scroll views so the whole width still scrolls.
EdgeInsets readableInsets(double width) => EdgeInsets.symmetric(
  horizontal: math.max(ManisSpace.s4, (width - readableWidth) / 2),
  vertical: ManisSpace.s4,
);

/// Builds [builder] with [readableInsets] for the available width.
class Readable extends StatelessWidget {
  const Readable({super.key, required this.builder});
  final Widget Function(BuildContext context, EdgeInsets insets) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => builder(context, readableInsets(box.maxWidth)),
  );
}
