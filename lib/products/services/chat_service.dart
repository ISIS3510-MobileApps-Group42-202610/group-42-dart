import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class ChatService {
  static final ValueNotifier<List<ChatMessage>> chatsNotifier =
      ValueNotifier<List<ChatMessage>>([]);

  static List<ChatMessage> getChats() => chatsNotifier.value;

  static void addMessage(ChatMessage chat) {
    final currentChats = List<ChatMessage>.from(chatsNotifier.value);
    
    final index = currentChats.indexWhere((c) => c.productId == chat.productId);

    if (index != -1) {
      currentChats[index] = chat;
    } else {
      currentChats.add(chat);
    }
    
    chatsNotifier.value = currentChats;
  }
}
