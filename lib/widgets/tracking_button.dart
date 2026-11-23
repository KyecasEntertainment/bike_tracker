import 'package:flutter/material.dart';
import '../utils/app_color_theme.dart';

/// A styled button for tracking controls.
class TrackingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLarge;

  const TrackingButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    final buttonContent = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (isLarge) {
      final pressedColor = Theme.of(context).brightness == Brightness.light
          ? AppColorTheme.lightPrimaryPressed
          : AppColorTheme.primaryPressed;
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (color == AppColorTheme.primary &&
                  states.contains(WidgetState.pressed)) {
                return pressedColor;
              }
              if (color == Theme.of(context).colorScheme.primary &&
                  states.contains(WidgetState.pressed)) {
                return pressedColor;
              }
              return color;
            }),
          ),
          child: buttonContent,
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: buttonContent,
    );
  }
}
