import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/chat_provider.dart';
import 'chat_room_screen.dart';

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
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(child: Text(provider.error!))
          : RefreshIndicator(
              onRefresh: provider.loadConversations,
              child: provider.conversations.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No tienes conversaciones')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: provider.conversations.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = provider.conversations[i];
                        return ListTile(
                          leading: CircleAvatar(child: Text('#${c.orderId}')),
                          title: Text('Pedido #${c.orderId}'),
                          subtitle: Text(
                            c.lastMessage?.content ?? 'Sin mensajes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: c.unreadCount > 0
                              ? CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    '${c.unreadCount}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  conversationId: c.id,
                                  orderId: c.orderId,
                                ),
                              ),
                            );
                            if (context.mounted) {
                              provider.loadConversations();
                            }
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
