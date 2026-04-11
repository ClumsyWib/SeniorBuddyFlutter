import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/buddy_service.dart';

class BuddyChatScreen extends StatefulWidget {
  final int? activeSeniorId;
  const BuddyChatScreen({Key? key, this.activeSeniorId}) : super(key: key);

  @override
  State<BuddyChatScreen> createState() => _BuddyChatScreenState();
}

class _BuddyChatScreenState extends State<BuddyChatScreen> with AutomaticKeepAliveClientMixin {
  final BuddyService _buddy = BuddyService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  List<Map<String, String>> _history = [];
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _isMuted = false;
  bool _sttAvailable = false;
  bool _greetingLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadGreeting();
  }

  Future<void> _initSpeech() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) => setState(() => _isListening = false),
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _loadGreeting() async {
    final greeting = await _buddy.fetchGreeting();
    if (mounted) {
      setState(() {
        _greetingLoading = false;
        _messages.add({'role': 'assistant', 'content': greeting});
      });
      _speak(greeting);
    }
  }

  Future<void> _speak(String text) async {
    if (_isMuted) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  void _toggleListening() async {
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }
    if (!_sttAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available on this device.')),
      );
      return;
    }
    await _tts.stop();
    setState(() => _isListening = true);
    _stt.listen(
      onResult: (result) {
        _controller.text = result.recognizedWords;
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    await _tts.stop();
    await _stt.stop();
    setState(() {
      _isListening = false;
      _isLoading = true;
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
    });
    _scrollToBottom();

    final result = await _buddy.sendMessage(
      text, _history,
      activeSeniorId: widget.activeSeniorId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        final reply = result['reply'] as String;
        _history = result['history'];
        setState(() => _messages.add({'role': 'assistant', 'content': reply}));

        final actionResult = result['action_result'];
        if (actionResult != null) {
          setState(() => _messages.add({
            'role': 'action',
            'content': actionResult['message'] ?? '',
            'success': actionResult['success'].toString(),
            'type': actionResult['type']?.toString() ?? '',
          }));
        }
        _scrollToBottom();
        _speak(reply);
      } else {
        // Inline error bubble — no SnackBar
        setState(() => _messages.add({
          'role': 'error',
          'content': result['error'] ?? 'Something went wrong. Please try again.',
        }));
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

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 8),
            Text('Buddy'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: () async {
              await _tts.stop();
              setState(() => _isMuted = !_isMuted);
            },
            tooltip: _isMuted ? 'Unmute' : 'Mute',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0) + (_greetingLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Show typing indicator while greeting loads
                if (_greetingLoading && index == 0) return _buildTypingIndicator();
                final msgIndex = _greetingLoading ? index - 1 : index;
                if (msgIndex == _messages.length) return _buildTypingIndicator();
                final msg = _messages[msgIndex];
                switch (msg['role']) {
                  case 'action':
                    return _buildActionCard(
                      msg['content']!,
                      msg['success'] == 'true',
                      msg['type'] ?? '',
                    );
                  case 'error':
                    return _buildErrorBubble(msg['content']!);
                  default:
                    return _buildBubble(msg['content']!, msg['role'] == 'user');
                }
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        child: const Text('Buddy is thinking...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildActionCard(String text, bool success, String type) {
    final config = _actionConfig(type, success);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: config['bgColor'] as Color,
          border: Border.all(color: config['borderColor'] as Color, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (config['borderColor'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(config['icon'] as IconData, color: config['borderColor'] as Color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: config['borderColor'] as Color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: TextStyle(fontSize: 14, color: config['textColor'] as Color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _actionConfig(String type, bool success) {
    if (!success) {
      return {
        'icon': Icons.error_outline,
        'label': 'Action failed',
        'bgColor': Colors.red[50]!,
        'borderColor': Colors.red[400]!,
        'textColor': Colors.red[800]!,
      };
    }
    switch (type) {
      case 'create_appointment':
        return {
          'icon': Icons.calendar_today_rounded,
          'label': 'Appointment scheduled',
          'bgColor': Colors.blue[50]!,
          'borderColor': Colors.blue[400]!,
          'textColor': Colors.blue[900]!,
        };
      case 'create_medicine':
        return {
          'icon': Icons.medication_rounded,
          'label': 'Medicine added',
          'bgColor': Colors.teal[50]!,
          'borderColor': Colors.teal[400]!,
          'textColor': Colors.teal[900]!,
        };
      case 'sos':
        return {
          'icon': Icons.warning_amber_rounded,
          'label': 'SOS alert sent',
          'bgColor': Colors.orange[50]!,
          'borderColor': Colors.orange[600]!,
          'textColor': Colors.orange[900]!,
        };
      default:
        return {
          'icon': Icons.check_circle_outline,
          'label': 'Done',
          'bgColor': Colors.green[50]!,
          'borderColor': Colors.green[400]!,
          'textColor': Colors.green[900]!,
        };
    }
  }

  Widget _buildErrorBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: Radius.zero),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 15, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isListening ? Colors.red[100] : Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: _isListening ? 'Listening...' : 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}