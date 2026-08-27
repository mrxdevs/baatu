class ChatMessageModel {
  final String id;
  final String role; // 'user' or 'model'
  final String content;
  final DateTime timestamp;
  final String? suggestionCorrection; // Optional grammar tip/correction

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.suggestionCorrection,
  });

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'suggestionCorrection': suggestionCorrection,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] ?? 'model',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      suggestionCorrection: json['suggestionCorrection'],
    );
  }
}

class ChatSessionModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userLevel;
  final List<ChatMessageModel> messages;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.userLevel = 'Intermediate',
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userLevel': userLevel,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    var rawMessages = json['messages'] as List<dynamic>? ?? [];
    List<ChatMessageModel> msgs = rawMessages
        .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return ChatSessionModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'English Practice Session',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      userLevel: json['userLevel'] ?? 'Intermediate',
      messages: msgs,
    );
  }
}
