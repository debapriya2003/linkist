import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/export_import_service.dart';
import '../services/link_provider.dart';
import '../utils/app_theme.dart';

class ExportImportScreen extends StatefulWidget {
  const ExportImportScreen({super.key});

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _svc = ExportImportService();

  // Export state
  bool _exporting = false;
  String? _exportedPath;
  String? _exportError;

  // Import state
  bool _importing = false;
  bool _picking = false;
  BackupManifest? _pendingManifest;
  String? _pickError;
  ImportConflictStrategy _strategy = ImportConflictStrategy.skip;
  ImportResult? _importResult;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─── EXPORT ACTIONS ──────────────────────────────────────────────────────────

  Future<void> _shareBackup() async {
    setState(() {
      _exporting = true;
      _exportedPath = null;
      _exportError = null;
    });
    try {
      await _svc.exportAndShare();
    } catch (e) {
      setState(() => _exportError = e.toString());
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _saveToFile() async {
    setState(() {
      _exporting = true;
      _exportedPath = null;
      _exportError = null;
    });
    try {
      final path = await _svc.exportToFile();
      setState(() => _exportedPath = path);
    } catch (e) {
      setState(() => _exportError = e.toString());
    } finally {
      setState(() => _exporting = false);
    }
  }

  // ─── IMPORT ACTIONS ──────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() {
      _picking = true;
      _pickError = null;
      _pendingManifest = null;
      _importResult = null;
    });
    try {
      final json = await _svc.pickBackupFile();
      if (json == null) {
        setState(() => _picking = false);
        return;
      }
      final manifest = _svc.parseBackup(json);
      setState(() => _pendingManifest = manifest);
    } catch (e) {
      setState(() => _pickError = 'Could not read file: $e');
    } finally {
      setState(() => _picking = false);
    }
  }

  Future<void> _runImport() async {
    if (_pendingManifest == null) return;
    setState(() {
      _importing = true;
      _importResult = null;
    });
    try {
      final result = await _svc.importBackup(_pendingManifest!, _strategy);
      setState(() {
        _importResult = result;
        _pendingManifest = null;
      });
      if (mounted) {
        // Refresh the main list
        context.read<LinkProvider>().init();
      }
    } catch (e) {
      setState(() => _pickError = 'Import failed: $e');
    } finally {
      setState(() => _importing = false);
    }
  }

  void _resetImport() {
    setState(() {
      _pendingManifest = null;
      _importResult = null;
      _pickError = null;
    });
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.upload_rounded, size: 18), text: 'Export'),
            Tab(icon: Icon(Icons.download_rounded, size: 18), text: 'Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ExportTab(
            exporting: _exporting,
            exportedPath: _exportedPath,
            exportError: _exportError,
            onShare: _shareBackup,
            onSave: _saveToFile,
          ),
          _ImportTab(
            picking: _picking,
            importing: _importing,
            pickError: _pickError,
            pendingManifest: _pendingManifest,
            importResult: _importResult,
            strategy: _strategy,
            onStrategyChanged: (s) => setState(() => _strategy = s),
            onPickFile: _pickFile,
            onRunImport: _runImport,
            onReset: _resetImport,
          ),
        ],
      ),
    );
  }
}

// ─── EXPORT TAB ──────────────────────────────────────────────────────────────

class _ExportTab extends StatelessWidget {
  final bool exporting;
  final String? exportedPath;
  final String? exportError;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _ExportTab({
    required this.exporting,
    required this.exportedPath,
    required this.exportError,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.backup_rounded,
            title: 'Export your links',
            subtitle:
                'Save all your links as a portable JSON file. Use it to move to a new device, create a backup, or share with another LinkVault installation.',
            iconColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),

          // Info card
          Consumer<LinkProvider>(
            builder: (context, provider, _) {
              final count = provider.stats['total'] ?? 0;
              return _InfoCard(
                isDark: isDark,
                children: [
                  _InfoRow(
                    icon: Icons.link_rounded,
                    label: 'Links to export',
                    value: '$count link${count == 1 ? '' : 's'}',
                    valueColor: AppTheme.primaryColor,
                  ),
                  _InfoRow(
                    icon: Icons.code_rounded,
                    label: 'Format',
                    value: 'JSON (human-readable)',
                  ),
                  _InfoRow(
                    icon: Icons.lock_open_rounded,
                    label: 'Encryption',
                    value: 'None (plaintext)',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Action buttons
          _ActionCard(
            isDark: isDark,
            icon: Icons.share_rounded,
            iconColor: AppTheme.primaryColor,
            title: 'Share backup file',
            subtitle: 'Send via email, WhatsApp, Drive, AirDrop…',
            loading: exporting,
            onTap: onShare,
            buttonLabel: 'Share',
            buttonIcon: Icons.share_rounded,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            isDark: isDark,
            icon: Icons.save_alt_rounded,
            iconColor: AppTheme.accentColor,
            title: 'Save to device',
            subtitle: 'Downloads folder on Android · Documents on iOS',
            loading: exporting,
            onTap: onSave,
            buttonLabel: 'Save file',
            buttonIcon: Icons.save_alt_rounded,
            buttonColor: AppTheme.accentColor,
          ),

          // Results
          if (exportedPath != null) ...[
            const SizedBox(height: 16),
            _ResultBanner(
              success: true,
              message: 'Saved to:',
              detail: exportedPath,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: exportedPath!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Path copied to clipboard')),
                );
              },
            ),
          ],
          if (exportError != null) ...[
            const SizedBox(height: 16),
            _ResultBanner(success: false, message: exportError!),
          ],

          const SizedBox(height: 28),
          _TipBox(
            isDark: isDark,
            tip:
                'Tip: Export regularly and store the file in Google Drive or iCloud so you can restore even if you lose your phone.',
          ),
        ],
      ),
    );
  }
}

// ─── IMPORT TAB ──────────────────────────────────────────────────────────────

class _ImportTab extends StatelessWidget {
  final bool picking;
  final bool importing;
  final String? pickError;
  final BackupManifest? pendingManifest;
  final ImportResult? importResult;
  final ImportConflictStrategy strategy;
  final ValueChanged<ImportConflictStrategy> onStrategyChanged;
  final VoidCallback onPickFile;
  final VoidCallback onRunImport;
  final VoidCallback onReset;

  const _ImportTab({
    required this.picking,
    required this.importing,
    required this.pickError,
    required this.pendingManifest,
    required this.importResult,
    required this.strategy,
    required this.onStrategyChanged,
    required this.onPickFile,
    required this.onRunImport,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show results screen
    if (importResult != null) {
      return _ImportResultView(
        result: importResult!,
        isDark: isDark,
        onDone: onReset,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.restore_rounded,
            title: 'Restore from backup',
            subtitle:
                'Choose a LinkVault JSON backup file from your device. All links inside will be added to your current collection.',
            iconColor: AppTheme.successColor,
          ),
          const SizedBox(height: 24),

          // Step 1 — Pick file
          _StepCard(
            step: 1,
            isDark: isDark,
            title: 'Select backup file',
            child: Column(
              children: [
                if (pendingManifest == null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: picking ? null : onPickFile,
                      icon: picking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(picking ? 'Opening…' : 'Browse files (.json)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  _ManifestPreview(manifest: pendingManifest!, isDark: isDark, onClear: onReset),
              ],
            ),
          ),

          if (pickError != null) ...[
            const SizedBox(height: 12),
            _ResultBanner(success: false, message: pickError!),
          ],

          // Step 2 — Conflict strategy (only after file picked)
          if (pendingManifest != null) ...[
            const SizedBox(height: 16),
            _StepCard(
              step: 2,
              isDark: isDark,
              title: 'Conflict handling',
              child: Column(
                children: [
                  _StrategyOption(
                    value: ImportConflictStrategy.skip,
                    selected: strategy,
                    isDark: isDark,
                    label: 'Skip duplicates',
                    subtitle: 'Keep existing links unchanged, ignore matches from backup.',
                    icon: Icons.skip_next_rounded,
                    onChanged: onStrategyChanged,
                  ),
                  const SizedBox(height: 8),
                  _StrategyOption(
                    value: ImportConflictStrategy.overwrite,
                    selected: strategy,
                    isDark: isDark,
                    label: 'Overwrite duplicates',
                    subtitle: 'Replace existing links with the backup version.',
                    icon: Icons.sync_rounded,
                    onChanged: onStrategyChanged,
                  ),
                  const SizedBox(height: 8),
                  _StrategyOption(
                    value: ImportConflictStrategy.keepBoth,
                    selected: strategy,
                    isDark: isDark,
                    label: 'Keep both',
                    subtitle: 'Import all links, duplicates get a new ID.',
                    icon: Icons.copy_all_rounded,
                    onChanged: onStrategyChanged,
                  ),
                ],
              ),
            ),

            // Step 3 — Run
            const SizedBox(height: 16),
            _StepCard(
              step: 3,
              isDark: isDark,
              title: 'Start import',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: importing ? null : onRunImport,
                  icon: importing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_done_rounded, size: 18),
                  label: Text(
                    importing
                        ? 'Importing…'
                        : 'Import ${pendingManifest!.totalLinks} link${pendingManifest!.totalLinks == 1 ? '' : 's'}',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),
          _TipBox(
            isDark: isDark,
            tip:
                'Tip: The backup file must be a LinkVault JSON export. Files from other apps are not supported.',
          ),
        ],
      ),
    );
  }
}

// ─── IMPORT RESULT VIEW ──────────────────────────────────────────────────────

class _ImportResultView extends StatelessWidget {
  final ImportResult result;
  final bool isDark;
  final VoidCallback onDone;

  const _ImportResultView({
    required this.result,
    required this.isDark,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = result.errors.isEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (success ? AppTheme.successColor : AppTheme.warningColor)
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_rounded : Icons.warning_rounded,
                size: 44,
                color: success ? AppTheme.successColor : AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              success ? 'Import complete!' : 'Import finished with warnings',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            _InfoCard(
              isDark: isDark,
              children: [
                if (result.imported > 0)
                  _InfoRow(
                    icon: Icons.add_circle_rounded,
                    label: 'Added',
                    value: '${result.imported} link${result.imported == 1 ? '' : 's'}',
                    valueColor: AppTheme.successColor,
                  ),
                if (result.overwritten > 0)
                  _InfoRow(
                    icon: Icons.sync_rounded,
                    label: 'Overwritten',
                    value: '${result.overwritten} link${result.overwritten == 1 ? '' : 's'}',
                    valueColor: AppTheme.primaryColor,
                  ),
                if (result.skipped > 0)
                  _InfoRow(
                    icon: Icons.skip_next_rounded,
                    label: 'Skipped',
                    value: '${result.skipped} link${result.skipped == 1 ? '' : 's'}',
                    valueColor: AppTheme.darkTextSecondary,
                  ),
                if (result.errors.isNotEmpty)
                  _InfoRow(
                    icon: Icons.error_outline_rounded,
                    label: 'Errors',
                    value: '${result.errors.length}',
                    valueColor: AppTheme.dangerColor,
                  ),
              ],
            ),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dangerColor.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.errors
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• $e',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.dangerColor),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.done_rounded),
                label: const Text('Done'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SMALL REUSABLE WIDGETS ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _InfoCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        children: children
            .expand((w) => [w, const Divider(height: 16)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: valueColor ?? AppTheme.darkTextSecondary),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;
  final String buttonLabel;
  final IconData buttonIcon;
  final Color? buttonColor;

  const _ActionCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
    required this.buttonLabel,
    required this.buttonIcon,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = buttonColor ?? AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: loading ? null : onTap,
            icon: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Icon(buttonIcon, size: 14),
            label: Text(buttonLabel, style: const TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final bool isDark;
  final String title;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.isDark,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ManifestPreview extends StatelessWidget {
  final BackupManifest manifest;
  final bool isDark;
  final VoidCallback onClear;

  const _ManifestPreview({
    required this.manifest,
    required this.isDark,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.successColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Backup file loaded',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: AppTheme.successColor),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.link_rounded,
            label: 'Links in backup',
            value: '${manifest.totalLinks}',
            valueColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Exported',
            value: _formatDate(manifest.exportedAt),
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.info_rounded,
            label: 'Backup version',
            value: 'v${manifest.version}',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StrategyOption extends StatelessWidget {
  final ImportConflictStrategy value;
  final ImportConflictStrategy selected;
  final bool isDark;
  final String label;
  final String subtitle;
  final IconData icon;
  final ValueChanged<ImportConflictStrategy> onChanged;

  const _StrategyOption({
    required this.value,
    required this.selected,
    required this.isDark,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == selected;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : (isDark ? AppTheme.darkSurface : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Radio<ImportConflictStrategy>(
              value: value,
              groupValue: selected,
              onChanged: (v) => onChanged(v!),
              activeColor: AppTheme.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool success;
  final String message;
  final String? detail;
  final VoidCallback? onCopy;

  const _ResultBanner({
    required this.success,
    required this.message,
    this.detail,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = success ? AppTheme.successColor : AppTheme.dangerColor;
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600, color: color)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                ],
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 15),
              onPressed: onCopy,
              tooltip: 'Copy path',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final bool isDark;
  final String tip;

  const _TipBox({required this.isDark, required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              size: 16, color: AppTheme.warningColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tip,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }
}