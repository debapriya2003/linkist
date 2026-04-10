import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/link_model.dart';
import '../services/link_provider.dart';
import '../utils/app_theme.dart';
import 'add_edit_link_sheet.dart';

class LinkCard extends StatelessWidget {
  final LinkModel link;
  final bool isCompact;

  const LinkCard({super.key, required this.link, this.isCompact = false});

  Future<void> _openUrl(BuildContext context) async {
  try {
    String url = link.url.trim();

    // 🔥 Fix 1: Normalize URL
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);

    // 🔥 Fix 2: Try opening in external browser FIRST
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    // 🔥 Fix 3: Fallback to in-app WebView if external fails
    if (!launched) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
    }

    // 🔥 Fix 4: Record visit only if launch attempted
    context.read<LinkProvider>().recordVisit(link.id);

  } catch (e) {
    debugPrint("URL launch error: $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or unsupported URL')),
      );
    }
  }
}

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: link.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 18),
            SizedBox(width: 8),
            Text('URL copied to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _editLink(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddEditLinkSheet(existingLink: link),
    );
  }

  Future<void> _deleteLink(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Link?'),
        content: Text('Remove "${link.title}" from your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<LinkProvider>().deleteLink(link.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Slidable(
      key: ValueKey(link.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => context.read<LinkProvider>().toggleFavorite(link.id),
            backgroundColor: AppTheme.warningColor,
            foregroundColor: Colors.white,
            icon: link.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            label: link.isFavorite ? 'Unfave' : 'Fave',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => _editLink(context),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => _deleteLink(context),
            backgroundColor: AppTheme.dangerColor,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _openUrl(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: link.isFavorite
                  ? AppTheme.warningColor.withOpacity(0.4)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Favicon
                    _FaviconWidget(link: link),
                    const SizedBox(width: 10),

                    // Title + Domain
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: isCompact ? 14 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            link.domain,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (link.isFavorite)
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.warningColor,
                            size: 16,
                          ),
                        const SizedBox(width: 4),
                        _ActionIconButton(
                          icon: Icons.copy_rounded,
                          tooltip: 'Copy URL',
                          onTap: () => _copyUrl(context),
                        ),
                        _ActionIconButton(
                          icon: Icons.open_in_new_rounded,
                          tooltip: 'Open in browser',
                          onTap: () => _openUrl(context),
                        ),
                      ],
                    ),
                  ],
                ),

                // Description
                if (!isCompact && link.description != null && link.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    link.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Tags + Meta row
                if (!isCompact) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Category chip
                      if (link.category != null && link.category!.isNotEmpty)
                        _CategoryChip(category: link.category!, isDark: isDark),

                      // Tags
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: link.tags.take(3).map((tag) {
                              final color = AppTheme.tagColor(tag);
                              return Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Visit count
                      if ((link.visitCount ?? 0) > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              size: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${link.visitCount}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaviconWidget extends StatelessWidget {
  final LinkModel link;

  const _FaviconWidget({required this.link});

  @override
  Widget build(BuildContext context) {
    final faviconUrl = link.faviconUrl ?? link.faviconFallbackUrl;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: faviconUrl.isNotEmpty
            ? Image.network(
                faviconUrl,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const _DefaultFaviconIcon(),
              )
            : const _DefaultFaviconIcon(),
      ),
    );
  }
}

class _DefaultFaviconIcon extends StatelessWidget {
  const _DefaultFaviconIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.language_rounded,
      size: 20,
      color: AppTheme.primaryColor,
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final bool isDark;

  const _CategoryChip({required this.category, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppTheme.categoryIcon(category),
            size: 10,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 3),
          Text(
            category,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}