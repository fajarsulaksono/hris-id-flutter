class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.relatedId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'notification',
        title: json['title'] as String? ?? 'Notifikasi',
        message: json['message'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        relatedId: json['related_id'] as String?,
        createdAt: json['created_at'] as String?,
      );

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? relatedId;
  final String? createdAt;
}
