import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../services/link_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/add_edit_link_sheet.dart';
import '../widgets/link_card.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/stats_header.dart';
import '../widgets/empty_state.dart';
import 'export_import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabAnimController;
  bool _isCompactView = false;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LinkProvider>().init();
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _showAddLinkSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const AddEditLinkSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'LinkVault',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Compact/Expanded view toggle
          IconButton(
            icon: Icon(
              _isCompactView
                  ? Icons.view_agenda_rounded
                  : Icons.view_list_rounded,
              size: 20,
            ),
            tooltip: _isCompactView ? 'Expanded view' : 'Compact view',
            onPressed: () => setState(() => _isCompactView = !_isCompactView),
          ),
          // Theme toggle handled in main.dart via provider
          Consumer<LinkProvider>(
            builder: (context, provider, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onPressed: () => _showOptionsMenu(context, provider),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const StatsHeader(),
          const SearchFilterBar(),
          const SizedBox(height: 4),
          Expanded(
            child: Consumer<LinkProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                if (provider.links.isEmpty) {
                  return EmptyState(
                    hasFilters: provider.hasActiveFilters,
                    onAddLink: _showAddLinkSheet,
                    onClearFilters: provider.clearFilters,
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: provider.links.length,
                    itemBuilder: (context, index) {
                      final link = provider.links[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 350),
                        child: SlideAnimation(
                          verticalOffset: 30,
                          child: FadeInAnimation(
                            child: LinkCard(
                              key: ValueKey(link.id),
                              link: link,
                              isCompact: _isCompactView,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddLinkSheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add Link',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, LinkProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // ── Backup & Restore ──────────────────────────────────────────
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.backup_rounded,
                    color: AppTheme.primaryColor, size: 20),
              ),
              title: const Text('Backup & Restore',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Export or import your links'),
              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExportImportScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 8, indent: 16, endIndent: 16),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: AppTheme.accentColor, size: 20),
              ),
              title: const Text('Refresh'),
              subtitle: const Text('Reload links from database'),
              onTap: () {
                Navigator.pop(ctx);
                provider.init();
              },
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_outline_rounded,
                    color: Colors.grey.shade500, size: 20),
              ),
              title: const Text('About LinkVault'),
              onTap: () {
                Navigator.pop(ctx);
                showAboutDialog(
                  context: context,
                  applicationName: 'LinkVault',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Your personal link organiser',
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}