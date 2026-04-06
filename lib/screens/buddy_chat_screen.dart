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

class _BuddyChatScreenState extends State<BuddyChatScreen> {
  final BuddyService _buddy = BuddyService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  List<Map<String, String>> _history = [];
  List<Map<String, String>> _messages = []; // for display: role + content
  bool _isLoading = false;
  bool _isListening = false;
  bool _isMuted = false;
  bool _sttAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
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

    final result = await _buddy.sendMessage(text,
     _history, activeSeniorId: widget.activeSeniorId);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        final reply = result['reply'] as String;
        _history = result['history'];
        setState(() => _messages.add({'role': 'assistant', 'content': reply}));
        final actionResult = result['action_result'];
        if (actionResult != null) {
          setState(() => _messages.add({
            'role': 'action',
            'content': actionResult['message'] ?? '',
            'success': actionResult['success'].toString(),
          }));
        }
        
        _scrollToBottom();
        _speak(reply);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Error')),
        );
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
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 36,
                          child: Text('B', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Hi! I\'m Buddy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Your personal care companion', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 24),
                        Text('Tap the mic or type to start talking!', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTypingIndicator();
                      final msg = _messages[index];
                      if (msg['role'] == 'action') return _buildActionCard(msg['content']!, msg['success'] == 'true');
                      return _buildBubble(msg['content']!, msg['role'] == 'user');
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
  Widget _buildActionCard(String text, bool success) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: success ? Colors.green[50] : Colors.red[50],
        border: Border.all(color: success ? Colors.green : Colors.red, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error_outline,
              color: success ? Colors.green : Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: success ? Colors.green[800] : Colors.red[800]))),
        ],
      ),
    ),
  );
}

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
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