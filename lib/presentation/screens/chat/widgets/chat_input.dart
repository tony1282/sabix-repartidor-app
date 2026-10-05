import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final void Function(String text) onSend;
  final void Function(String text)? onTyping;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onTyping,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    if (!widget.enabled) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                minLines: 1,
                maxLines: 4,
                enabled: widget.enabled,
                textInputAction: TextInputAction.send,
                onChanged: widget.onTyping,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: widget.enabled
                      ? 'Escribe un mensaje…'
                      : 'Conversación cerrada',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: widget.enabled
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: widget.enabled ? _send : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
