import 'package:flutter/material.dart';
import 'package:iris/appBars/community_app_bar.dart';
import 'package:iris/appBars/default_app_bar.dart';
import 'package:iris/navbars/default_nav_bar.dart';
import 'package:iris/provider/screen_provider.dart';
import 'package:iris/screens/community_screen.dart';
import 'package:iris/screens/home_screen.dart';
import 'package:iris/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:iris/themes/theme.dart';

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

  Widget _bodyForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SettingsScreen();
      case 2:
        return const CommunityScreen();
      default:
        return const HomeScreen();
    }
  }

  PreferredSizeWidget _appBarForIndex(int index) {
    switch (index) {
      case 0:
        return const DefaultAppBar();
      case 1:
        // Reused layout from default or settings? Actually setting screen has its own appbar but let MasterScreen control it if possible, or we just return an empty size.
        // The original code returned DefaultAppBar() for settings and SettingsScreen had its own AppBar in scaffolding.
        // Wait, Home -> Default, Settings -> Default, Community -> CommunityAppBar.
        return const DefaultAppBar();
      case 2:
        return const CommunityAppBar();
      default:
        return const DefaultAppBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenProvider = context.watch<ScreenProvider>();
    return Scaffold(
      backgroundColor: kBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
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
