import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/repositories.dart';
import '../../core/models/appointment.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/status_label.dart';
import '../../theme/manis_theme.dart';

class ScheduleDay extends Notifier<DateTime> {
  @override
  DateTime build() => todayMyt();
  void set(DateTime mytDay) => state = mytDay;
}

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
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(day.year, day.month, day.day),
        firstDate: DateTime(day.year - 1),
        lastDate: DateTime(day.year + 1, 12, 31),
      );
      if (picked != null) {
        setDay(DateTime.utc(picked.year, picked.month, picked.day));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            tooltip: 'Pick a date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous day',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setDay(day.subtract(const Duration(days: 1))),
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
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setDay(day.add(const Duration(days: 1))),
              ),
            ],
          ),
          Expanded(
            child: AsyncView(
              value: ref.watch(bookingsProvider),
              onRetry: () => ref.invalidate(bookingsProvider),
              builder: (all) {
                final list = all
                    .where((b) => isSameMytDay(b.appointment.startAt, day))
                    .toList();
                return ListView(
                  padding: const EdgeInsets.all(ManisSpace.s4),
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
                      const EmptyState('No appointments')
                    else
                      for (final b in list) ...[
                        _AppointmentCard(b),
                        const SizedBox(height: ManisSpace.s3),
                      ],
                  ],
                );
              },
            ),
          ),
        ],
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
    final profile = booking.customer.profile;
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
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
              if (profile.allergyAlert != null ||
                  profile.preferredNailShape != null) ...[
                const SizedBox(height: ManisSpace.s2),
                Wrap(
                  spacing: ManisSpace.s2,
                  runSpacing: ManisSpace.s2,
                  children: [
                    if (profile.allergyAlert case final allergy?)
                      StatusLabel(
                        'Allergy: $allergy',
                        tone: Tone.danger,
                        icon: Icons.warning_amber_rounded,
                      ),
                    if (profile.preferredNailShape case final shape?)
                      StatusLabel('Shape: $shape'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
