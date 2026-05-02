import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../models/notification.dart' as notification_model;
import '../providers/notifications_provider.dart';
import '../config/supabase_provider.dart';
import 'property_details_screen.dart';
import 'roommate_search_details_screen.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all'; // 'all', 'roommate', 'departamento'

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

  List<notification_model.Notification> _getFilteredNotifications(
    List<notification_model.Notification> notifications,
  ) {
    if (_selectedFilter == 'all') {
      return notifications;
    }
    return notifications
        .where((n) => n.publicationType == _selectedFilter)
        .toList();
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

          final filteredNotifications = _getFilteredNotifications(
            notificationsProvider.notifications,
          );

          if (notificationsProvider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          if (filteredNotifications.isEmpty) {
            return _buildEmptyFilterState();
          }

          return RefreshIndicator(
            onRefresh: () => notificationsProvider.loadNotifications(),
            child: Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationTile(
                        filteredNotifications[index],
                        notificationsProvider,
                      );
                    },
                  ),
                ),
              ],
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

  Widget _buildFilterBar() {
    final Map<String, Map<String, dynamic>> filterOptions = {
      'all': {'label': 'Todos', 'icon': Icons.list},
      'departamento': {'label': 'Departamento', 'icon': Icons.apartment},
      'roommate': {'label': 'Rommi', 'icon': Icons.people},
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getFilterLabel(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return filterOptions.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.value['icon'] as IconData,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.value['label'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            icon: Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            position: PopupMenuPosition.under,
          ),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'departamento':
        return '🏠 Departamentos';
      case 'roommate':
        return '👤 Rommi';
      case 'all':
      default:
        return '≡ Todos';
    }
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list,
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
            'No hay notificaciones para este filtro',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
              });
            },
            child: const Text('Ver todas'),
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
              ? _getNotificationColor(notification).withOpacity(0.08)
              : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread 
                ? _getNotificationColor(notification).withOpacity(0.4)
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
                        color: _getNotificationColor(notification),
                        width: 2.5,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          _getNotificationColor(notification).withOpacity(0.1),
                          _getNotificationColor(notification).withOpacity(0.05),
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
                          notification.title,
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
                              color: _getNotificationColor(notification),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getNotificationColor(notification).withOpacity(0.4),
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
                      color: _getNotificationColor(notification).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification),
                      color: _getNotificationColor(notification),
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
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    
    // Obtener iniciales de las primeras 2 palabras
    String initials;
    if (words.isEmpty) {
      initials = 'U';
    } else if (words.length == 1) {
      initials = (words[0][0] + words[0][0]).toUpperCase();
    } else {
      initials = (words[0][0] + words[1][0]).toUpperCase();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
                _getNotificationColor(notification).withOpacity(0.3),
                _getNotificationColor(notification).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials.substring(0, 2.clamp(0, initials.length)),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
                color: _getNotificationColor(notification),
          ),
        ),
      ),
    );
  }

      bool _isProfileMatch(notification_model.Notification notification) {
        final normalizedTitle = (notification.publicationTitle ?? '').trim().toLowerCase();
        return notification.type == 'match' &&
            (notification.publicationType == 'profile' ||
             notification.senderName == null ||
             notification.senderName!.isEmpty ||
             normalizedTitle == 'nuevo match' ||
             normalizedTitle == '¡nuevo match!' ||
             normalizedTitle == '!nuevo match!');
      }

      IconData _getNotificationIcon(notification_model.Notification notification) {
        if (_isProfileMatch(notification)) {
          return Icons.favorite_rounded;
        }

        switch (notification.type) {
      case 'match':
        return Icons.person;
      case 'match_confirmed':
        return Icons.favorite_rounded;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'like':
        return Icons.favorite_rounded;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(notification_model.Notification notification) {
    if (_isProfileMatch(notification)) {
      return Colors.green;
    }

    switch (notification.type) {
      case 'match':
        return Colors.red;
      case 'match_confirmed':
        return Colors.green;
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
    final dateFormat = '${dateTime.day}/${dateTime.month}';
    final timeFormat = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateFormat - $timeFormat';
  }

  void _handleNotificationTap(notification_model.Notification notification) {
    switch (notification.type) {
      case 'match':
      case 'like':
      case 'match_confirmed':
        // Navegar al perfil del usuario que dio match/like,
        // pasando el contexto de la publicación para que _returnMatch() sea correcto
        if (mounted && notification.senderUserId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(
                userId: notification.senderUserId!,
                senderUserId: notification.senderUserId,
                publicationType: notification.publicationType, // ✅ 'roommate' | 'departamento'
                publicationId: notification.publicationId,    // ✅ ID real de la publicación
              ),
            ),
          );
        }
        break;
      case 'message':
        // Cerrar notificaciones
        if (mounted) {
          Navigator.pop(context);
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
