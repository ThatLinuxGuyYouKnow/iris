import 'package:flutter/material.dart';
import 'package:iris/themes/theme.dart';

class OpenCameraView extends StatelessWidget {
  final Function()? onButtonPressed;
  final IconData icon;
  final String label;
  const OpenCameraView({
    super.key,
    required this.onButtonPressed,
    this.icon = Icons.camera_alt,
    this.label = 'Use Camera',
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onButtonPressed != null;
    return InkWell(
      onTap: onButtonPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 250,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kDivider.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: kTextPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kPrimaryAccent, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(
                      color: kPrimaryAccent,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
