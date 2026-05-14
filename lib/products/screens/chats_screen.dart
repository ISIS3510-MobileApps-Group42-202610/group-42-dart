import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> conversations = [];

  Dio getDio() {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      throw Exception('User is not authenticated');
    }

    return Dio(
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
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadConversations();
    });
  }

  Future<void> loadConversations() async {
    setState(() {
      loading = true;
    });

    try {
      final dio = getDio();

      final buyerResponse = await dio.get('/messages/as-buyer');
      final sellerResponse = await dio.get('/messages/as-seller');

      final loaded = <Map<String, dynamic>>[];

      final buyerData = buyerResponse.data;
      if (buyerData is List) {
        for (final item in buyerData) {
          final message = Map<String, dynamic>.from(item as Map);
          final seller = message['seller'];

          if (seller is Map) {
            final sellerMap = Map<String, dynamic>.from(seller);
            final sellerUser = sellerMap['user'];

            String sellerName = 'Seller';

            if (sellerUser is Map) {
              final userMap = Map<String, dynamic>.from(sellerUser);
              final name = (userMap['name'] ?? '').toString();
              final lastName = (userMap['last_name'] ?? '').toString();
              sellerName = '$name $lastName'.trim();
              if (sellerName.isEmpty) sellerName = 'Seller';
            }

            loaded.add({
              'role': 'buyer',
              'sellerId': (sellerMap['id'] as num?)?.toInt() ?? 0,
              'buyerId': null,
              'otherName': sellerName,
              'lastMessage': (message['content'] ?? '').toString(),
              'sentAt': (message['sent_at'] ?? '').toString(),
            });
          }
        }
      }

      final sellerData = sellerResponse.data;
      if (sellerData is List) {
        for (final item in sellerData) {
          final message = Map<String, dynamic>.from(item as Map);
          final buyer = message['buyer'];

          String buyerName = 'Buyer';

          if (buyer is Map) {
            final buyerMap = Map<String, dynamic>.from(buyer);
            final name = (buyerMap['name'] ?? '').toString();
            final lastName = (buyerMap['last_name'] ?? '').toString();
            buyerName = '$name $lastName'.trim();
            if (buyerName.isEmpty) {
              buyerName = (buyerMap['email'] ?? 'Buyer').toString();
            }
          }

          loaded.add({
            'role': 'seller',
            'sellerId': null,
            'buyerId': (message['buyer_id'] as num?)?.toInt() ?? 0,
            'otherName': buyerName,
            'lastMessage': (message['content'] ?? '').toString(),
            'sentAt': (message['sent_at'] ?? '').toString(),
          });
        }
      }

      final unique = <String, Map<String, dynamic>>{};

      for (final chat in loaded) {
        final role = chat['role'].toString();
        final sellerId = chat['sellerId'];
        final buyerId = chat['buyerId'];
        final key = role == 'buyer'
            ? 'buyer_seller_$sellerId'
            : 'seller_buyer_$buyerId';

        if (!unique.containsKey(key)) {
          unique[key] = chat;
        }
      }

      final result = unique.values.toList()
        ..sort((a, b) {
          final aDate = a['sentAt'].toString();
          final bDate = b['sentAt'].toString();
          return bDate.compareTo(aDate);
        });

      setState(() {
        conversations = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load conversations: $e')),
      );
    }
  }

  String formatTime(String raw) {
    if (raw.isEmpty) return '';

    try {
      final date = DateTime.parse(raw).toLocal();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loadConversations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contact a seller to start a chat',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadConversations,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: conversations.length,
          separatorBuilder: (context, index) => const Divider(
            indent: 70,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final chat = conversations[index];
            final role = chat['role'].toString();
            final otherName = chat['otherName'].toString();
            final lastMessage = chat['lastMessage'].toString();
            final sentAt = chat['sentAt'].toString();

            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                AppColors.primaryBlue.withOpacity(0.1),
                child: Icon(
                  role == 'seller'
                      ? Icons.storefront
                      : Icons.person,
                  color: AppColors.primaryBlue,
                ),
              ),
              title: Text(
                otherName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${role == 'seller' ? 'As seller: ' : 'As buyer: '}$lastMessage',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatTime(sentAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      productId: '',
                      productName: 'Chat',
                      sellerName: otherName,
                      sellerId: chat['sellerId'] as int?,
                      buyerId: chat['buyerId'] as int?,
                      mode: role == 'seller'
                          ? ChatMode.seller
                          : ChatMode.buyer,
                    ),
                  ),
                );

                loadConversations();
              },
            );
          },
        ),
      ),
    );
  }
}