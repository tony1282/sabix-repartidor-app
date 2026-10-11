import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/providers/delivery_provider.dart';
import '../../../domain/entities/order_entity.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/responsive_content.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadAvailableOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Pedidos disponibles'),
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
            tooltip: 'Regresar a Inicio',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () =>
                  context.read<DeliveryProvider>().loadAvailableOrders(),
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: Consumer<DeliveryProvider>(
          builder: (context, provider, _) {
            if (provider.hasActiveOrder) {
              return ResponsiveContent(
                maxWidth: 520,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: FadeSlideIn(
                  child: _ActiveOrderState(
                    onViewOrder: () => context.go('/deliveries'),
                  ),
                ),
              );
            }

            if (provider.isLoading) {
              return const LoadingWidget(message: 'Buscando pedidos...');
            }

            if (provider.errorMessage != null) {
              return ResponsiveContent(
                maxWidth: 520,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: CustomErrorWidget(
                  message: provider.errorMessage!,
                  onRetry: () => provider.loadAvailableOrders(),
                ),
              );
            }

            if (provider.availableOrders.isEmpty) {
              return const ResponsiveContent(
                maxWidth: 520,
                alignment: Alignment.center,
                padding: EdgeInsets.all(24),
                child: FadeSlideIn(child: _EmptyOrdersState()),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadAvailableOrders(),
              color: AppColors.primary,
              child: ResponsiveContent(
                maxWidth: 780,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: provider.availableOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = provider.availableOrders[index];
                    return FadeSlideIn(
                      duration: Duration(
                        milliseconds: 300 + (index.clamp(0, 4) * 60),
                      ),
                      child: _AvailableOrderCard(order: order),
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
}

class _ActiveOrderState extends StatelessWidget {
  final VoidCallback onViewOrder;

  const _ActiveOrderState({required this.onViewOrder});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.info.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              size: 40,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Ya tienes un pedido en curso',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Completa tu entrega actual antes de aceptar otro pedido.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewOrder,
              icon: const Icon(Icons.route_rounded),
              label: const Text('Ver mi pedido activo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

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
              Icons.inbox_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No hay pedidos disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando un restaurante tenga un pedido listo para entrega aparecera aqui.',
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

class _AvailableOrderCard extends StatelessWidget {
  final OrderEntity order;

  const _AvailableOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.go('/delivery/${order.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.primary,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${order.id}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Listo para recoger',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Disponible',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (order.restaurantName != null)
                _InfoRow(
                  icon: Icons.storefront_rounded,
                  text: order.restaurantName!,
                ),
              if (order.clientName != null)
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: 'Cliente: ${order.clientName}',
                ),
              if (order.deliveryAddress != null)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: order.deliveryAddress!,
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total del pedido',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
