import 'package:flutter/material.dart';
import 'package:iris/appBars/settings_app_bar.dart';
import 'package:iris/themes/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: const SettingsAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Container(
              decoration: kGlassDecoration(),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up, color: kPrimaryAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Voice settings coming soon',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
