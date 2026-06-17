import 'package:flutter/material.dart';
import 'package:iris/appBars/community_app_bar.dart';
import 'package:iris/appBars/default_app_bar.dart';
import 'package:iris/navbars/default_nav_bar.dart';
import 'package:iris/provider/screen_provider.dart';
import 'package:iris/screens/community_screen.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

  Widget _bodyForIndex(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return const SettingsScreen();
      case 2:
        return const CommunityScreen();
      default:
        return HomeScreen();
    }
  }

  Widget _appBarForIndex(int Index) {
    switch (Index) {
      case 0:
        return DefaultAppBar();

      case 1:
        return DefaultAppBar();

      case 2:
        return CommunityAppBar();

      default:
        return DefaultAppBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenProvider = context.watch<ScreenProvider>();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: _appBarForIndex(screenProvider.currentIndex),
      ),
      bottomNavigationBar: DefaultNavBar(
        currentIndex: screenProvider.currentIndex,
        onTap: (i) => screenProvider.selectScreen(i),
      ),
      body: _bodyForIndex(screenProvider.currentIndex),
    );
  }
}
