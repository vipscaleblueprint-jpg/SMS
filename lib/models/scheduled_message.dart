class ScheduledMessage {
  final String id;
  final String title;
  final DateTime date;
  final String? frequency;
  final String? frequencyDetail;
  final String? body;

  ScheduledMessage({
    required this.id,
    required this.title,
    required this.date,
    this.frequency,
    this.frequencyDetail,
    this.body,
  });
}
