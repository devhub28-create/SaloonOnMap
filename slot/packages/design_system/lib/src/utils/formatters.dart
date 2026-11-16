/// Formats duration in minutes into human-readable string.
/// Examples:
/// 45 -> "45 min"
/// 60 -> "1 hr"
/// 75 -> "1 hr 15 min"
/// 90 -> "1 hr 30 min"
/// 120 -> "2 hrs"
/// 150 -> "2 hrs 30 min"
String formatDuration(dynamic minutes) {
  final totalMin = int.tryParse(minutes?.toString() ?? '0') ??
      (minutes is num ? (minutes as num).toInt() : 0);
  if (totalMin <= 0) return '0 min';
  if (totalMin < 60) {
    return '$totalMin min';
  }
  final hours = totalMin ~/ 60;
  final remainingMin = totalMin % 60;
  final hrStr = hours == 1 ? '1 hr' : '$hours hrs';
  if (remainingMin == 0) {
    return hrStr;
  }
  return '$hrStr $remainingMin min';
}
