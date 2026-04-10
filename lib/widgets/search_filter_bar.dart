import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/link_provider.dart';
import '../utils/app_theme.dart';

class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({super.key});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<LinkProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search links, tags, domains...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {});
                        provider.setSearchQuery(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort button
                  _SortButton(provider: provider, isDark: isDark),
                ],
              ),
            ),

            // Filter chips row
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                children: [
                  // Clear filters
                  if (provider.hasActiveFilters)
                    _FilterChip(
                      label: 'Clear all',
                      icon: Icons.clear_all_rounded,
                      isSelected: false,
                      color: AppTheme.dangerColor,
                      onTap: () {
                        _searchController.clear();
                        provider.clearFilters();
                      },
                    ),

                  // Favorites filter
                  _FilterChip(
                    label: 'Favorites',
                    icon: Icons.star_rounded,
                    isSelected: provider.showFavoritesOnly == true,
                    color: AppTheme.warningColor,
                    onTap: () => provider.setFavoritesOnly(
                      provider.showFavoritesOnly == true ? null : true,
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Category filters
                  ...provider.categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _FilterChip(
                          label: cat,
                          icon: AppTheme.categoryIcon(cat),
                          isSelected: provider.selectedCategory == cat,
                          color: AppTheme.accentColor,
                          onTap: () => provider.setCategory(
                            provider.selectedCategory == cat ? null : cat,
                          ),
                        ),
                      )),

                  // Tag filters
                  ...provider.tags.take(8).map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _FilterChip(
                          label: '#$tag',
                          icon: Icons.label_rounded,
                          isSelected: provider.selectedTag == tag,
                          color: AppTheme.tagColor(tag),
                          onTap: () => provider.setTag(
                            provider.selectedTag == tag ? null : tag,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark ? AppTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? color
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final LinkProvider provider;
  final bool isDark;

  const _SortButton({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      initialValue: provider.sortOption,
      onSelected: provider.setSortOption,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Icon(
          Icons.sort_rounded,
          size: 20,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _buildSortItem(SortOption.newest, Icons.schedule_rounded, 'Newest First', provider),
        _buildSortItem(SortOption.oldest, Icons.history_rounded, 'Oldest First', provider),
        _buildSortItem(SortOption.title, Icons.sort_by_alpha_rounded, 'By Title', provider),
        _buildSortItem(SortOption.mostVisited, Icons.trending_up_rounded, 'Most Visited', provider),
      ],
    );
  }

  PopupMenuItem<SortOption> _buildSortItem(
    SortOption option,
    IconData icon,
    String label,
    LinkProvider provider,
  ) {
    final isSelected = provider.sortOption == option;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 16, color: AppTheme.primaryColor),
          ],
        ],
      ),
    );
  }
}