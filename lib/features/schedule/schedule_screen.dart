import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/repositories.dart';
import '../../core/models/appointment.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/large_title_page.dart';
import '../../core/widgets/readable.dart';
import '../../core/widgets/sheet_bar.dart';
import '../../core/widgets/status_label.dart';
import '../../theme/manis_theme.dart';

/// The day shown on UI-02. Follows "today" across midnight (the app can sit
/// in memory overnight) until the owner picks another day.
class ScheduleDay extends Notifier<DateTime> {
  var _followsToday = true;

  @override
  DateTime build() {
    final listener = AppLifecycleListener(
      onResume: () {
        if (_followsToday) state = todayMyt();
      },
    );
    ref.onDispose(listener.dispose);
    return todayMyt();
  }

  void set(DateTime mytDay) {
    _followsToday = mytDay == todayMyt();
    state = mytDay;
  }
}

/// Empty or whitespace-only text from the API counts as missing.
String? _present(String? s) =>
    (s == null || s.trim().isEmpty) ? null : s.trim();

final scheduleDayProvider = NotifierProvider<ScheduleDay, DateTime>(
  ScheduleDay.new,
);

/// UI-02 Daily schedule (FR-09, FR-11 badges, BR-01–BR-03).
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(scheduleDayProvider);
    final setDay = ref.read(scheduleDayProvider.notifier).set;
    final text = Theme.of(context).textTheme;

    Future<void> pickDate() async {
      var picked = DateTime(day.year, day.month, day.day);
      final done = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true, // sheets cover the tab bar on iOS
        useSafeArea: true,
        builder: (c) => SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetBar(
                title: 'Pick a date',
                onDone: () => Navigator.pop(c, true),
              ),
              SizedBox(
                height: 216,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: picked,
                  minimumDate: DateTime(day.year - 1),
                  maximumDate: DateTime(day.year + 1, 12, 31),
                  onDateTimeChanged: (d) => picked = d,
                ),
              ),
            ],
          ),
        ),
      );
      if (done ?? false) {
        setDay(DateTime.utc(picked.year, picked.month, picked.day));
      }
    }

    return LargeTitlePage(
      title: 'Schedule',
      actions: [
        IconButton(
          tooltip: 'Pick a date',
          icon: const Icon(CupertinoIcons.calendar),
          onPressed: pickDate,
        ),
      ],
      // One scroll view: the date bar is its first row, and loading/error
      // states sit below it, so day navigation never disappears.
      body: Readable(
        builder: (context, insets) => PullToRefresh(
          onRefresh: () => ref.refresh(dayBookingsProvider(day).future),
          child: ListView(
            padding: insets,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous day',
                    icon: const Icon(CupertinoIcons.chevron_left),
                    onPressed: () =>
                        setDay(day.subtract(const Duration(days: 1))),
                  ),
                  Expanded(
                    child: Text(
                      day == todayMyt()
                          ? 'Today · ${formatDate(day)}'
                          : formatDate(day),
                      textAlign: TextAlign.center,
                      style: text.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next day',
                    icon: const Icon(CupertinoIcons.chevron_right),
                    onPressed: () => setDay(day.add(const Duration(days: 1))),
                  ),
                ],
              ),
              const SizedBox(height: ManisSpace.s4),
              AsyncView(
                value: ref.watch(dayBookingsProvider(day)),
                onRetry: () => ref.invalidate(dayBookingsProvider(day)),
                builder: (list) => Column(
                  // Stretch so cards fill the column, as in a ListView.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${freeSlots(list.map((b) => b.appointment))} of $dailyCap slots free',
                      style: text.titleSmall,
                    ),
                    Text(
                      'Open ${formatClock(8, 0)} – ${formatClock(21, 0)}',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: ManisSpace.s4),
                    if (list.isEmpty)
                      const Center(child: EmptyState('No appointments'))
                    else
                      for (final b in list) ...[
                        _AppointmentCard(b),
                        const SizedBox(height: ManisSpace.s3),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard(this.booking);
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final a = booking.appointment;
    final allergy = _present(booking.customer.profile.allergyAlert);
    final shape = _present(booking.customer.profile.preferredNailShape);
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      // VoiceOver: one element that reads the whole card, announced as a
      // button that opens the details.
      child: MergeSemantics(
        child: Semantics(
          button: true,
          hint: 'Opens appointment details',
          child: InkWell(
            onTap: () => context.push('/appointments/${a.appointmentId}'),
            child: Padding(
              padding: const EdgeInsets.all(ManisSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: ManisSpace.s2,
                    runSpacing: ManisSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatTimeRange(a.startAt, a.endAt),
                        style: text.titleSmall,
                      ),
                      StatusLabel.appointment(a.status),
                    ],
                  ),
                  const SizedBox(height: ManisSpace.s2),
                  Text(booking.customer.name, style: text.bodyMedium),
                  Text(booking.service.name, style: text.bodySmall),
                  if (allergy != null || shape != null) ...[
                    const SizedBox(height: ManisSpace.s2),
                    Wrap(
                      spacing: ManisSpace.s2,
                      runSpacing: ManisSpace.s2,
                      children: [
                        if (allergy != null)
                          StatusLabel(
                            'Allergy: $allergy',
                            tone: Tone.danger,
                            icon: CupertinoIcons.exclamationmark_triangle,
                          ),
                        if (shape != null) StatusLabel('Shape: $shape'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
