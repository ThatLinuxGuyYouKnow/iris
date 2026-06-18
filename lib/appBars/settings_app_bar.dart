import 'package:flutter/material.dart';
import 'package:iris/themes/theme.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({super.key});

  static const double _height = 80;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Container(
        decoration: kGlassDecoration(opacity: 0.05, borderRadius: 0).copyWith(
          border: const Border(bottom: BorderSide(color: kDivider)),
        ),
        child: AppBar(
          toolbarHeight: _height,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Center(
              child: Container(
                decoration: kGlassDecoration(opacity: 0.1, borderRadius: 12),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: kTextPrimary),
                ),
              ),
            ),
          ),
          title: Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ),
    );
  }
}
