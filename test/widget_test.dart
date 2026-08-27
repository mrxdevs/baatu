import 'package:flutter_test/flutter_test.dart';
import 'package:baatu/model/chat_message_model.dart';

void main() {
  test('ChatMessageModel serialization smoke test', () {
    final msg = ChatMessageModel(
      id: 'msg_123',
      role: 'user',
      content: 'Hello Nancy',
      timestamp: DateTime.now(),
    );

    final json = msg.toJson();
    final restored = ChatMessageModel.fromJson(json);

    expect(restored.id, 'msg_123');
    expect(restored.role, 'user');
    expect(restored.content, 'Hello Nancy');
    expect(restored.isUser, true);
  });

  test('ChatSessionModel serialization smoke test', () {
    final session = ChatSessionModel(
      id: 'session_1',
      title: 'Practice Session',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userLevel: 'Beginner',
      messages: [
        ChatMessageModel(
          id: '1',
          role: 'model',
          content: 'Hi!',
          timestamp: DateTime.now(),
        ),
      ],
    );

    final json = session.toJson();
    final restored = ChatSessionModel.fromJson(json);

    expect(restored.id, 'session_1');
    expect(restored.userLevel, 'Beginner');
    expect(restored.messages.length, 1);
  });
}
