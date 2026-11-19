import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/manis_theme.dart';
import 'confirm_dialog.dart';

/// Loading, error-with-retry and data states for one provider value.
/// A failed refresh keeps showing the last data instead of blanking the screen.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
    skipError: true,
    data: builder,
    loading: () => Center(
      child: Semantics(
        label: 'Loading',
        child: const CupertinoActivityIndicator(),
      ),
    ),
    error: (_, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(ManisSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Couldn't load this. Check your connection and try again.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ManisSpace.s4),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}

/// Pull-to-refresh for data the WhatsApp bot can change behind the owner's
/// back. On failure the current list stays and a snackbar says so.
/// [child] must be a scroll view with [AlwaysScrollableScrollPhysics].
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<Object?> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshIndicator.adaptive(
    onRefresh: () async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await onRefresh();
      } catch (_) {
        showSnack(messenger, "Couldn't refresh. Showing the last loaded list.");
      }
    },
    child: child,
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key, this.hint});
  final String text;

  /// Optional next step, e.g. "Pull down to check for new requests."
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(ManisSpace.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center, style: style.titleSmall),
          if (hint case final h?) ...[
            const SizedBox(height: ManisSpace.s2),
            Text(h, textAlign: TextAlign.center, style: style.bodySmall),
          ],
        ],
      ),
    );
  }
}
