import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/recent_scans_screen.dart';
import '../screens/vocabulary_screen.dart';
import 'app_routes.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.allowSelectedNavigation = false,
  });

  final int currentIndex;
  final bool allowSelectedNavigation;

  void _open(BuildContext context, int index) {
    if (index == currentIndex && !allowSelectedNavigation) return;

    final Widget screen = switch (index) {
      0 => const HomeScreen(),
      1 => const ProjectsScreen(),
      2 => const VocabularyScreen(),
      3 => const RecentScansScreen(),
      _ => const HomeScreen(),
    };

    Navigator.of(context).pushAndRemoveUntil(
      appRoute(screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _open(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: '企画',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: '単語帳',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: '最近',
          ),
        ],
      ),
    );
  }
}
