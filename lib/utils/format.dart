import 'package:flutter/material.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// DST-safe day math.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Monday of the week containing [d].
DateTime startOfWeek(DateTime d) => addDays(dateOnly(d), 1 - d.weekday);

String dayKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1].substring(0, 3);

String monthShort(DateTime d) => _months[d.month - 1].substring(0, 3);

/// e.g. "Oct 15".
String formatShortDate(DateTime d) => '${monthShort(d)} ${d.day}';

/// "Today", "Yesterday" or e.g. "Mon, Oct 12".
String formatDayLabel(DateTime d) {
  final today = DateTime.now();
  if (isSameDay(d, today)) return 'Today';
  if (isSameDay(d, addDays(today, -1))) return 'Yesterday';
  final label = '${weekdayShort(d)}, ${formatShortDate(d)}';
  return d.year == today.year ? label : '$label, ${d.year}';
}

String formatTime(BuildContext context, DateTime d) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(d),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

/// 12345 -> "12,345".
String formatNumber(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// 72.0 -> "72", 72.46 -> "72.5".
String formatKg(double kg) {
  final text = kg.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// Parses user input such as "72,5" or "72.5"; null when out of range.
double? parseWeight(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  if (value == null || value < 20 || value > 400) return null;
  return value;
}

/// Height in cm, e.g. "172"; null when out of range.
double? parseHeight(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  if (value == null || value < 100 || value > 250) return null;
  return value;
}

String greeting(DateTime d) => d.hour < 12
    ? 'Good morning'
    : d.hour < 17
    ? 'Good afternoon'
    : 'Good evening';

String _two(int n) => n.toString().padLeft(2, '0');
