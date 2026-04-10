import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onAddLink;
  final VoidCallback? onClearFilters;

  const EmptyState({
    super.key,
    required this.hasFilters,
    required this.onAddLink,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.search_off_rounded : Icons.bookmark_add_rounded,
                size: 48,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'No results found' : 'No links saved yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters to find what you\'re looking for.'
                  : 'Start saving your favourite links.\nTap the + button to add your first one!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            if (hasFilters && onClearFilters != null)
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: onAddLink,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Link'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}