/// "Just now", "5 min ago", "3 h ago", "Yesterday", "4 days ago".
String agoText(DateTime openedAt, DateTime now) {
  final minutes = now.difference(openedAt).inMinutes;
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return '$minutes min ago';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(openedAt.year, openedAt.month, openedAt.day);
  final days = today.difference(day).inDays;
  if (days == 0) return '${now.difference(openedAt).inHours} h ago';
  if (days == 1) return 'Yesterday';
  return '$days days ago';
}
