import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;

class MetadataService {
  static final MetadataService _instance = MetadataService._internal();
  factory MetadataService() => _instance;
  MetadataService._internal();

  Future<PageMetadata> fetchMetadata(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme) {
        return PageMetadata(title: _titleFromUrl(url), faviconUrl: _googleFaviconUrl(url));
      }

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final document = htmlParser.parse(response.body);

        // Try OG title first, then <title>
        String? title = document
            .querySelector('meta[property="og:title"]')
            ?.attributes['content'];
        title ??= document.querySelector('title')?.text;
        title ??= document
            .querySelector('meta[name="twitter:title"]')
            ?.attributes['content'];

        // Try OG description
        String? description = document
            .querySelector('meta[property="og:description"]')
            ?.attributes['content'];
        description ??= document
            .querySelector('meta[name="description"]')
            ?.attributes['content'];

        // Favicon: try link[rel="icon"] or link[rel="shortcut icon"] or Google's service
        String? faviconUrl = _extractFavicon(document, uri);
        faviconUrl ??= _googleFaviconUrl(url);

        // Smart tags from keywords meta or OG tags
        List<String> suggestedTags = _extractTags(document, uri);

        return PageMetadata(
          title: title?.trim() ?? _titleFromUrl(url),
          description: description?.trim(),
          faviconUrl: faviconUrl,
          suggestedTags: suggestedTags,
        );
      }
    } catch (_) {}

    return PageMetadata(
      title: _titleFromUrl(url),
      faviconUrl: _googleFaviconUrl(url),
    );
  }

  String? _extractFavicon(dynamic document, Uri baseUri) {
    final selectors = [
      'link[rel="apple-touch-icon"]',
      'link[rel="icon"][sizes="32x32"]',
      'link[rel="icon"][sizes="16x16"]',
      'link[rel="shortcut icon"]',
      'link[rel="icon"]',
    ];

    for (final selector in selectors) {
      final el = document.querySelector(selector);
      if (el != null) {
        final href = el.attributes['href'];
        if (href != null && href.isNotEmpty) {
          if (href.startsWith('http')) return href;
          if (href.startsWith('//')) return 'https:$href';
          return '${baseUri.scheme}://${baseUri.host}$href';
        }
      }
    }
    return null;
  }

  List<String> _extractTags(dynamic document, Uri uri) {
    final tags = <String>{};

    // Keywords meta
    final keywords = document
        .querySelector('meta[name="keywords"]')
        ?.attributes['content'];
    if (keywords != null) {
      tags.addAll(
        keywords
            .split(',')
            .map((k) => k.trim().toLowerCase())
            .where((k) => k.isNotEmpty && k.length < 20)
            .take(5),
      );
    }

    // OG type
    final ogType = document
        .querySelector('meta[property="og:type"]')
        ?.attributes['content'];
    if (ogType != null && ogType.isNotEmpty) tags.add(ogType.toLowerCase());

    // Domain-based smart tag
    final host = uri.host.replaceAll('www.', '');
    final domainTag = _domainToTag(host);
    if (domainTag != null) tags.add(domainTag);

    return tags.take(5).toList();
  }

  String? _domainToTag(String host) {
    const domainTags = {
      'github.com': 'dev',
      'stackoverflow.com': 'dev',
      'medium.com': 'article',
      'youtube.com': 'video',
      'twitter.com': 'social',
      'x.com': 'social',
      'linkedin.com': 'social',
      'reddit.com': 'social',
      'news.ycombinator.com': 'news',
      'bbc.com': 'news',
      'cnn.com': 'news',
      'docs.google.com': 'docs',
      'drive.google.com': 'docs',
      'notion.so': 'docs',
      'wikipedia.org': 'reference',
      'arxiv.org': 'research',
      'amazon.com': 'shopping',
      'netflix.com': 'entertainment',
      'spotify.com': 'music',
    };

    for (final entry in domainTags.entries) {
      if (host.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String _titleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.replaceAll('/', ' ').replaceAll('-', ' ').replaceAll('_', ' ').trim();
      if (path.isNotEmpty) return '${uri.host} - $path';
      return uri.host.replaceAll('www.', '');
    } catch (_) {
      return url;
    }
  }

  String _googleFaviconUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (_) {
      return '';
    }
  }
}

class PageMetadata {
  final String title;
  final String? description;
  final String? faviconUrl;
  final List<String> suggestedTags;

  PageMetadata({
    required this.title,
    this.description,
    this.faviconUrl,
    List<String>? suggestedTags,
  }) : suggestedTags = suggestedTags ?? [];
}