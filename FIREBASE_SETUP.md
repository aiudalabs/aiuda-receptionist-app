# Firebase Setup Instructions

## Prerequisites
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "Aiuda Receptionist"

## Setup Steps

### 1. Enable Firebase Authentication
- In Firebase Console, go to Authentication > Sign-in method
- Enable "Email/Password" provider

### 2. Create Firestore Database
- Go to Firestore Database
- Click "Create database"
- Start in **test mode** (we'll add security rules later)
- Choose a location close to your users

### 3. Enable Cloud Messaging
- Go to Project Settings > Cloud Messaging
- Enable Firebase Cloud Messaging API

### 4. Add Firebase to Flutter App

#### For Android:
1. In Firebase Console: Project Settings > Add app > Android
2. Register app with package name: `com.aiudalabs.aiuda_receptionist`
3. Download `google-services.json`
4. Place it in `android/app/`
5. Follow the Firebase setup instructions for Gradle configuration

#### For iOS:
1. In Firebase Console: Project Settings > Add app > iOS
2. Register app with bundle ID: `com.aiudalabs.aiudaReceptionist`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`
5. Follow the Firebase setup instructions for Xcode configuration

### 5. Initialize FlutterFire CLI (Recommended)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Run configuration
flutterfire configure
```

This will automatically:
- Create firebase_options.dart
- Configure all platforms
- Set up necessary files

### 6. Firestore Collections Structure

```
users/
  {userId}/
    - businessName: string
    - email: string
    - timezone: string
    - createdAt: timestamp
    - fcmTokens: array

services/
  {serviceId}/
    - userId: string
    - name: string
    - duration: number (minutes)
    - price: number (optional)
    - createdAt: timestamp

appointments/
  {appointmentId}/
    - userId: string
    - clientName: string
    - clientEmail: string (optional)
    - serviceId: string
    - datetime: timestamp
    - status: string (scheduled, completed, cancelled, no_show)
    - googleEventId: string
    - createdAt: timestamp

messages/
  {messageId}/
    - userId: string
    - role: string (user, assistant, system)
    - content: string
    - timestamp: timestamp
    - senderId: string

leads/
  {leadId}/
    - userId: string
    - clientName: string
    - lastMessage: string
    - status: string (new, contacted, scheduled, lost)
    - createdAt: timestamp
    - updatedAt: timestamp
```

## Security Rules (Add Later)

After testing, update Firestore security rules to:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /services/{serviceId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /appointments/{appointmentId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /messages/{messageId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /leads/{leadId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```
