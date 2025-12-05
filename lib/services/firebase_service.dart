import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Collection references
  static CollectionReference get usersCollection =>
      firestore.collection('users');
  static CollectionReference get servicesCollection =>
      firestore.collection('services');
  static CollectionReference get appointmentsCollection =>
      firestore.collection('appointments');
  static CollectionReference get messagesCollection =>
      firestore.collection('messages');
  static CollectionReference get leadsCollection =>
      firestore.collection('leads');
}
