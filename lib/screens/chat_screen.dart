import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final int? helpRequestId;
  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.helpRequestId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Timer? _timer;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadMessages(silent: true);
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final result = await _api.getConversation(
      widget.otherUserId,
      helpRequestId: widget.helpRequestId,
    );
    if (mounted) {
      int oldLength = _messages.length;
      setState(() {
        _isLoading = false;
        if (result['success']) {
          List<dynamic> data = result['data'];

          // 🔥 CLIENT-SIDE ISOLATION: Filter by Help Request ID if provided
          if (widget.helpRequestId != null) {
            data = data.where((msg) {
              final id = msg['help_request'];
              // Strict filtering: Only show messages explicitly linked to this request.
              return id == widget.helpRequestId;
            }).toList();
          }

          _messages = data;
        }
      });
      // Scroll to bottom if new messages arrived
      if (result['success'] && _messages.length > oldLength) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();
    final result = await _api.sendMessage(
      widget.otherUserId,
      text,
      helpRequestId: widget.helpRequestId,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (result['success']) {
        _loadMessages(silent: true);
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send: ${result['error']}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.otherUserName}')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No messages yet',
                                style: TextStyle(color: Colors.grey)),
                            Text('Start chatting with ${widget.otherUserName}!',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          // Robust check for self-sent messages
                          dynamic senderVal = msg['sender'];
                          int senderId = (senderVal is Map)
                              ? senderVal['id']
                              : (senderVal as int? ?? 0);
                          bool isMe = senderId != widget.otherUserId;

                          // DEBUG LOG
                          print(
                              '💬 Rendering message: ${msg['message']} | senderId: $senderId | otherId: ${widget.otherUserId} | isMe: $isMe');

                          return _buildMessageBubble(msg['message'], isMe);
                        },
                      ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                  hintText: 'Type a message...', border: InputBorder.none),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.blue)),
        ],
      ),
    );
  }
}
