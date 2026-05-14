import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../analytics/analytics.dart';

enum ChatMode { buyer, seller }

class ChatScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String sellerName;
  final int? sellerId;
  final int? buyerId;
  final ChatMode mode;

  const ChatScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.sellerName,
    required this.sellerId,
    this.buyerId,
    this.mode = ChatMode.buyer,
  });

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  bool firstMessageSent = false;

  Dio getDio() {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      throw Exception('User is not authenticated');
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://group-42-backend.vercel.app/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${authState.accessToken}',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('[CHAT_DIO] ${options.method} ${options.path}');
          return handler.next(options);
        },
        onError: (error, handler) {
          print('[CHAT_DIO] ERROR ${error.requestOptions.method} ${error.requestOptions.path}');
          print('[CHAT_DIO] status: ${error.response?.statusCode}');
          print('[CHAT_DIO] response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadMessages();
    });
  }

  Future<void> loadMessages() async {
    setState(() {
      loading = true;
    });

    try {
      final dio = getDio();

      late final Response response;

      if (widget.mode == ChatMode.seller) {
        if (widget.buyerId == null || widget.buyerId! <= 0) {
          throw Exception('Invalid buyer id');
        }

        response = await dio.get('/messages/thread/buyer/${widget.buyerId}');
      } else {
        if (widget.sellerId == null || widget.sellerId! <= 0) {
          throw Exception('Invalid seller id');
        }

        response = await dio.get('/messages/thread/seller/${widget.sellerId}');
      }

      final data = response.data;

      if (data is List) {
        setState(() {
          messages = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          messages = [];
          loading = false;
        });
      }

      scrollToBottom();
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load chat: $e')),
      );
    }
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
    });

    try {
      final dio = getDio();

      if (widget.mode == ChatMode.seller) {
        if (widget.buyerId == null || widget.buyerId! <= 0) {
          throw Exception('Invalid buyer id');
        }

        await dio.post(
          '/messages/seller',
          data: {
            'buyer_id': widget.buyerId,
            'content': text,
          },
        );
      } else {
        if (widget.sellerId == null || widget.sellerId! <= 0) {
          throw Exception('Invalid seller id');
        }

        await dio.post(
          '/messages/buyer',
          data: {
            'seller_id': widget.sellerId,
            'content': text,
          },
        );
      }

      final authState = context.read<AuthBloc>().state;

      if (!firstMessageSent && authState is AuthAuthenticated) {
        context.read<AnalyticsBloc>().add(
          TrackBusinessEvent(
            eventName: 'chat_started',
            listingId: widget.productId,
            buyerUserId: widget.mode == ChatMode.buyer
                ? authState.user.id
                : widget.buyerId,
            metadata: {
              'source': 'chat_screen',
              'mode': widget.mode.name,
              'product_id': widget.productId,
              'product_name': widget.productName,
              'seller_id': widget.sellerId,
              'buyer_id': widget.buyerId,
              'other_name': widget.sellerName,
            },
          ),
        );

        firstMessageSent = true;
      }

      controller.clear();
      await loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool isMyMessage(Map<String, dynamic> message) {
    final sentBy = message['sent_by'];

    if (widget.mode == ChatMode.seller) {
      return sentBy == 'seller';
    }

    return sentBy == 'buyer';
  }

  String messageText(Map<String, dynamic> message) {
    return (message['content'] ?? '').toString();
  }

  String messageTime(Map<String, dynamic> message) {
    final raw = message['sent_at'];
    if (raw == null) return '';

    try {
      final date = DateTime.parse(raw.toString()).toLocal();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  Widget quickMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          controller.text = text;
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.productName.trim().isEmpty
        ? 'Chat'
        : widget.productName;

    final subtitle = widget.mode == ChatMode.seller
        ? 'Buyer: ${widget.sellerName}'
        : 'Seller: ${widget.sellerName}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: loadMessages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final mine = isMyMessage(msg);

                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: mine
                          ? AppColors.primaryBlue
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: mine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          messageText(msg),
                          style: TextStyle(
                            color: mine
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          messageTime(msg),
                          style: TextStyle(
                            fontSize: 10,
                            color: mine
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                quickMessage('Hola, ¿sigue disponible?'),
                quickMessage('Me interesa'),
                quickMessage('¿Podemos encontrarnos hoy?'),
                quickMessage('¿Cuál sería el precio final?'),
              ],
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
                      controller: controller,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: IconButton(
                      icon: sending
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: sending ? null : sendMessage,
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