import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../client/client_home_screen.dart';

/// Decides which home screen to show based on user role
class RoleBasedHomeScreen extends StatelessWidget {
  const RoleBasedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getUserRole(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isProvider = snapshot.data == true;

        // TODO: Add proper role detection from UserModel
        // For now, show a bottom nav with both modes for testing
        return _AppShell(initialIsProvider: isProvider);
      },
    );
  }

  Future<bool> _getUserRole(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.getUserProfile(
      authService.currentUser?.uid ?? '',
    );

    // If user has businesses or works at businesses, they're a provider
    // Otherwise, they're a client
    return user != null &&
        (user.businessIds.isNotEmpty || user.industries.isNotEmpty);
  }
}

class _AppShell extends StatefulWidget {
  final bool initialIsProvider;

  const _AppShell({required this.initialIsProvider});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;
  late bool _isProvider;

  @override
  void initState() {
    super.initState();
    _isProvider = widget.initialIsProvider;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Client view
          const ClientHomeScreen(),
          // Provider view
          const DashboardScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Provider',
          ),
        ],
      ),
    );
  }
}
