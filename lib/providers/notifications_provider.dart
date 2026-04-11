import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../config/supabase_provider.dart';

class NotificationsProvider extends ChangeNotifier {
  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void dispose() {
    _unsubscribeFromRealtime();
    super.dispose();
  }

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

      if (kDebugMode) {
        print('✅ Notificaciones cargadas: ${_notifications.length}');
      }

      // Iniciar escucha de notificaciones en tiempo real
      _subscribeToRealtimeNotifications(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error cargando notificaciones: $e');
      }
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToRealtimeNotifications(String userId) {
    _unsubscribeFromRealtime();

    final channelName = 'notifications_$userId';
    _channel = SupabaseProvider.client.channel(channelName);

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            if (kDebugMode) {
              print('📨 NOTIFICACIÓN REALTIME RECIBIDA: ${payload.newRecord}');
            }
            try {
              final newRecord = payload.newRecord as Map<String, dynamic>;
              // Verificar que sea para este usuario
              if (newRecord['recipient_user_id'] == userId) {
                final newNotification = Notification.fromJson(newRecord);
                // Verificar que no sea duplicado
                final isDuplicate = _notifications.any((n) => n.id == newNotification.id);
                if (!isDuplicate) {
                  _notifications.insert(0, newNotification);
                  notifyListeners();
                  if (kDebugMode) {
                    print('✅ Notificación agregada: ${newNotification.message}');
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error procesando notificación realtime: $e');
              }
            }
          },
        )
        .subscribe();
    
    if (kDebugMode) {
      print('🔔 Iniciando suscripción realtime para notificaciones del usuario: $userId');
    }
  }

  void _unsubscribeFromRealtime() {
    if (_channel != null) {
      SupabaseProvider.client.removeChannel(_channel!);
      _channel = null;
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
          publicationTitle: oldNotification.publicationTitle,
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
            publicationTitle: notification.publicationTitle,
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
