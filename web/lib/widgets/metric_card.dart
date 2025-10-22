import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primaryContainer;
    final textColor = theme.colorScheme.onPrimaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: textColor,
              size: 32,
            ),
          if (icon != null) const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: textColor.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor.withOpacity(0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
