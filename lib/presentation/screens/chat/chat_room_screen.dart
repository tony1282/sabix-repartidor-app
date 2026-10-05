import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/chat_room_provider.dart';
import '../../../core/services/chat_socket_service.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final int orderId;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.orderId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _scrollController = ScrollController();
  late final ChatRoomProvider _room;

  @override
  void initState() {
    super.initState();
    _room = context.read<ChatRoomProvider>();
    _room.addListener(_onRoomChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _room.open(widget.conversationId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _room.removeListener(_onRoomChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRoomChanged() => _scrollToBottom();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<ChatRoomProvider>();

    final isClosed = room.conversation?.isActive == false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat · Pedido #${widget.orderId}'),
        actions: [
          if (room.connectionState == ChatSocketState.reconnecting ||
              room.connectionState == ChatSocketState.connecting)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'Solicitar soporte',
            onPressed: isClosed ? null : () => _showSupportSheet(context, room),
          ),
        ],
      ),
      body: Column(
        children: [
          if (room.typingUsernames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${room.typingUsernames.first} está escribiendo…',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Expanded(
            child: room.isLoading
                ? const Center(child: CircularProgressIndicator())
                : room.error != null
                ? Center(child: Text(room.error!))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: room.messages.length,
                    itemBuilder: (_, i) => MessageBubble(
                      message: room.messages[i],
                      onDelete: (id) => room.deleteMessage(id),
                    ),
                  ),
          ),
          ChatInput(
            enabled: !isClosed,
            onSend: (text) => room.send(text),
            onTyping: room.onUserTyping,
          ),
        ],
      ),
    );
  }

  void _showSupportSheet(BuildContext context, ChatRoomProvider room) {
    final controller = TextEditingController();
    String priority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Solicitar soporte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe el problema…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, setSt) => DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Baja')),
                  DropdownMenuItem(value: 'medium', child: Text('Media')),
                  DropdownMenuItem(value: 'high', child: Text('Alta')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                ],
                onChanged: (v) => setSt(() => priority = v ?? 'medium'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await room.requestSupport(
                  controller.text.trim(),
                  priority: priority,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enviar'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
