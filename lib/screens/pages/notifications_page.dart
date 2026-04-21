import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';
import 'package:flutter/material.dart';
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/screens/widgets/notification_tile.dart';
import 'package:alive_shot/screens/widgets/widgets.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onNotificationsChanged;
  const NotificationsPage({super.key, this.onNotificationsChanged});
  //final String firebaseUid;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with AutomaticKeepAliveClientMixin {
  List<UserNotification> _notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void readAll() {
    setState(() {
      _notifications = _notifications.map((e) {
        return e.copyWith(isRead: true);
      }).toList();
    });
  }

  Future<void> _loadNotifications() async {
    final firebaseUid = await ApiService.getCurrentUserUid();
    if (firebaseUid == null) return;

    final notifications = await ApiService.getUserNotifications(firebaseUid);
    setState(() {
      _notifications = notifications;
    });
  }

  Future<void> _acceptChallengeRequest(UserNotification notification) async {
    if (notification.challengeId == null) return;

    try {
      await CApiService.acceptRequest(notification.challengeId!);
      await ApiService.deleteNotification(notification.id);
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitud aceptada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectChallengeRequest(UserNotification notification) async {
    if (notification.challengeId == null) return;

    try {
      await CApiService.rejectRequest(notification.challengeId!);
      await ApiService.deleteNotification(notification.id);
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitud rechazada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: ResponsivePadding(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notificaciones', style: textTheme.headlineSmall),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: textTheme.bodyMedium?.color,
                    ),
                    icon: const Icon(Icons.check),
                    // texto "Marcar todas como leídas" con tamaño
                    label: const Text(
                      'Marcar todas como leídas',
                      style: TextStyle(fontSize: 12),
                    ),

                    onPressed: () async {
                      final firebaseUid = await ApiService.getCurrentUserUid();
                      if (firebaseUid == null) return;

                      await ApiService.markAllAsRead(firebaseUid);
                      readAll();
                      widget.onNotificationsChanged?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.onPrimary,
        onRefresh: _loadNotifications,
        child: ResponsivePadding(
          child: _notifications.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes notificaciones',
                              style: textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount:
                      _notifications.length, // ← IMPORTANTE: Agregar itemCount

                  itemBuilder: (context, index) {
                    final notification = _notifications[index];

                    // Determinar trailing
                    Widget? trailing;
                    if (notification.type ==
                            NotificationType.challenge_request &&
                        notification.challengeId != null) {
                      trailing = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () =>
                                _acceptChallengeRequest(notification),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                _rejectChallengeRequest(notification),
                          ),
                        ],
                      );
                    } else {
                      trailing = IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNotification(index),
                      );
                    }

                    return NotificationTile(
                      notification: notification,
                      trailing: trailing,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _deleteNotification(int index) async {
    final firebaseUid = await ApiService.getCurrentUserUid();
    if (firebaseUid == null) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta notificación?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Eliminar',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Verificar que el índice sea válido antes de eliminar
        if (index < 0 || index >= _notifications.length) {
          return;
        }

        final notification = _notifications[index];
        debugPrint("notificaciones actuales: $_notifications");
        debugPrint('Eliminando notificación con id: ${notification.id}');
        debugPrint("Borrando para el usuario con Firebase UID: $firebaseUid");

        // Corregir la llamada a deleteNotification - pasar el ID correcto
        await ApiService.deleteNotification(
          notification.id,
        ); // Usar notification.id en lugar de casting

        // Actualizar la lista de notificaciones
        setState(() {
          _notifications.removeAt(index);
        });

        widget.onNotificationsChanged?.call();

        // Mostrar mensaje de confirmación
        if (mounted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notificación eliminada')),
          );
        }
      } catch (e) {
        debugPrint('Error al eliminar notificación: $e');
        if (mounted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar la notificación'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}
