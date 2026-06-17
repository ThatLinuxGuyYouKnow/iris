import 'package:flutter/material.dart';

class DefaultNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DefaultNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
      ],
    );
  }
}
