import 'package:flutter/material.dart';


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.sellerName}"),
      ),
      body: Column(
        children: [

          // MENSAJES
          const Expanded(
            child: Center(
              child: Text("No messages yet"),
            ),
          ),

          // INPUT
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Write a message...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // ahora solo limpia

                    _controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}