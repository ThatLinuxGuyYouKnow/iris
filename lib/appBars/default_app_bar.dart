import 'package:flutter/material.dart';

class DefaultAppBar extends StatelessWidget {
  const DefaultAppBar({super.key});

  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: AppBar(
        title: Text('Iris', style: TextStyle(color: Colors.blue, fontSize: 40)),
        toolbarHeight: 80,
        actions: [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.settings, size: 50, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
