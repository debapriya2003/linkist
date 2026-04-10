import 'dart:convert';

class LinkModel {
  final String id;
  String title;
  String url;
  String? description;
  List<String> tags;
  String? faviconUrl;
  String? category;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;
  int? visitCount;

  LinkModel({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    List<String>? tags,
    this.faviconUrl,
    this.category,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.visitCount = 0,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'tags': jsonEncode(tags),
      'faviconUrl': faviconUrl,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'visitCount': visitCount ?? 0,
    };
  }

  factory LinkModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['tags'].toString());
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return LinkModel(
      id: map['id'],
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      description: map['description'],
      tags: parsedTags,
      faviconUrl: map['faviconUrl'],
      category: map['category'],
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      visitCount: map['visitCount'] ?? 0,
    );
  }

  LinkModel copyWith({
    String? id,
    String? title,
    String? url,
    String? description,
    List<String>? tags,
    String? faviconUrl,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? visitCount,
  }) {
    return LinkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      tags: tags ?? List.from(this.tags),
      faviconUrl: faviconUrl ?? this.faviconUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      visitCount: visitCount ?? this.visitCount,
    );
  }

  String get domain {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (_) {
      return url;
    }
  }

  String get faviconFallbackUrl {
    try {
      final uri = Uri.parse(url);
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (_) {
      return '';
    }
  }
}