import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/navigation_provider.dart';
import 'views/recommendation_view.dart';
import 'views/collection_view.dart';
import 'views/profile_view.dart';
import 'views/settings_view.dart';
import 'utils/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '寻味',
      theme: AppTheme.theme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: Consumer<NavigationProvider>(
        builder: (context, navigationProvider, _) {
          return Scaffold(
            body: IndexedStack(
              index: navigationProvider.currentIndex,
              children: const [
                RecommendationView(),
                CollectionView(),
                ProfileView(),
                SettingsView(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: navigationProvider.currentIndex,
              onTap: (index) => navigationProvider.setIndex(index),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.recommend),
                  label: '推荐',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark),
                  label: '收藏',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: '我的',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: '设置',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
