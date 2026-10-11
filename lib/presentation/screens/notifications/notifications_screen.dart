import '../../routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/error_widget.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_content.dart';
import '../../../core/config/app_colors.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../core/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotificationProvider>();
      await provider.clearCache();
      await provider.loadNotifications(refresh: true);
      await provider.loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(AppRouter.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Notificaciones'),
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(AppRouter.home),
            tooltip: 'Regresar a Inicio',
          ),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.unreadCount == 0) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.done_all_rounded),
                  onPressed: () => _markAllAsRead(context),
                  tooltip: 'Marcar todas como leídas',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                final provider = context.read<NotificationProvider>();
                provider.loadNotifications(refresh: true);
                provider.loadUnreadCount();
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return const LoadingWidget(message: 'Cargando notificaciones...');
            }

            if (provider.errorMessage != null) {
              return CustomErrorWidget(
                message: provider.errorMessage!,
                onRetry: () {
                  provider.loadNotifications(refresh: true);
                  provider.loadUnreadCount();
                },
              );
            }

            if (provider.notifications.isEmpty) {
              return const ResponsiveContent(
                maxWidth: 520,
                alignment: Alignment.center,
                padding: EdgeInsets.all(24),
                child: FadeSlideIn(
                  child: _EmptyNotificationsState(),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                provider.loadNotifications(refresh: true);
                provider.loadUnreadCount();
              },
              child: ResponsiveContent(
                maxWidth: 780,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: provider.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = provider.notifications[index];
                    return FadeSlideIn(
                      duration: Duration(
                        milliseconds:
                            300 + (index.clamp(0, 4).toInt() * 60),
                      ),
                      child: _NotificationCard(
                        notification: notification,
                        onTap: () =>
                            _handleNotificationTap(context, notification),
                        onDelete: () =>
                            _deleteNotification(context, notification.id),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================
  // LÓGICA DE NEGOCIO (SIN CAMBIOS)
  // ============================================
  void _handleNotificationTap(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    try {
      final provider = context.read<NotificationProvider>();
      await provider.markAsRead(notification.id);

      if (notification.orderId != null && notification.orderId! > 0) {
        if (context.mounted) {
          context.go('/delivery/${notification.orderId}');
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificación marcada como leída'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al manejar tap: $e');
    }
  }

  void _markAllAsRead(BuildContext context) async {
    try {
      final provider = context.read<NotificationProvider>();
      final success = await provider.markAllAsRead();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al marcar todas: $e');
    }
  }

  void _deleteNotification(BuildContext context, int notificationId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar notificación'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar esta notificación?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final provider = context.read<NotificationProvider>();
                  final success = await provider.deleteNotification(
                    notificationId,
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificación eliminada'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error al eliminar: $e');
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No tienes notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando haya novedades sobre tus pedidos apareceran aqui.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================
// TARJETA DE NOTIFICACIÓN
// ============================================
class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(notification.priority);
    final bool isUnread = !notification.isRead;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread ? priorityColor.withOpacity(0.28) : AppColors.borderLight,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: título + indicador + eliminar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Mensaje
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Chips de información
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Tipo de notificación
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        notification.typeDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    // Tiempo
                    if (notification.timeAgo != null &&
                        notification.timeAgo!.isNotEmpty)
                      Text(
                        notification.timeAgo!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    // Acción: Ver pedido
                    if (notification.orderId != null &&
                        notification.orderId! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ver pedido',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2: // Urgente
        return Colors.red;
      case 1: // Alta
        return Colors.orange;
      default: // Normal
        return AppColors.primary;
    }
  }
}
