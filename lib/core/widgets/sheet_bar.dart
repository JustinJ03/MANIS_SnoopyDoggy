import 'package:material_ui/material_ui.dart';

import '../../theme/manis_theme.dart';

/// iOS sheet header: Cancel · title · Done.
class SheetBar extends StatelessWidget {
  const SheetBar({
    super.key,
    required this.title,
    required this.onDone,
    this.doneLabel = 'Done',
  });

  final String title;
  final VoidCallback onDone;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ManisSpace.s2,
        vertical: ManisSpace.s2,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleSmall,
            ),
          ),
          TextButton(
            onPressed: onDone,
            child: Text(
              doneLabel,
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
