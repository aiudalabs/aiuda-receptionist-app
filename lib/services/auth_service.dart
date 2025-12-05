import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // SMS/Phone verification state
  String? _verificationId;
  int? _resendToken;
  String? _phoneNumber;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle({
    required Function(String) onError,
  }) async {
    try {
      developer.log('🚀 Starting Google authentication...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('❌ User cancelled Google login');
        onError('Login cancelled');
        return null;
      }

      developer.log('✅ Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        developer.log('❌ Could not obtain Google tokens');
        onError('Error obtaining Google credentials');
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      developer.log('🔐 Google credentials created successfully');

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      developer
          .log('🎉 Firebase login successful: ${userCredential.user?.uid}');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('❌ Firebase Auth error: ${e.code} - ${e.message}');

      String errorMessage = 'Google authentication error';

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with this email using a different method';
          break;
        case 'invalid-credential':
          errorMessage = 'Google credentials are invalid';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google authentication is not enabled';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'network-request-failed':
          errorMessage = 'Connection error. Check your internet';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }

      onError(errorMessage);
      return null;
    } catch (e) {
      developer.log('❌ General Google Sign-In error: $e');
      onError('Unexpected error during authentication');
      return null;
    }
  }

  // Send phone verification code
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
    required Function() onVerificationCompleted,
  }) async {
    try {
      _verificationId = null;
      _resendToken = null;
      _phoneNumber = formatPhoneNumber(phoneNumber);

      developer.log('Starting verification for: $_phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            developer.log('Verification completed automatically');
            UserCredential result =
                await _auth.signInWithCredential(credential);
            developer.log('Auto-login successful for: ${result.user?.uid}');
            onVerificationCompleted();
          } catch (e) {
            developer.log('Error in automatic verification: $e');
            onVerificationFailed('Error in automatic verification: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log('Verification failed: ${e.code} - ${e.message}');
          String errorMessage = 'Verification error';

          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Try again in 24 hours';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Try again later';
              break;
            case 'missing-phone-number':
              errorMessage = 'Phone number is required';
              break;
            case 'network-request-failed':
              errorMessage = 'Connection error. Check your internet';
              break;
            default:
              errorMessage = e.message ?? 'Verification error. Code: ${e.code}';
          }

          onVerificationFailed(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log('Code sent successfully');
          developer.log('VerificationId: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent('SMS code sent to $_phoneNumber');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          developer
              .log('Auto-retrieval timeout. VerificationId: $verificationId');
          if (_verificationId == null || _verificationId!.isEmpty) {
            _verificationId = verificationId;
          }
        },
        timeout: const Duration(seconds: 120),
      );
    } catch (e) {
      developer.log('General error sending code: $e');
      onVerificationFailed('Unexpected error sending code: $e');
    }
  }

  // Verify OTP code
  Future<UserCredential?> verifyOTP({
    required String otp,
    required Function(String) onError,
  }) async {
    try {
      developer.log('Attempting to verify OTP: $otp');
      developer.log('VerificationId available: $_verificationId');

      if (_verificationId == null || _verificationId!.isEmpty) {
        developer.log('Error: Verification ID not found');
        onError('Verification ID not found. Please request a new code.');
        return null;
      }

      if (otp.isEmpty || otp.length != 6) {
        onError('Please enter a valid 6-digit code');
        return null;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      developer.log('Attempting to login with credential');
      UserCredential result = await _auth.signInWithCredential(credential);
      developer.log('Login successful for user: ${result.user?.uid}');

      return result;
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase Auth error: ${e.code} - ${e.message}');
      String errorMessage = 'Verification error';

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Incorrect verification code';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID. Request a new code';
          break;
        case 'session-expired':
          errorMessage = 'Session expired. Request a new code';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Try again later';
          break;
        default:
          errorMessage = e.message ?? 'Incorrect or expired code';
      }

      onError(errorMessage);
      return null;
    } catch (e) {
      developer.log('General error verifying OTP: $e');
      onError('Unexpected error. Try again');
      return null;
    }
  }

  // Resend verification code
  Future<void> resendVerificationCode({
    required Function(String) onCodeSent,
    required Function(String) onVerificationFailed,
  }) async {
    if (_phoneNumber == null) {
      onVerificationFailed('Phone number not available');
      return;
    }

    await sendPhoneVerification(
      phoneNumber: _phoneNumber!,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: () {},
    );
  }

  // Clear verification state
  void clearVerificationState() {
    _verificationId = null;
    _resendToken = null;
    _phoneNumber = null;
  }

  // Format phone number (US format for now, adjust as needed)
  String formatPhoneNumber(String phoneNumber) {
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If it starts with country code, add +
    if (phoneNumber.startsWith('1') && phoneNumber.length == 11) {
      return '+$phoneNumber';
    } else if (phoneNumber.length == 10) {
      return '+1$phoneNumber'; // Default to US
    }

    // If already has +, keep it
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    }

    return '+$phoneNumber';
  }

  // Sign out (including Google)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      developer.log('Error signing out: $e');
      await _auth.signOut();
    }
  }

  // Create user profile in Firestore
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String businessName,
    required String timezone,
    WorkMode? workMode,
    ProfessionalInfo? professionalInfo,
    List<String>? industries,
    String? phoneNumber,
  }) async {
    final user = UserModel(
      id: userId,
      email: email,
      businessName: businessName,
      timezone: timezone,
      createdAt: DateTime.now(),
      workMode: workMode ?? WorkMode.independent,
      professionalInfo: professionalInfo,
      industries: industries ?? [],
      phoneNumber: phoneNumber,
    );

    await _firestore.collection('users').doc(userId).set(user.toFirestore());
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update FCM token
  Future<void> updateFcmToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token])
      });
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
