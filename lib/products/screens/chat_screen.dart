import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import '../../analytics/analytics.dart';

class ChatScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String sellerName;

  const ChatScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.sellerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _firstMessageSent = false;

  @override
  void initState() {
    super.initState();
    _messages = ChatService.getMessages(widget.productId);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = Message(
      text: text,
      isMe: true,
    );

    final authState = context
        .read<AuthBloc>()
        .state;
    int? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    setState(() {
      _messages.add(message);
    });

    ChatService.sendMessage(
      widget.productId,
      widget.productName,
      widget.sellerName,
      message,
    );

    setState(() {
      _messages = ChatService.getMessages(widget.productId);
    });

    // BQ9 tracking
    if (!_firstMessageSent) {
      context.read<AnalyticsBloc>().add(
        TrackBusinessEvent(
          eventName: 'first_message_sent',
          listingId: widget.productId,
          buyerUserId: 1,
          metadata: {"source": "chat_screen"},
        ),
      );
      _firstMessageSent = true;
    }

    // TRACKING BQ6 - PRUEBA
    context.read<AnalyticsBloc>().add(
      TrackBQ6Event(
        eventName: 'seller_avg_response_time',
        userId: currentUserId ?? 1,
        sellerId: 1,
        avgResponseMinutes: 15,
        properties: {
          'source': 'chat_screen_test',
          'product_id': widget.productId,
          'seller_name': widget.sellerName,
        },
      ),
    );

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

  void _simulateSellerReply() {
    final reply = Message(
      text: "Sure, it's still available",
      isMe: false,
    );

    setState(() {
      _messages.add(reply);
    });

    ChatService.sendMessage(widget.productId, widget.productName, widget.sellerName, reply);
  }

  Widget _quickMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          _controller.text = text;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName),
            Text(
              "Seller: ${widget.sellerName}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No messages yet",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];

                return Align(
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,





                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isMe
                          ? AppColors.primaryBlue
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.status == MessageStatus.pending
                          ? "⏳ ${msg.text}"
                          : msg.text,
                      style: TextStyle(
                        color:
                        msg.isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _quickMessage("Hi!"),
                _quickMessage("Is this still available?"),
                _quickMessage("I'm interested"),
                _quickMessage("Can we meet today?"),
              ],
            ),
          ),

          // botón para simulator respuesta
          TextButton(
            onPressed: _simulateSellerReply,
            child: const Text("Simulate seller reply"),
          ),


          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () async {
                  setState(() {
                    ChatService.isOnline = !ChatService.isOnline;
                  });

                  if (ChatService.isOnline) {
                    await ChatService.retryPendingMessages();
                    setState(() {
                      _messages = ChatService.getMessages(widget.productId);
                    });
                  }
                },
                child: Text(
                  ChatService.isOnline ? "Go Offline" : "Go Online",
                ),
              ),
            ],
          ),


          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white, size: 20),
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