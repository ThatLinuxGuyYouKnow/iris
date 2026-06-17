import 'package:flutter/material.dart';
import 'package:iris/appBars/settings_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SettingsAppBar(),

      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Column(children: [SizedBox(height: 20)]),
      ),
    );
  }
}
