import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/link_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'link_saver.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE links (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        description TEXT,
        tags TEXT,
        faviconUrl TEXT,
        category TEXT,
        isFavorite INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        visitCount INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_links_category ON links(category)');
    await db.execute('CREATE INDEX idx_links_createdAt ON links(createdAt)');
  }

  Future<LinkModel> insertLink(LinkModel link) async {
    final db = await database;
    await db.insert('links', link.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return link;
  }

  Future<List<LinkModel>> getAllLinks({
    String? searchQuery,
    String? category,
    String? tag,
    bool? isFavorite,
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    final db = await database;
    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(title LIKE ? OR url LIKE ? OR description LIKE ? OR tags LIKE ?)');
      final q = '%$searchQuery%';
      whereArgs.addAll([q, q, q, q]);
    }
    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      whereArgs.add(category);
    }
    if (tag != null && tag.isNotEmpty) {
      conditions.add('tags LIKE ?');
      whereArgs.add('%$tag%');
    }
    if (isFavorite != null) {
      conditions.add('isFavorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'links',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '$orderBy ${descending ? 'DESC' : 'ASC'}',
    );
    return maps.map((map) => LinkModel.fromMap(map)).toList();
  }

  Future<LinkModel?> getLinkById(String id) async {
    final db = await database;
    final maps = await db.query('links', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return LinkModel.fromMap(maps.first);
    return null;
  }

  Future<LinkModel> updateLink(LinkModel link) async {
    final db = await database;
    final updated = link.copyWith(updatedAt: DateTime.now());
    await db.update('links', updated.toMap(), where: 'id = ?', whereArgs: [link.id]);
    return updated;
  }

  Future<void> deleteLink(String id) async {
    final db = await database;
    await db.delete('links', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteLinks(List<String> ids) async {
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete('links', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<void> toggleFavorite(String id, bool value) async {
    final db = await database;
    await db.update(
      'links',
      {'isFavorite': value ? 1 : 0, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementVisitCount(String id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE links SET visitCount = visitCount + 1, updatedAt = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  Future<List<String>> getAllCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT DISTINCT category FROM links WHERE category IS NOT NULL AND category != '' ORDER BY category ASC",
    );
    return result.map((row) => row['category'].toString()).toList();
  }

  Future<List<String>> getAllTags() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT tags FROM links WHERE tags IS NOT NULL AND tags != ''",
    );
    final Set<String> allTags = {};
    for (final row in result) {
      try {
        final decoded = jsonDecode(row['tags'].toString());
        if (decoded is List) {
          for (final t in decoded) {
            if (t.toString().isNotEmpty) allTags.add(t.toString());
          }
        }
      } catch (_) {}
    }
    return allTags.toList()..sort();
  }

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM links')) ?? 0;
    final favorites = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM links WHERE isFavorite = 1'),
        ) ?? 0;
    final categories = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(DISTINCT category) FROM links WHERE category IS NOT NULL AND category != ''",
          ),
        ) ?? 0;
    return {'total': total, 'favorites': favorites, 'categories': categories};
  }
}