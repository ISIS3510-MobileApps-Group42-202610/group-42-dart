import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversations"),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<ChatMessage>>(
        valueListenable: ChatService.chatsNotifier,
        builder: (context, chats, child) {
          if (chats.isEmpty) {
            return Center(
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
                    "No conversations yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Contact a seller to start a chat",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(
              indent: 70,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryBlue,
                  ),
                ),
                title: Text(
                  chat.sellerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        productId: chat.productId,
                        sellerName: chat.sellerName, productName: '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
