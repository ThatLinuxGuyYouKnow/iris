import 'package:flutter/material.dart';
import 'package:iris/themes/theme.dart';

class CommunityGuidelinesBanner extends StatelessWidget {
  const CommunityGuidelinesBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: kGlassDecoration(opacity: 0.05, borderRadius: 16).copyWith(
        color: kSecondaryAccent.withValues(alpha: 0.05),
        border: Border.all(
          color: kSecondaryAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: kSecondaryAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Guidelines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kSecondaryAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Visually impaired users depend on your guidance to navigate the school premises in difficult spots. Please ensure submissions are accurate.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
