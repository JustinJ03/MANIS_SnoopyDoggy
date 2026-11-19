import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Asks before a data-changing action with an iOS alert. Resolves false on
/// Cancel. [destructive] styles the action red and makes Cancel the default.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async =>
    await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: destructive,
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: !destructive,
            isDestructiveAction: destructive,
            onPressed: () => Navigator.pop(c, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

void showSnack(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));
