import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sabix_repartidor_app/data/repositories/chat_repository_impl.dart'
    show ChatRepositoryImpl;
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../../core/config/app_colors.dart';
import '../../../domain/entities/order_entity.dart';
import '../../../core/providers/delivery_provider.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final int orderId;
  const DeliveryDetailScreen({super.key, required this.orderId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // ✅ Ir a pedidos asignados al presionar atrás físico
          context.go('/deliveries');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Detalle del Pedido'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            // ✅ Botón de retroceso → pedidos asignados
            onPressed: () => context.go('/deliveries'),
            tooltip: 'Volver a pedidos',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<DeliveryProvider>().loadOrderDetail(
                widget.orderId,
              ),
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: Consumer<DeliveryProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const LoadingWidget(message: 'Cargando detalle...');
            }

            if (provider.errorMessage != null) {
              return CustomErrorWidget(
                message: provider.errorMessage!,
                onRetry: () => provider.loadOrderDetail(widget.orderId),
              );
            }

            final order = provider.selectedOrder;
            if (order == null) {
              return const Center(child: Text('No se encontró el pedido'));
            }

            return _OrderDetailContent(order: order);
          },
        ),
      ),
    );
  }
}

// ============================================
// CONTENIDO PRINCIPAL DEL DETALLE
// ============================================
class _OrderDetailContent extends StatelessWidget {
  final OrderEntity order;
  const _OrderDetailContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [statusColor.withOpacity(0.18), AppColors.surface],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(order.status),
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pedido #${order.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 12),

            // ===== BOTÓN CHAT =====
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openChat(context, order.id),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat con el cliente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // Información básica del pedido
            Card(
              color: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(label: 'Pedido #', value: '${order.id}'),
                    if (order.restaurantName != null)
                      _InfoRow(
                        label: 'Restaurante',
                        value: order.restaurantName!,
                      ),
                    if (order.clientName != null)
                      _InfoRow(label: 'Cliente', value: order.clientName!),
                    if (order.deliveryAddress != null)
                      _InfoRow(
                        label: 'Dirección',
                        value: order.deliveryAddress!,
                      ),
                    if (order.estimatedDeliveryTime != null)
                      _InfoRow(
                        label: 'Tiempo estimado',
                        value: '${order.estimatedDeliveryTime} min',
                      ),
                    _InfoRow(
                      label: 'Total',
                      value: '\$${order.total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    if (order.isPaid)
                      const _InfoRow(label: 'Pago', value: 'Pagado'),
                    if (order.notes != null && order.notes!.isNotEmpty)
                      _InfoRow(label: 'Notas', value: order.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Productos
            if (order.items != null && order.items!.isNotEmpty) ...[
              const Text(
                'Productos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...order.items!.map((item) => _ItemCard(item: item)).toList(),
              const SizedBox(height: 16),
            ],

            // Botones de acción según estado
            if (order.status == 'pending' || order.status == 'ready')
              _ActionButtons(order: order),
            if (order.status == 'in_delivery') _DeliverButton(order: order),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'in_delivery':
        return Colors.blue;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'ready':
        return Icons.check_circle_outline;
      case 'in_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

// ============================================
// FILA DE INFORMACIÓN
// ============================================
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _InfoRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// TARJETA DE PRODUCTO
// ============================================
class _ItemCard extends StatelessWidget {
  final OrderItemEntity item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.selectedOptions != null &&
                    item.selectedOptions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item.selectedOptions!.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// BOTONES ACEPTAR / RECHAZAR
// ============================================
class _ActionButtons extends StatelessWidget {
  final OrderEntity order;
  const _ActionButtons({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(context),
                icon: const Icon(Icons.block_rounded),
                label: const Text('Rechazar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(context),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Aceptar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.28),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _acceptOrder(BuildContext context) async {
    final provider = context.read<DeliveryProvider>();
    final success = await provider.acceptOrder(order.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido aceptado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/deliveries');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al aceptar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rechazar entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Estás seguro de rechazar este pedido?'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                Navigator.pop(context);
                final provider = context.read<DeliveryProvider>();
                final success = await provider.rejectOrder(
                  order.id,
                  reason: reason.isNotEmpty ? reason : null,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido rechazado'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  context.go('/deliveries');
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Error'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Rechazar',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================
// BOTÓN "MARCAR COMO ENTREGADO"
// ============================================
class _DeliverButton extends StatelessWidget {
  final OrderEntity order;
  const _DeliverButton({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _markAsDelivered(context),
          icon: const Icon(Icons.local_shipping_rounded),
          label: const Text('Marcar como entregado'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            shadowColor: AppColors.success.withOpacity(0.28),
          ),
        ),
      ),
    );
  }

  void _markAsDelivered(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: const Text('¿Ya entregaste este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sí, entregar',
              style: TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final provider = context.read<DeliveryProvider>();
    final success = await provider.markAsDelivered(order.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido entregado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/deliveries');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al entregar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

Future<void> _openChat(BuildContext context, int orderId) async {
  try {
    final repo = context.read<ChatRepositoryImpl>();
    final conv = await repo.getConversationByOrder(orderId);
    if (!context.mounted) return;
    context.push('/chat/${conv.id}/$orderId');
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo abrir el chat: $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
