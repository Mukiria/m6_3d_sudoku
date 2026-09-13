import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.elevation = 1,
    this.color,
    this.borderColor,
    this.borderRadius = 16,
    this.onTap,
    this.inkColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? inkColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: inkColor ?? colorScheme.primary.withValues(alpha: 0.1),
        highlightColor:
            inkColor?.withValues(alpha: 0.05) ??
            colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(padding: padding, child: child),
      ),
    );

    // A caller-supplied color/border (a semantic error card, say) keeps the
    // existing solid Card look rather than being overridden by glass — glass
    // changes the container's material, not a card's deliberate semantics.
    if (color != null || borderColor != null) {
      return Card(
        elevation: elevation,
        margin: margin,
        color: color ?? colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: borderColor ?? colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: content,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GlassSurface(
        cornerRadius: borderRadius,
        elevatedShadow: elevation > 0,
        child: content,
      ),
    );
  }
}

class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.trend,
    this.trendIsPositive,
    this.onTap,
  });

  final String title;
  final String value;
  final Widget? icon;
  final Color? iconColor;
  final String? trend;
  final bool? trendIsPositive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extension = theme.extension<AppThemeExtension>()!;

    return AppCard(
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? colorScheme.primary).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      color: iconColor ?? colorScheme.primary,
                      size: 20,
                    ),
                    child: icon!,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trendIsPositive == true
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 14,
                  color:
                      trendIsPositive == true
                          ? Colors.green
                          : (trendIsPositive == false
                              ? Colors.red
                              : colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 4),
                Text(
                  trend!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        trendIsPositive == true
                            ? Colors.green
                            : (trendIsPositive == false
                                ? Colors.red
                                : colorScheme.onSurfaceVariant),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
