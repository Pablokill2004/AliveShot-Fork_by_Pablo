import 'dart:math';

import 'package:alive_shot/screens/models/models.dart';

// ignore: constant_identifier_names
enum NotificationType { like, comment, follow, challenge_request, challenge_won, challenge_lost }

class UserNotification {
  final int id; // Agregar esta propiedad
  final NotificationType type;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? challengeId;

  const UserNotification({
    required this.id, // Agregar en el constructor
    required this.type,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.challengeId,
  });

  static List<UserNotification> dummyNotifications = List.generate(7, (index) {
    final type = NotificationType.values[Random().nextInt(2)];
    final user = User.dummyUsers[Random().nextInt(User.dummyUsers.length - 1)];

    return UserNotification(
      id: index,
      type: type,
      message: (type == NotificationType.like)
          ? '${user.username} menyukai postingan anda'
          : (type == NotificationType.comment)
          ? '${user.username} membalas komentar anda'
          : '${user.username} mulai mengikuti anda',
      createdAt: DateTime.now(),
      //dateTime: faker.date.dateTime(minYear: 2020, maxYear: 2023),
    );
  });

  UserNotification copyWith({
    NotificationType? type,
    String? message,
    DateTime? dateTime,
    bool? isRead,
    int? challengeId,
  }) {
    return UserNotification(
      id: id,
      type: type ?? this.type,
      message: message ?? this.message,
      // dateTime: dateTime ?? this.dateTime,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt, // Mantener la fecha de creación original
      challengeId: challengeId ?? this.challengeId,
    );
  }

  //Metodo para obtener la informacion de la notificacion de "seguido" de la API
  factory UserNotification.fromJson(Map<String, dynamic> json) {
    final type = _parseType(json['type']);
    return UserNotification(
      id: json['notification_id'] as int? ?? 0,

      type: type,
      message: json['message'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),

      isRead: json['is_read'] ?? false,
      challengeId: type == NotificationType.challenge_request
          ? json['challenge_id'] as int?
          : null,
    );
  }
  static NotificationType _parseType(String? type) {
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.follow,
    );
  }

}
