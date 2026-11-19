import 'package:material_ui/material_ui.dart';

import '../../theme/manis_theme.dart';
import '../models/enums.dart';

enum Tone { neutral, success, warning, danger }

/// A status shown as text (never colour alone), tinted by tone.
class StatusLabel extends StatelessWidget {
  const StatusLabel(
    this.text, {
    super.key,
    this.tone = Tone.neutral,
    this.icon,
  });

  StatusLabel.appointment(AppointmentStatus s, {Key? key})
    : this(
        s.label,
        key: key,
        tone: switch (s) {
          AppointmentStatus.pending => Tone.warning,
          AppointmentStatus.confirmed => Tone.success,
          AppointmentStatus.completed => Tone.neutral,
          AppointmentStatus.cancelled => Tone.danger,
        },
      );

  StatusLabel.deposit(DepositStatus s, {Key? key})
    : this(
        s.label,
        key: key,
        tone: s == DepositStatus.received ? Tone.success : Tone.warning,
      );

  StatusLabel.stock(StockLevel s, {Key? key})
    : this(
        s.label,
        key: key,
        tone: switch (s) {
          StockLevel.inStock => Tone.success,
          StockLevel.low => Tone.warning,
          StockLevel.out => Tone.danger,
        },
      );

  final String text;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = ManisColors.of(context);
    final (bg, fg) = switch (tone) {
      Tone.neutral => (c.line, c.ink),
      Tone.success => (c.successSoft, c.success),
      Tone.warning => (c.warningSoft, c.warning),
      Tone.danger => (c.dangerSoft, c.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ManisSpace.s2,
        vertical: ManisSpace.s1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ManisRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: ManisSpace.s1),
          ],
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
