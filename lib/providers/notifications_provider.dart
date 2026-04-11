import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../config/supabase_provider.dart';

class NotificationsProvider extends ChangeNotifier {
  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = SupabaseProvider.client.auth.currentUser?.id;
      if (userId == null) {
        _error = 'Usuario no autenticado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Cargar notificaciones de Supabase (tabla: notifications)
      final response = await SupabaseProvider.client
          .from('notifications')
          .select('*')
          .eq('recipient_user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (response.isEmpty) {
        _notifications = [];
      } else {
        _notifications = (response as List)
            .map((data) => Notification.fromJson(data as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Silenciar errores temporalmente hasta crear tabla en Supabase
      if (kDebugMode) {
        // print('Error cargando notificaciones: $e');
      }
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseProvider.client
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);

      // Actualizar localmente
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final oldNotification = _notifications[index];
        _notifications[index] = Notification(
          id: oldNotification.id,
          title: oldNotification.title,
          message: oldNotification.message,
          type: oldNotification.type,
          createdAt: oldNotification.createdAt,
          isRead: true,
          senderUserId: oldNotification.senderUserId,
          publicationId: oldNotification.publicationId,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marcando notificación como leída: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = SupabaseProvider.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseProvider.client
          .from('notifications')
          .update({'read': true})
          .eq('recipient_user_id', userId)
          .eq('read', false);

      // Actualizar localmente
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          final notification = _notifications[i];
          _notifications[i] = Notification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            createdAt: notification.createdAt,
            isRead: true,
            senderUserId: notification.senderUserId,
            publicationId: notification.publicationId,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error marcando todas como leídas: $e');
      }
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await SupabaseProvider.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error eliminando notificación: $e');
      }
    }
  }
}
