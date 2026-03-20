import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../../analytics/analytics.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class ChatScreen extends StatefulWidget {
  final String productId;
  final String sellerName;

  const ChatScreen({
    super.key,
    required this.productId,
    required this.sellerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<String> _conversationMessages = [];
  bool _firstMessageSent = false;

  @override
  void initState() {
    super.initState();
    final existingChat = ChatService.getChats().cast<ChatMessage?>().firstWhere(
          (c) => c?.productId == widget.productId,
          orElse: () => null,
        );
    
    if (existingChat != null) {
      _conversationMessages.add(existingChat.lastMessage);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;


    final authState = context.read<AuthBloc>().state;
    int? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    setState(() {
      _conversationMessages.add(text);
    });

    ChatService.addMessage(
      ChatMessage(
        productId: widget.productId,
        sellerName: widget.sellerName,
        lastMessage: text,
      ),
    );

    // TRACKING BQ9
    if (!_firstMessageSent) {
      context.read<AnalyticsBloc>().add(
        TrackBusinessEvent(
          eventName: 'first_message_sent',
          listingId: widget.productId,
          buyerUserId: currentUserId,
          metadata: {"source": "chat_screen"},
        ),
      );
      _firstMessageSent = true;
    }

    _controller.clear();
    
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.sellerName),
            const Text(
              "Online",
              style: TextStyle(fontSize: 12, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversationMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("No messages yet", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversationMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _conversationMessages[index];
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(0),
                            ),
                          ),
                          child: Text(
                            msg,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Write a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
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
}
