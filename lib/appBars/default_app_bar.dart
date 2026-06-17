import 'package:flutter/material.dart';
import 'package:iris/screens/settings_screen.dart';

class DefaultAppBar extends StatelessWidget {
  const DefaultAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: AppBar(
        title: Text('Iris', style: TextStyle(color: Colors.blue, fontSize: 40)),
        toolbarHeight: 80,
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => const SettingsScreen(),
                ),
              );
            },
            icon: Icon(Icons.settings, size: 50, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
