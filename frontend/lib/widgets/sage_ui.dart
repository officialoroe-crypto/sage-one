import 'package:flutter/material.dart';
import '../theme/sage_theme.dart';

class SagePanel extends StatelessWidget {
  const SagePanel({required this.child, super.key, this.padding = const EdgeInsets.all(16), this.radius = SageTheme.radiusMedium, this.borderColor, this.backgroundColor, this.gradient});
  final Widget child; final EdgeInsetsGeometry padding; final double radius; final Color? borderColor; final Color? backgroundColor; final Gradient? gradient;
  @override Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null ? (backgroundColor ?? SageTheme.panelGlass) : null,
      gradient: gradient, borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? SageTheme.outline),
      boxShadow: const [BoxShadow(color: Color(0x18005C9C), blurRadius: 24, spreadRadius: -8, offset: Offset(0, 8))],
    ),
    child: child,
  );
}

class SageSectionHeading extends StatelessWidget {
  const SageSectionHeading({required this.title, super.key, this.subtitle, this.trailing});
  final String title; final String? subtitle; final Widget? trailing;
  @override Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: SageTheme.headingStyle),
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: const TextStyle(color: SageTheme.textSecondary, fontSize: 11))],
      ])),
      ?trailing,
    ],
  );
}

class SageStatusDot extends StatelessWidget {
  const SageStatusDot({super.key, this.color = SageTheme.success, this.size = 7});
  final Color color; final double size;
  @override Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: .55), blurRadius: 8)]),
  );
}

class SagePrimaryButton extends StatelessWidget {
  const SagePrimaryButton({required this.label, required this.onPressed, super.key, this.icon, this.expanded = false});
  final String label; final VoidCallback? onPressed; final IconData? icon; final bool expanded;
  @override Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 17),
      label: Text(label),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}