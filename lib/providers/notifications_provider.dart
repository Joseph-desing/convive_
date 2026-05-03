import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/notification.dart';
import '../config/supabase_provider.dart';

class NotificationsProvider extends ChangeNotifier {
  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _channel;
  bool _isSubscribed = false; // ✅ NUEVO: Flag para evitar múltiples suscripciones
  Timer? _debounceTimer; // ✅ NUEVO: Timer para debounce de notifyListeners
  bool _pendingNotification = false; // ✅ NUEVO: Flag para saber si hay cambios pendientes

  String _notificationKey(Notification notification) {
    // ✅ Normalizar: 'match' y 'match_confirmed' del mismo sender se consideran
    // el mismo tipo para deduplicación (evita duplicados históricos en BD)
    final normalizedType = (notification.type == 'match' || notification.type == 'match_confirmed')
        ? 'match_any'
        : notification.type;

    return [
      normalizedType,
      notification.senderUserId ?? '',
      notification.publicationId ?? '',
    ].join('|');
  }

  List<Notification> _dedupeNotifications(Iterable<Notification> items) {
    final seen = <String>{};
    final deduped = <Notification>[];

    for (final item in items) {
      final key = _notificationKey(item);
      if (seen.add(key)) {
        deduped.add(item);
      }
    }

    return deduped;
  }

  bool _shouldShowNotification(Notification notification, String currentUserId) {
    if (notification.type == 'match' &&
        notification.senderUserId == currentUserId) {
      return false;
    }

    return true;
  }

  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void dispose() {
    _debounceTimer?.cancel(); // ✅ NUEVO: Limpiar timer
    _unsubscribeFromRealtime();
    super.dispose();
  }

  /// ✅ NUEVO: Notificar cambios con debounce (máximo 1 notificación por 500ms)
  void _notifyChangesDebounced() {
    _pendingNotification = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_pendingNotification) {
        notifyListeners();
        _pendingNotification = false;
        if (kDebugMode) {
          print('🔔 Notificaciones actualizadas (debounced)');
        }
      }
    });
  }

  Future<void> loadNotifications() async {
    // ✅ GUARD: Evitar múltiples cargas simultáneas
    if (_isLoading) {
      if (kDebugMode) {
        print('⏳ Ya se está cargando, ignorando nueva solicitud');
      }
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = SupabaseProvider.client.auth.currentUser?.id;
      if (userId == null) {
        _error = 'Usuario no autenticado';
        _isLoading = false;
        notifyListeners();
        if (kDebugMode) {
          print('⚠️ Usuario no autenticado para cargar notificaciones');
        }
        return;
      }

      if (kDebugMode) {
        print('📥 Iniciando carga de notificaciones para usuario: $userId');
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
        if (kDebugMode) {
          print('ℹ️ No hay notificaciones para este usuario');
        }
      } else {
        final loadedNotifications = (response as List)
            .map((data) => Notification.fromJson(data as Map<String, dynamic>))
            .where((notification) => _shouldShowNotification(notification, userId));

        _notifications = _dedupeNotifications(loadedNotifications.toList());
        if (kDebugMode) {
          print('✅ Notificaciones cargadas: ${_notifications.length}');
          for (var notif in _notifications) {
            print('  - ${notif.type}: ${notif.message}');
          }
        }
      }

      // ✅ NUEVO: Solo iniciar realtime si aún no está suscrito
      if (!_isSubscribed) {
        if (kDebugMode) {
          print('🔌 Inicializando realtime para usuario: $userId');
        }
        _subscribeToRealtimeNotifications(userId);
        _isSubscribed = true;
      } else if (kDebugMode) {
        print('✅ Ya estamos suscritos a realtime, no reinicializando');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cargando notificaciones: $e');
      }
      _notifications = [];
      _error = 'Error cargando notificaciones';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToRealtimeNotifications(String userId) {
    _unsubscribeFromRealtime();

    // ✅ Usar un nombre de canal consistente (sin timestamp) para evitar múltiples suscripciones
    final channelName = 'notifications:recipient_user_id=eq.$userId';
    _channel = SupabaseProvider.client.channel(
      channelName,
      opts: const RealtimeChannelConfig(
        ack: true,
      ),
    );

    if (kDebugMode) {
      print('🔄 Creando canal realtime: $channelName');
    }

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          // ✅ FILTRO EXPLÍCITO para evitar procesar todas las inserciones
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              if (kDebugMode) {
                print('🔔 Evento INSERT recibido: ${payload.newRecord}');
              }
              
              final newRecord = payload.newRecord;
              // Validar que sea un Map válido
              if (newRecord is! Map<String, dynamic>) {
                if (kDebugMode) {
                  print('⚠️ Payload inválido: $newRecord');
                }
                return;
              }
              
              final newNotification = Notification.fromJson(newRecord);
              if (!_shouldShowNotification(newNotification, userId)) {
                if (kDebugMode) {
                  print('⚠️ Notificación de match propia ignorada: ${newNotification.id}');
                }
                return;
              }
              // ✅ DEDUPLICACIÓN ROBUSTA: Verificar por ID y timestamp para evitar duplicados
              final isDuplicate = _notifications.any((n) => _notificationKey(n) == _notificationKey(newNotification));
              if (!isDuplicate) {
                _notifications.insert(0, newNotification);
                // ✅ NUEVO: Usar debounce en lugar de notifyListeners directo
                _notifyChangesDebounced();
                if (kDebugMode) {
                  print('✅ 📨 REALTIME: Notificación recibida: ${newNotification.message} (ID: ${newNotification.id})');
                }
              } else if (kDebugMode) {
                print('⚠️ Notificación duplicada ignorada: ${newNotification.id}');
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error procesando notificación realtime: $e');
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final oldRecord = payload.oldRecord;
              if (oldRecord is Map<String, dynamic>) {
                final deletedId = oldRecord['id'] as String?;
                if (deletedId != null) {
                  _notifications.removeWhere((n) => n.id == deletedId);
                  // ✅ NUEVO: Usar debounce en lugar de notifyListeners directo
                  _notifyChangesDebounced();
                  if (kDebugMode) {
                    print('🗑️ Notificación eliminada: $deletedId');
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error en DELETE realtime: $e');
              }
            }
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            print('📡 Estado del canal realtime: $status');
            if (error != null) {
              print('❌ Error de suscripción: $error');
            }
          }
          
          // Si la suscripción fue exitosa
          if (status == 'SUBSCRIBED' || status.toString() == 'RealtimeSubscriptionStatus.subscribed') {
            if (kDebugMode) {
              print('✅ Canal realtime ACTIVO para usuario: $userId');
            }
          }
        });
    
    if (kDebugMode) {
      print('🔔 ✅ Suscripción realtime ACTIVADA para usuario: $userId');
    }
  }

  void _unsubscribeFromRealtime() {
    if (_channel != null) {
      SupabaseProvider.client.removeChannel(_channel!);
      _channel = null;
      _isSubscribed = false; // ✅ NUEVO: Resetear flag al desuscribirse
      if (kDebugMode) {
        print('🔌 Desuscrito del realtime');
      }
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
        _notifications[index] = _notifications[index].copyWith(isRead: true);
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
          _notifications[i] = _notifications[i].copyWith(isRead: true);
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
      final userId = SupabaseProvider.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseProvider.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      // Eliminar de la lista local
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();

      if (kDebugMode) {
        print('✅ Notificación eliminada: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error eliminando notificación: $e');
      }
    }
  }

  // Método privado para verificación (sin usar)
  Future<void> _verifyNotificationsInDB() async {
    try {
      final userId = SupabaseProvider.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await SupabaseProvider.client
          .from('notifications')
          .select('id, type, created_at')
          .eq('recipient_user_id', userId);

      if (kDebugMode) {
        print('📊 Total en BD: ${(response as List).length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error verificando BD: $e');
      }
    }
  }
}
