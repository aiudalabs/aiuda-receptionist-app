import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../profile/profile_preview_screen.dart';
import '../booking/service_selection_screen.dart';

/// Public profile for providers when viewed by clients
/// Reuses ProfilePreviewScreen with client-specific actions
class ProviderPublicProfileScreen extends StatelessWidget {
  final UserModel provider;

  const ProviderPublicProfileScreen({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProfilePreviewScreen(profile: provider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceSelectionScreen(provider: provider),
            ),
          );
        },
        icon: const Icon(Icons.calendar_month),
        label: const Text('Book Appointment'),
      ),
    );
  }
}
