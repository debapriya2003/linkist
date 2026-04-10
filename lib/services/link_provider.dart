import 'package:flutter/foundation.dart';
import '../models/link_model.dart';
import '../services/database_service.dart';
import '../services/metadata_service.dart';
import 'package:uuid/uuid.dart';

enum SortOption { newest, oldest, title, mostVisited }

class LinkProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final MetadataService _metaService = MetadataService();
  final _uuid = const Uuid();

  List<LinkModel> _links = [];
  List<String> _categories = [];
  List<String> _tags = [];
  Map<String, int> _stats = {};

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedTag;
  bool? _showFavoritesOnly;
  SortOption _sortOption = SortOption.newest;
  bool _isLoading = false;
  bool _isFetchingMeta = false;

  List<LinkModel> get links => _links;
  List<String> get categories => _categories;
  List<String> get tags => _tags;
  Map<String, int> get stats => _stats;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedTag => _selectedTag;
  bool? get showFavoritesOnly => _showFavoritesOnly;
  SortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;
  bool get isFetchingMeta => _isFetchingMeta;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _selectedTag != null ||
      _showFavoritesOnly == true;

  Future<void> init() async {
    await loadLinks();
    await loadCategories();
    await loadTags();
    await loadStats();
  }

  Future<void> loadLinks() async {
    _isLoading = true;
    notifyListeners();

    String orderBy;
    bool descending = true;
    switch (_sortOption) {
      case SortOption.newest:
        orderBy = 'createdAt';
        descending = true;
        break;
      case SortOption.oldest:
        orderBy = 'createdAt';
        descending = false;
        break;
      case SortOption.title:
        orderBy = 'title';
        descending = false;
        break;
      case SortOption.mostVisited:
        orderBy = 'visitCount';
        descending = true;
        break;
    }

    _links = await _db.getAllLinks(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
      tag: _selectedTag,
      isFavorite: _showFavoritesOnly,
      orderBy: orderBy,
      descending: descending,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _db.getAllCategories();
    notifyListeners();
  }

  Future<void> loadTags() async {
    _tags = await _db.getAllTags();
    notifyListeners();
  }

  Future<void> loadStats() async {
    _stats = await _db.getStats();
    notifyListeners();
  }

  Future<PageMetadata?> fetchMetadata(String url) async {
    _isFetchingMeta = true;
    notifyListeners();
    try {
      final meta = await _metaService.fetchMetadata(url);
      return meta;
    } finally {
      _isFetchingMeta = false;
      notifyListeners();
    }
  }

  Future<LinkModel> addLink({
    required String url,
    required String title,
    String? description,
    List<String>? tags,
    String? faviconUrl,
    String? category,
  }) async {
    final link = LinkModel(
      id: _uuid.v4(),
      title: title,
      url: url,
      description: description,
      tags: tags ?? [],
      faviconUrl: faviconUrl,
      category: category,
    );

    await _db.insertLink(link);
    await _refresh();
    return link;
  }

  Future<LinkModel> updateLink(LinkModel link) async {
    final updated = await _db.updateLink(link);
    await _refresh();
    return updated;
  }

  Future<void> deleteLink(String id) async {
    await _db.deleteLink(id);
    await _refresh();
  }

  Future<void> deleteLinks(List<String> ids) async {
    await _db.deleteLinks(ids);
    await _refresh();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _links.indexWhere((l) => l.id == id);
    if (index != -1) {
      final newValue = !_links[index].isFavorite;
      await _db.toggleFavorite(id, newValue);
      _links[index] = _links[index].copyWith(isFavorite: newValue);
      await loadStats();
      notifyListeners();
    }
  }

  Future<void> recordVisit(String id) async {
    await _db.incrementVisitCount(id);
    final index = _links.indexWhere((l) => l.id == id);
    if (index != -1) {
      _links[index] = _links[index].copyWith(visitCount: (_links[index].visitCount ?? 0) + 1);
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadLinks();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    loadLinks();
  }

  void setTag(String? tag) {
    _selectedTag = tag;
    loadLinks();
  }

  void setFavoritesOnly(bool? value) {
    _showFavoritesOnly = value;
    loadLinks();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    loadLinks();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedTag = null;
    _showFavoritesOnly = null;
    loadLinks();
  }

  Future<void> _refresh() async {
    await Future.wait([loadLinks(), loadCategories(), loadTags(), loadStats()]);
  }
}