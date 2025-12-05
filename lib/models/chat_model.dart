import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String sessionId;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<Map<String, dynamic>>? toolCalls;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.toolCalls,
    required this.timestamp,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessageModel(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      role: data['role'] ?? 'user',
      content: data['content'] ?? '',
      toolCalls: data['toolCalls'] != null
          ? List<Map<String, dynamic>>.from(data['toolCalls'])
          : null,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'toolCalls': toolCalls,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasToolCalls => toolCalls != null && toolCalls!.isNotEmpty;
}

class ChatSessionModel {
  final String id;
  final String userId;
  final String? providerId;
  final String? businessId;
  final String type; // 'support', 'booking', 'registration'
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSessionModel({
    required this.id,
    required this.userId,
    this.providerId,
    this.businessId,
    this.type = 'support',
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatSessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      providerId: data['providerId'],
      businessId: data['businessId'],
      type: data['type'] ?? 'support',
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'providerId': providerId,
      'businessId': businessId,
      'type': type,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
