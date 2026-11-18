
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFF5267D8).withOpacity(0.12),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(
            Icons.home_rounded,
            color: Color(0xFF5267D8),
          ),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(
            Icons.receipt_long_rounded,
            color: Color(0xFF5267D8),
          ),
          label: 'Transaksi',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(
            Icons.bar_chart_rounded,
            color: Color(0xFF5267D8),
          ),
          label: 'Statistik',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(
            Icons.person_rounded,
            color: Color(0xFF5267D8),
          ),
          label: 'Profil',
        ),
      ],
    );
  }
}
