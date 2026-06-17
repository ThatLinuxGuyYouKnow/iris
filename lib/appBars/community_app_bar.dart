import 'package:flutter/material.dart';

class CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommunityAppBar({super.key});

  static const double _height = 100;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _height,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Material(
                color: Colors.blue,
                elevation: 4,
                shadowColor: Colors.blue.withValues(alpha: 0.4),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
      title: const Text(
        'Community',
        style: TextStyle(fontSize: 25, color: Colors.blue),
      ),
    );
  }
}
