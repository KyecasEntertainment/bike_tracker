import 'package:flutter/material.dart';

/// Shared page heading for the dashboard's secondary screens.
class DashboardPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final Widget? action;

  const DashboardPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                DashboardIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else
                Semantics(
                  label: 'Bike Tracker',
                  image: true,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        'assets/bike_logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        color: colors.onPrimary,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              action ?? const SizedBox(height: 48),
            ],
          ),
          const SizedBox(height: 28),
          Text(title,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              )),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              )),
        ],
      ),
    );
  }
}

class DashboardIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const DashboardIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 23),
      style: IconButton.styleFrom(
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
      ),
    );
  }
}

/// An outlined surface with the same accent and fill as the home cards.
class DashboardSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  const DashboardSurface({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor ?? colors.primary, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
