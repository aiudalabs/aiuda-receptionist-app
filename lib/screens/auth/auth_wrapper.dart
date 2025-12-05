import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../onboarding/onboarding_screen.dart';
import 'role_based_home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder(
            future: authService.getUserProfile(snapshot.data!.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If user profile exists, go to role-based home
              if (profileSnapshot.hasData && profileSnapshot.data != null) {
                return const RoleBasedHomeScreen();
              }

              // If no profile, go to onboarding
              return const OnboardingScreen();
            },
          );
        }

        // User is not signed in
        return const LoginScreen();
      },
    );
  }
}
