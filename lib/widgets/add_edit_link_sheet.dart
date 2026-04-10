import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/link_model.dart';
import '../services/link_provider.dart';
import '../utils/app_theme.dart';

class AddEditLinkSheet extends StatefulWidget {
  final LinkModel? existingLink;

  const AddEditLinkSheet({super.key, this.existingLink});

  @override
  State<AddEditLinkSheet> createState() => _AddEditLinkSheetState();
}

class _AddEditLinkSheetState extends State<AddEditLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagController = TextEditingController();

  List<String> _selectedTags = [];
  String? _faviconUrl;
  bool _isFetchingMeta = false;
  bool _urlFetched = false;

  bool get isEditing => widget.existingLink != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final link = widget.existingLink!;
      _urlController.text = link.url;
      _titleController.text = link.title;
      _descriptionController.text = link.description ?? '';
      _categoryController.text = link.category ?? '';
      _selectedTags = List.from(link.tags);
      _faviconUrl = link.faviconUrl;
      _urlFetched = true;
    }

    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    if (_urlFetched) return;
    final url = _urlController.text.trim();
    if (url.length > 10 && (url.startsWith('http') || url.contains('.'))) {
      _fetchMetadata(url);
    }
  }

  Future<void> _fetchMetadata(String url) async {
    if (_isFetchingMeta) return;
    setState(() => _isFetchingMeta = true);

    try {
      final provider = context.read<LinkProvider>();
      final meta = await provider.fetchMetadata(url);

      if (meta != null && mounted) {
        setState(() {
          if (_titleController.text.isEmpty) {
            _titleController.text = meta.title;
          }
          if (_descriptionController.text.isEmpty && meta.description != null) {
            _descriptionController.text = meta.description!;
          }
          if (meta.faviconUrl != null) {
            _faviconUrl = meta.faviconUrl;
          }
          // Add suggested tags
          for (final tag in meta.suggestedTags) {
            if (!_selectedTags.contains(tag)) {
              _selectedTags.add(tag);
            }
          }
          _urlFetched = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isFetchingMeta = false);
    }
  }

  void _addTag(String tag) {
    tag = tag.trim().toLowerCase();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<LinkProvider>();
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();

    try {
      if (isEditing) {
        final updated = widget.existingLink!.copyWith(
          url: url,
          title: title,
          description: description.isEmpty ? null : description,
          tags: _selectedTags,
          faviconUrl: _faviconUrl,
          category: category.isEmpty ? null : category,
        );
        await provider.updateLink(updated);
      } else {
        await provider.addLink(
          url: url,
          title: title,
          description: description.isEmpty ? null : description,
          tags: _selectedTags,
          faviconUrl: _faviconUrl,
          category: category.isEmpty ? null : category,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving link: $e')),
        );
      }
    }
  }

  String _normalizeUrl(String url) {
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title row
              Row(
                children: [
                  if (_faviconUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _faviconUrl!,
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.language_rounded,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    isEditing ? 'Edit Link' : 'Add New Link',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_isFetchingMeta)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // URL Field
              _buildLabel('URL *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  suffixIcon: _isFetchingMeta
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search_rounded, size: 20),
                          tooltip: 'Fetch page info',
                          onPressed: () {
                            _urlFetched = false;
                            _fetchMetadata(_normalizeUrl(_urlController.text.trim()));
                          },
                        ),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                onChanged: (val) {
                  _urlController.text = _normalizeUrl(val);
                  _urlController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _urlController.text.length),
                  );
                },
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'URL is required';
                  try {
                    Uri.parse(val.trim());
                    return null;
                  } catch (_) {
                    return 'Enter a valid URL';
                  }
                },
              ),
              const SizedBox(height: 16),

              // Title Field
              _buildLabel('Title *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Page title or your own label',
                  prefixIcon: Icon(Icons.title_rounded, size: 20),
                ),
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              _buildLabel('Description (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Brief notes about this link...',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Category Field
              _buildLabel('Category (optional)'),
              const SizedBox(height: 6),
              Consumer<LinkProvider>(
                builder: (context, provider, _) {
                  final existingCategories = provider.categories;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., dev, design, reading...',
                          prefixIcon: Icon(Icons.folder_rounded, size: 20),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      if (existingCategories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: existingCategories.map((cat) {
                            final isSelected = _categoryController.text == cat;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _categoryController.text =
                                      isSelected ? '' : cat;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withOpacity(0.15)
                                      : surfaceColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : (isDark
                                            ? AppTheme.darkBorder
                                            : AppTheme.lightBorder),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppTheme.categoryIcon(cat),
                                      size: 14,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : (isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      cat,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : null,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Tags Field
              _buildLabel('Tags (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add tag and press enter',
                  prefixIcon: const Icon(Icons.label_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _addTag(_tagController.text),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: _addTag,
              ),
              if (_selectedTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedTags.map((tag) {
                    final color = AppTheme.tagColor(tag);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#$tag',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeTag(tag),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: color),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(isEditing ? 'Save Changes' : 'Add Link'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
    );
  }
}