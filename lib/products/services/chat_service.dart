import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/message.dart';

class ChatService {
  static final ValueNotifier<List<ChatMessage>> chatsNotifier =
      ValueNotifier<List<ChatMessage>>([]);

  static List<ChatMessage> getChats() => chatsNotifier.value;

  static final Map<String, List<Message>> _chatMessages = {};
  static bool isOnline = true; // simulación

  static List<Message> getMessages(String productId) {
    return _chatMessages[productId] ?? [];
  }

  static void sendMessage(
      String productId,
      String productName,
      String sellerName,
      Message message,
      ) {
    final messages = _chatMessages[productId] ?? [];

    if (!isOnline) {
      messages.add(message.copyWith(status: MessageStatus.pending));
    } else {
      messages.add(message.copyWith(status: MessageStatus.sent));
    }

    _chatMessages[productId] = messages;

    _updateChatPreview(productId, productName, sellerName, message.text);
  }

  // Reintentar mensajes pendientes
  static Future<void> retryPendingMessages() async {
    for (var entry in _chatMessages.entries) {
      final messages = entry.value;

      for (int i = 0; i < messages.length; i++) {
        if (messages[i].status == MessageStatus.pending) {
          await Future.delayed(const Duration(milliseconds: 500));

          messages[i] =
              messages[i].copyWith(status: MessageStatus.sent);
        }
      }
    }
  }
  static void _updateChatPreview(
      String productId,
      String productName,
      String sellerName,
      String lastMessage,
      ) {
    final currentChats = List<ChatMessage>.from(chatsNotifier.value);

    final index =
    currentChats.indexWhere((c) => c.productId == productId);

    final updatedChat = ChatMessage(
      productId: productId,
      productName: productName,
      sellerName: sellerName,
      lastMessage: lastMessage,
    );

    if (index != -1) {
      currentChats[index] = updatedChat;
    } else {
      currentChats.add(updatedChat);
    }

    chatsNotifier.value = currentChats;
  }
}