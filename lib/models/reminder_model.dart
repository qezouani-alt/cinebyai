class Reminder {
  final String id;
  final int mediaId;
  final String mediaType; // 'movie' or 'tv'
  final String title;
  final String posterUrl;
  final DateTime scheduledTime;

  Reminder({
    required this.id,
    required this.mediaId,
    required this.mediaType,
    required this.title,
    required this.posterUrl,
    required this.scheduledTime,
  });
}
