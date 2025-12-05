import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../services/ai_chat_service.dart';
import '../../services/auth_service.dart';
import 'widgets/chat_bubble.dart';

class AIChatScreen extends StatefulWidget {
  final String? sessionId;
  final String? providerId;
  final String? businessId;

  const AIChatScreen({
    Key? key,
    this.sessionId,
    this.providerId,
    this.businessId,
  }) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AIChatService _chatService = AIChatService();
  String? _currentSessionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    if (_currentSessionId == null) {
      _initializeSession();
    }
  }

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        // Handle unauthenticated state if necessary
        return;
      }

      // Check for existing active session or create new
      // For MVP, always create new if not provided
      final sessionId = await _chatService.createSession(
        userId: userId,
        providerId: widget.providerId,
        businessId: widget.businessId,
      );

      setState(() {
        _currentSessionId = sessionId;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentSessionId == null) return;

    _messageController.clear();

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) return;

      await _chatService.sendMessage(
        sessionId: _currentSessionId!,
        userId: userId,
        content: content,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aiuda Assistant'),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentSessionId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<ChatMessageModel>>(
                    stream: _chatService.messagesStream(_currentSessionId!),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!;

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'How can I help you today?',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return ChatBubble(message: message);
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.auto_awesome,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.5),
                            size: 20,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(
                                  fontSize:
                                      16.0), // WhatsApp standard input size
                              decoration: const InputDecoration(
                                hintText: 'Ask Aiuda...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                isDense: true,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.arrow_upward_rounded),
                      color: Colors.white,
                      tooltip: 'Send',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
