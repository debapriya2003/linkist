import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/link_provider.dart';
import '../utils/app_theme.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<LinkProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        final total = stats['total'] ?? 0;
        final favorites = stats['favorites'] ?? 0;
        final categories = stats['categories'] ?? 0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                AppTheme.accentColor.withOpacity(isDark ? 0.1 : 0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              _StatItem(
                value: total.toString(),
                label: 'Links',
                icon: Icons.link_rounded,
                color: AppTheme.primaryColor,
              ),
              _Divider(isDark: isDark),
              _StatItem(
                value: favorites.toString(),
                label: 'Favorites',
                icon: Icons.star_rounded,
                color: AppTheme.warningColor,
              ),
              _Divider(isDark: isDark),
              _StatItem(
                value: categories.toString(),
                label: 'Categories',
                icon: Icons.folder_rounded,
                color: AppTheme.accentColor,
              ),
              _Divider(isDark: isDark),
              _StatItem(
                value: provider.links.length.toString(),
                label: 'Showing',
                icon: Icons.visibility_rounded,
                color: AppTheme.successColor,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
    );
  }
}