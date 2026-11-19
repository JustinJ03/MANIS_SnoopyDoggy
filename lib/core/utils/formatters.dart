/// Data is stored in UTC; the salon runs on Malaysia time (UTC+8, no DST).
const _myt = Duration(hours: 8);

/// A UTC instant as Malaysia wall-clock time (returned as a UTC DateTime so
/// its fields read as MYT without depending on the device time zone).
DateTime toMyt(DateTime utc) => utc.toUtc().add(_myt);

/// Today's date in Malaysia, at midnight.
DateTime todayMyt([DateTime? now]) {
  final t = toMyt(now ?? DateTime.now());
  return DateTime.utc(t.year, t.month, t.day);
}

bool isSameMytDay(DateTime utc, DateTime mytDay) {
  final t = toMyt(utc);
  return t.year == mytDay.year &&
      t.month == mytDay.month &&
      t.day == mytDay.day;
}

/// "8:00 AM" for a MYT wall-clock time.
String formatClock(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
}

String formatTime(DateTime utc) {
  final t = toMyt(utc);
  return formatClock(t.hour, t.minute);
}

String formatTimeRange(DateTime startUtc, DateTime endUtc) =>
    '${formatTime(startUtc)} – ${formatTime(endUtc)}';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Thu, 19 Nov 2026" for a MYT date.
String formatDate(DateTime mytDay) =>
    '${_days[mytDay.weekday - 1]}, ${mytDay.day} ${_months[mytDay.month - 1]} ${mytDay.year}';

String formatRm(num amount) => 'RM ${amount.toStringAsFixed(2)}';
