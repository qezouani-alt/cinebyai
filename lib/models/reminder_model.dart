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

  // A deterministic, positive 31-bit identifier remains cancellable after the
  // process restarts. String.hashCode is not a persistence format.
  int get notificationId {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaId': mediaId,
    'mediaType': mediaType,
    'title': title,
    'posterUrl': posterUrl,
    'scheduledTime': scheduledTime.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    mediaId: json['mediaId'] as int,
    mediaType: json['mediaType'] as String,
    title: json['title'] as String,
    posterUrl: json['posterUrl'] as String? ?? '',
    scheduledTime: DateTime.parse(json['scheduledTime'] as String),
  );
}
