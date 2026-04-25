import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/message.dart';

class ChatService {
  static final ValueNotifier<List<ChatMessage>> chatsNotifier =
      ValueNotifier<List<ChatMessage>>([]);

  static List<ChatMessage> getChats() => chatsNotifier.value;

  static final Map<String, List<Message>> _chatMessages = {};

  static List<Message> getMessages(String productId) {
    return _chatMessages[productId] ?? [];
  }

  static void sendMessage(String productId,
      String productName,
      String sellerName,
      Message message,
      ) {
    final messages = _chatMessages[productId] ?? [];
    messages.add(message);
    _chatMessages[productId] = messages;
    addMessage(
      ChatMessage(
        productId: productId,
        sellerName: sellerName,
        lastMessage: message.text, productName: '',
        ),
      chatsNotifier,
    );
    }
  }
  void addMessage(ChatMessage chat, dynamic chatsNotifier) {
    final currentChats = List<ChatMessage>.from(chatsNotifier.value);

    final index =
    currentChats.indexWhere((c) => c.productId == chat.productId);

    if (index != -1) {
      currentChats[index] = chat;
    } else {
      currentChats.add(chat);
    }

    chatsNotifier.value = currentChats;
  }
