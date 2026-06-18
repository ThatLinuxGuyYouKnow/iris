import 'package:flutter/material.dart';
import 'package:iris/themes/theme.dart';

class CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommunityAppBar({super.key});

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
          centerTitle: false,
          title: Text(
            'Community',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: kAccentGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryAccent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {}, // Handled elsewhere or add route
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
