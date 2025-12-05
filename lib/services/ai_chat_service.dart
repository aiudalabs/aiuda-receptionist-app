import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import 'firebase_service.dart';

class AIChatService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Create a new chat session
  Future<String> createSession({
    required String userId,
    String? providerId,
    String? businessId,
    String type = 'support',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final docRef = await _firestore.collection('chat_sessions').add({
        'userId': userId,
        'providerId': providerId,
        'businessId': businessId,
        'type': type,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('DEBUG: Chat session created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('ERROR creating chat session: $e');
      rethrow;
    }
  }

  /// Send a message (writes to Firestore, triggers Cloud Function)
  Future<void> sendMessage({
    required String sessionId,
    required String userId,
    required String content,
  }) async {
    try {
      await _firestore.collection('chat_messages').add({
        'sessionId': sessionId,
        'userId': userId,
        'role': 'user',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('DEBUG: Message sent to session: $sessionId');
    } catch (e) {
      print('ERROR sending message: $e');
      rethrow;
    }
  }

  /// Listen to messages in real-time
  Stream<List<ChatMessageModel>> messagesStream(String sessionId) {
    return _firestore
        .collection('chat_messages')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get chat history (one-time fetch)
  Future<List<ChatMessageModel>> getHistory(String sessionId) async {
    try {
      final snapshot = await _firestore
          .collection('chat_messages')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ERROR getting chat history: $e');
      return [];
    }
  }

  /// Get user's chat sessions
  Future<List<ChatSessionModel>> getUserSessions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chat_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => ChatSessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ERROR getting user sessions: $e');
      return [];
    }
  }

  /// Get session by ID
  Future<ChatSessionModel?> getSession(String sessionId) async {
    try {
      final doc =
          await _firestore.collection('chat_sessions').doc(sessionId).get();
      if (!doc.exists) return null;
      return ChatSessionModel.fromFirestore(doc);
    } catch (e) {
      print('ERROR getting session: $e');
      return null;
    }
  }

  /// Delete a session and its messages
  Future<void> deleteSession(String sessionId) async {
    try {
      // Delete all messages
      final messagesSnapshot = await _firestore
          .collection('chat_messages')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete session
      await _firestore.collection('chat_sessions').doc(sessionId).delete();

      print('DEBUG: Session deleted: $sessionId');
    } catch (e) {
      print('ERROR deleting session: $e');
      rethrow;
    }
  }
}
