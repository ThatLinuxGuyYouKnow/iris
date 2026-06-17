import 'package:flutter/material.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({super.key});

  static const double _height = 100;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _height,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SizedBox(
            width: 70,
            height: 70,
            child: Material(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.blue.withValues(alpha: 0.4),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(fontSize: 25, color: Colors.blue),
      ),
    );
  }
}
