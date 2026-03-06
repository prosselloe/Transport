class FeedVersion {
  final String id;
  final String feedId;
  final DateTime? earliestCalendarDate;
  final DateTime? latestCalendarDate;
  final String? sha1;
  final String? url;
  final DateTime? fetchedAt; // Made nullable
  final DateTime? createdAt; // Made nullable

  FeedVersion({
    required this.id,
    required this.feedId,
    this.earliestCalendarDate,
    this.latestCalendarDate,
    this.sha1,
    this.url,
    this.fetchedAt, // Updated constructor
    this.createdAt, // Updated constructor
  });

  factory FeedVersion.fromJson(Map<String, dynamic> json) {
    return FeedVersion(
      id: json['id']?.toString() ?? '',
      feedId: json['feed']?.toString() ?? '',

      // Safely parse dates, allowing for nulls
      earliestCalendarDate: json['earliest_calendar_date'] != null
          ? DateTime.parse(json['earliest_calendar_date'])
          : null,
      latestCalendarDate: json['latest_calendar_date'] != null
          ? DateTime.parse(json['latest_calendar_date'])
          : null,

      sha1: json['sha1']?.toString(),
      url: json['url']?.toString(),

      // Safely parse dates, allowing for nulls
      fetchedAt: json['fetched_at'] != null
          ? DateTime.parse(json['fetched_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
