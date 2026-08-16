class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };
}

/// A conversation thread tied to a specific batch (keeps chat scoped to a
/// transaction, consistent with the platform-mediated trust model rather
/// than an open-ended contact list).
class ChatThread {
  final String batchId;
  final String otherPartyId;
  final String otherPartyName;
  final String? otherPartyPhone; // for tap-to-dial only, never shown as a raw contact list

  ChatThread({
    required this.batchId,
    required this.otherPartyId,
    required this.otherPartyName,
    this.otherPartyPhone,
  });
}