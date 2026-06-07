import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Current route to determine index
    final String location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/nutrition')) {
      currentIndex = 1;
    }
    if (location.startsWith('/game')) {
      currentIndex = 2;
    }
    if (location.startsWith('/medical')) {
      currentIndex = 3;
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: child, // The router handles the actual screen switching
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4))
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              if (index == 0) {
                context.go('/home');
              } else if (index == 1) {
                context.go('/nutrition');
              } else if (index == 2) {
                context.go('/game');
              } else if (index == 3) {
                context.go('/medical');
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.indigo.shade600,
            unselectedItemColor: Colors.blueGrey.shade400,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_rounded),
                  activeIcon: Icon(Icons.favorite_rounded, size: 28),
                  label: 'Wellness'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.local_fire_department_rounded),
                  activeIcon:
                      Icon(Icons.local_fire_department_rounded, size: 28),
                  label: 'Fuel'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.sports_esports_rounded),
                  activeIcon: Icon(Icons.sports_esports_rounded, size: 28),
                  label: 'Avatar'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.medical_services_rounded),
                  activeIcon: Icon(Icons.medical_services_rounded, size: 28),
                  label: 'Doctor'),
            ],
          ),
        ),
      ),
    );
  }
}
