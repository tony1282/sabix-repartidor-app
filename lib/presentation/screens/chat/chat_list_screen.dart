import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/providers/chat_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_content.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Mensajes'),
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<ChatProvider>().loadConversations(),
            ),
          ],
        ),
        body: Consumer<ChatProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const LoadingWidget(message: 'Cargando mensajes...');
            }

            if (provider.error != null) {
              return ResponsiveContent(
                maxWidth: 520,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: FadeSlideIn(
                  child: _ChatStateCard(
                    icon: Icons.error_outline_rounded,
                    iconColor: AppColors.error,
                    title: 'No pudimos cargar tus mensajes',
                    subtitle: provider.error!,
                    action: ElevatedButton.icon(
                      onPressed: provider.loadConversations,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ),
                ),
              );
            }

            if (provider.conversations.isEmpty) {
              return const ResponsiveContent(
                maxWidth: 520,
                alignment: Alignment.center,
                padding: EdgeInsets.all(24),
                child: FadeSlideIn(
                  child: _ChatStateCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: AppColors.primary,
                    title: 'Sin conversaciones',
                    subtitle: 'Los chats de tus pedidos apareceran aqui.',
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: provider.loadConversations,
              color: AppColors.primary,
              child: ResponsiveContent(
                maxWidth: 780,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: provider.conversations.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 72,
                  color: AppColors.border,
                ),
                itemBuilder: (_, i) {
                  final c = provider.conversations[i];
                  return FadeSlideIn(
                    duration: Duration(
                      milliseconds: 300 + (i.clamp(0, 4).toInt() * 60),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#${c.orderId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Pedido #${c.orderId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      c.lastMessage?.content ?? 'Sin mensajes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: c.unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${c.unreadCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                    onTap: () => context.go('/chat/${c.id}/${c.orderId}'),
                  ),
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
}


class _ChatStateCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? action;

  const _ChatStateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.action,
  });

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
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: action!),
          ],
        ],
      ),
    );
  }
}
