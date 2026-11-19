import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/large_title_page.dart';
import '../../core/widgets/readable.dart';
import '../../core/widgets/status_label.dart';
import '../../theme/manis_theme.dart';

/// UI-03 Appointment requests (FR-10, BR-05–BR-07).
class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LargeTitlePage(
    title: 'Requests',
    body: AsyncView(
      value: ref.watch(pendingBookingsProvider),
      onRetry: () => ref.invalidate(pendingBookingsProvider),
      builder: (pending) {
        // New requests arrive from the WhatsApp bot, so pull-to-refresh
        // works on the empty list too.
        return Readable(
          builder: (_, insets) => PullToRefresh(
            onRefresh: () => ref.refresh(pendingBookingsProvider.future),
            child: pending.isEmpty
                ? ListView(
                    padding: insets,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EmptyState(
                        'No pending requests',
                        hint: 'Pull down to check for new requests.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: insets,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: pending.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: ManisSpace.s3),
                    itemBuilder: (_, i) => _RequestCard(
                      pending[i],
                      key: ValueKey(pending[i].appointment.appointmentId),
                    ),
                  ),
          ),
        );
      },
    ),
  );
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard(this.booking, {super.key});
  final Booking booking;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  var _saving = false;

  Future<void> _decide({required bool accept}) async {
    final b = widget.booking;
    final a = b.appointment;
    final slot =
        '${formatDate(toMyt(a.startAt))}, ${formatTimeRange(a.startAt, a.endAt)}';
    final ok = await confirmAction(
      context,
      title: accept ? 'Confirm deposit?' : 'Reject request?',
      message: accept
          ? 'Mark the RM15 deposit from ${b.customer.name} as received and book $slot.'
          : "Cancel ${b.customer.name}'s request for $slot. The slot will be freed.",
      confirmLabel: accept ? 'Confirm' : 'Reject',
      destructive: !accept,
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .changeStatus(
            a.appointmentId,
            accept ? AppointmentStatus.confirmed : AppointmentStatus.cancelled,
            depositStatus: accept ? DepositStatus.received : null,
          );
      invalidateBookings(ref, a);
      showSnack(
        messenger,
        accept
            ? 'Confirmed ${b.customer.name}. Deposit received.'
            : "Rejected ${b.customer.name}'s request. Slot freed.",
      );
    } on StateError {
      // BR-07 refused: the request was already confirmed, cancelled or
      // removed elsewhere (bot, another device). Retrying can't help.
      invalidateBookings(ref, a);
      showSnack(
        messenger,
        "${b.customer.name}'s request was already updated. The list is refreshed.",
      );
    } catch (_) {
      showSnack(
        messenger,
        "Couldn't save. Check your connection and try again.",
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final a = b.appointment;
    final text = Theme.of(context).textTheme;
    final enabled = !_saving && ref.watch(onlineProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ManisSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.customer.name, style: text.titleSmall),
            Text(b.service.name, style: text.bodyMedium),
            const SizedBox(height: ManisSpace.s2),
            Text(formatDate(toMyt(a.startAt)), style: text.bodyMedium),
            Text(formatTimeRange(a.startAt, a.endAt), style: text.bodyMedium),
            const SizedBox(height: ManisSpace.s2),
            StatusLabel.deposit(a.depositStatus),
            const SizedBox(height: ManisSpace.s3),
            Wrap(
              spacing: ManisSpace.s2,
              runSpacing: ManisSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  onPressed: enabled ? () => _decide(accept: true) : null,
                  child: const Text('Confirm RM15 deposit'),
                ),
                OutlinedButton(
                  onPressed: enabled ? () => _decide(accept: false) : null,
                  child: const Text('Reject'),
                ),
                // Greyed buttons alone don't say why; show the save in flight.
                if (_saving)
                  Semantics(
                    label: 'Saving',
                    child: const CupertinoActivityIndicator(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
