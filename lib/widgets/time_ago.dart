/// Formatte une date en relatif (ex: "il y a 2 j").
String timeAgo(DateTime date, {String lang = 'fr'}) {
  final diff = DateTime.now().difference(date);
  if (lang == 'fr') {
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem';
    return '${date.day}/${date.month}/${date.year}';
  }
  return '${date.day}/${date.month}/${date.year}';
}
