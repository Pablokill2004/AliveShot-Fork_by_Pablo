import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';



class NotificationTile extends StatelessWidget {
  final UserNotification notification;
  final Widget? trailing;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      leading: Icon(
        _getIconForType(notification.type),
        color: notification.isRead ? Theme.of(context).disabledColor : theme.onPrimary,
      ),
      title: Text(
        notification.message,
        style: TextStyle(
          color: notification.isRead ? Theme.of(context).disabledColor : theme.onPrimary,
        ),
      ),
      subtitle: Text(
        _formatDate(notification.createdAt),
        style: TextStyle(color: Theme.of(context).disabledColor),
      ),
      trailing: trailing,
    );
  }

  IconData _getIconForType(NotificationType type) {
    return switch (type) {
      NotificationType.like => Icons.favorite,
      NotificationType.comment => Icons.chat_bubble,
      NotificationType.follow => Icons.person_add,
      NotificationType.challenge_request => Icons.sports_esports,
      NotificationType.challenge_won => Icons.emoji_events,
      NotificationType.challenge_lost => Icons.sentiment_dissatisfied,
    };
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Ahora';
  }
}
