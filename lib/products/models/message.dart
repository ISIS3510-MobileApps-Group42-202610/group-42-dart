enum MessageStatus { sent, pending }

class Message {
  final String text;
  final bool isMe;
  final MessageStatus status;

  Message({
    required this.text,
    required this.isMe,
    this.status = MessageStatus.sent,
  });

  Message copyWith({MessageStatus? status}) {
    return Message(
      text: text,
      isMe: isMe,
      status: status ?? this.status,
    );
  }
}