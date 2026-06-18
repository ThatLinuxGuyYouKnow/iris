import 'package:flutter/material.dart';
import 'package:iris/themes/theme.dart';

class CommunityMapTypeCard extends StatelessWidget {
  final String mapType;
  final IconData mapIcon;
  final int typeCount;
  final VoidCallback? onTap;

  const CommunityMapTypeCard({
    super.key,
    required this.mapType,
    required this.mapIcon,
    required this.typeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 130,
      padding: const EdgeInsets.all(16.0),
      decoration: kGlassDecoration(opacity: 0.05, borderRadius: 16).copyWith(
        border: Border.all(color: kDivider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: kAccentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimaryAccent.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(mapIcon, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            mapType,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$typeCount posts',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: card);
  }
}
