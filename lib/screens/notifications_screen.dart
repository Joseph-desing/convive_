import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../models/notification.dart' as notification_model;
import '../providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar notificaciones cuando se abre la pantalla
    Future.microtask(() {
      if (mounted) {
        context.read<NotificationsProvider>().loadNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, notificationsProvider, _) {
              if (notificationsProvider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () => notificationsProvider.markAllAsRead(),
                child: const Text(
                  'Marcar todas',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, notificationsProvider, _) {
          if (notificationsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (notificationsProvider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => notificationsProvider.loadNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationsProvider.notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationTile(
                  notificationsProvider.notifications[index],
                  notificationsProvider,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí aparecerán nuevos matches y mensajes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    notification_model.Notification notification,
    NotificationsProvider notificationsProvider,
  ) {
    final isUnread = !notification.isRead;
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        notificationsProvider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación eliminada'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          notificationsProvider.markAsRead(notification.id);
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isUnread 
              ? _getNotificationColor(notification.type).withOpacity(0.08)
              : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread 
                ? _getNotificationColor(notification.type).withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
              width: isUnread ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
          children: [
            // Header con avatar, nombre y actions
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _getNotificationColor(notification.type),
                        width: 2.5,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          _getNotificationColor(notification.type).withOpacity(0.1),
                          _getNotificationColor(notification.type).withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: notification.senderProfileImageUrl != null && notification.senderProfileImageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.network(
                              notification.senderProfileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildAvatarInitials(notification),
                            ),
                          )
                        : _buildAvatarInitials(notification),
                  ),
                  const SizedBox(width: 14),
                  // Nombre y tipo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.senderName ?? 'Usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (notification.publicationType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: notification.publicationType == 'roommate'
                                  ? Colors.blue.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notification.publicationType == 'roommate'
                                  ? '👤 Buscando Roommate'
                                  : '🏠 Departamento',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: notification.publicationType == 'roommate'
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Menu de acciones
                  SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUnread)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification.type),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getNotificationColor(notification.type).withOpacity(0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            margin: const EdgeInsets.only(right: 6),
                          ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Eliminar'),
                              onTap: () async {
                                await notificationsProvider.deleteNotification(notification.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Notificación eliminada'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          position: PopupMenuPosition.under,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Mensaje principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            // Tiempo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Icono de acción
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),        ),      ),
    );
  }

  Widget _buildAvatarInitials(notification_model.Notification notification) {
    final name = notification.senderName ?? 'Usuario';
    final initials = name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join()
        .substring(0, 2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            _getNotificationColor(notification.type).withOpacity(0.3),
            _getNotificationColor(notification.type).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _getNotificationColor(notification.type),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'match':
        return Icons.person;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'like':
        return Icons.person;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'match':
        return Colors.red;
      case 'message':
        return Colors.blue;
      case 'like':
        return Colors.pink;
      case 'system':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Justo ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(notification_model.Notification notification) {
    switch (notification.type) {
      case 'match':
      case 'like':
        // Navegar al perfil del usuario que dio match/like
        if (mounted && notification.senderUserId != null) {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            '/user-profile',
            arguments: notification.senderUserId,
          );
        }
        break;
      case 'message':
        // Cerrar notificaciones y volver al chat
        if (mounted && notification.senderUserId != null) {
          Navigator.pop(context);
          // Navegar al chat con el usuario que envió el mensaje
          Navigator.pushNamed(
            context,
            '/chat-detail',
            arguments: notification.senderUserId,
          );
        }
        break;
      case 'system':
        if (mounted) {
          Navigator.pop(context);
        }
        break;
      default:
        break;
    }
  }
}
