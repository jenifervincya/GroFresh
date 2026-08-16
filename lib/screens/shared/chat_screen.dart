import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../theme/app_theme.dart';
import 'call_button.dart';

class ChatScreen extends StatefulWidget {
  final ChatThread thread;
  const ChatScreen({super.key, required this.thread});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final msgs = await ApiService.instance.fetchMessages(widget.thread.batchId);
      if (mounted) setState(() => _messages = msgs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load chat: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      final myId = AuthSession.instance.userId ?? 'me';
      final msg = await ApiService.instance.sendMessage(widget.thread.batchId, myId, text);
      if (mounted) {
        setState(() => _messages = [..._messages, msg]);
        await Future.delayed(const Duration(milliseconds: 50));
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message failed: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = AuthSession.instance.userId ?? 'me';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.thread.otherPartyName),
        actions: [
          if (widget.thread.otherPartyPhone != null)
            CallIconButton(phoneNumber: widget.thread.otherPartyPhone!),
        ],
      ),
      body: Column(
        children: [
          if (ApiService.instance.isDevMode)
            Container(
              width: double.infinity,
              color: AppColors.accentSoft,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Text(
                'DEV MODE — messages are local only, not sent to a real backend',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Say hello 👋', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isMe = m.senderId == myId;
                          return _Bubble(message: m, isMe: isMe);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Type a message'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.text, style: TextStyle(color: isMe ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 3),
            Text(
              _formatTime(message.sentAt),
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}