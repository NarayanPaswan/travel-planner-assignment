import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../trips/trips_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> _buildScreens(bool isAdmin) {
    return [
      const TripsScreen(),
      if (isAdmin) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _buildNavItems(bool isAdmin) {
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.flight), label: 'Trips'),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final screens = _buildScreens(isAdmin);
    final items = _buildNavItems(isAdmin);

    // Clamp index if tab count changed (e.g., admin -> user)
    if (_currentIndex >= screens.length) {
      _currentIndex = screens.length - 1;
    }

    return WillPopScope(
      onWillPop: () async {
        // If not on first tab, go to first tab (Trips)
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false; // prevent app from exiting
        }
        // Already on first tab: keep app open (do not exit)
        return false;
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: items,
        ),
      ),
    );
  }
}
