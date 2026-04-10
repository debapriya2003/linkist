import 'dart:convert';
import 'dart:io';
// ignore: unused_import
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/link_model.dart';
import 'database_service.dart';

/// Backup envelope written to / read from JSON files.
class BackupManifest {
  static const int currentVersion = 1;

  final int version;
  final DateTime exportedAt;
  final String appName;
  final int totalLinks;
  final List<LinkModel> links;

  BackupManifest({
    required this.version,
    required this.exportedAt,
    required this.totalLinks,
    required this.links,
  }) : appName = 'LinkVault';

  Map<String, dynamic> toJson() => {
        'version': version,
        'appName': appName,
        'exportedAt': exportedAt.toIso8601String(),
        'totalLinks': totalLinks,
        'links': links.map((l) => l.toMap()).toList(),
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['links'] as List<dynamic>? ?? [];
    return BackupManifest(
      version: json['version'] as int? ?? 1,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ?? DateTime.now(),
      totalLinks: json['totalLinks'] as int? ?? rawLinks.length,
      links: rawLinks
          .map((e) => LinkModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

enum ImportConflictStrategy { skip, overwrite, keepBoth }

class ImportResult {
  final int imported;
  final int skipped;
  final int overwritten;
  final List<String> errors;

  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.overwritten,
    required this.errors,
  });
}

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  final DatabaseService _db = DatabaseService();

  // ─── EXPORT ──────────────────────────────────────────────────────────────────

  /// Builds the JSON backup string from the current database.
  Future<String> buildBackupJson() async {
    final links = await _db.getAllLinks(orderBy: 'createdAt', descending: false);
    final manifest = BackupManifest(
      version: BackupManifest.currentVersion,
      exportedAt: DateTime.now(),
      totalLinks: links.length,
      links: links,
    );
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(manifest.toJson());
  }

  /// Writes backup JSON to a temp file and triggers the system share sheet.
  Future<void> exportAndShare() async {
    final json = await buildBackupJson();
    final dir = await getTemporaryDirectory();
    final timestamp = _fileTimestamp();
    final file = File('${dir.path}/linkvault_backup_$timestamp.json');
    await file.writeAsString(json, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'LinkVault Backup – $timestamp',
      text: 'My LinkVault links backup. Import this file in LinkVault to restore.',
    );
  }

  /// Saves backup to the device Downloads / Documents folder and returns the path.
  Future<String> exportToFile() async {
    final json = await buildBackupJson();
    final timestamp = _fileTimestamp();
    final fileName = 'linkvault_backup_$timestamp.json';

    Directory dir;
    if (Platform.isAndroid) {
      // Try external Downloads first, fall back to app documents
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json, encoding: utf8);
    return file.path;
  }

  // ─── IMPORT ──────────────────────────────────────────────────────────────────

Future<String?> pickBackupFile() async {
  // Use FilePicker.instance in newer versions
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    allowMultiple: false,
    withData: true, // Required for Web to populate the 'bytes' field
  );

  if (result == null || result.files.isEmpty) return null;

  final platformFile = result.files.single;

  // Web implementation
  if (kIsWeb) {
    if (platformFile.bytes != null) {
      return utf8.decode(platformFile.bytes!);
    }
    return null;
  }

  // Mobile/Desktop implementation
  final path = platformFile.path;
  if (path == null) return null;
  return File(path).readAsString(encoding: utf8);
}


  /// Parses a JSON string into a [BackupManifest]. Throws on bad format.
  BackupManifest parseBackup(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Not a valid LinkVault backup file.');
    }
    if (decoded['appName'] != 'LinkVault' && decoded['links'] == null) {
      throw const FormatException('File does not appear to be a LinkVault backup.');
    }
    return BackupManifest.fromJson(decoded);
  }

  /// Imports links from a manifest into the database using the given strategy.
  Future<ImportResult> importBackup(
    BackupManifest manifest,
    ImportConflictStrategy strategy,
  ) async {
    int imported = 0;
    int skipped = 0;
    int overwritten = 0;
    final errors = <String>[];

    for (final link in manifest.links) {
      try {
        final existing = await _db.getLinkById(link.id);

        if (existing == null) {
          await _db.insertLink(link);
          imported++;
        } else {
          switch (strategy) {
            case ImportConflictStrategy.skip:
              skipped++;
              break;
            case ImportConflictStrategy.overwrite:
              await _db.updateLink(link);
              overwritten++;
              break;
            case ImportConflictStrategy.keepBoth:
              // Assign a new ID so both coexist
              final newLink = link.copyWith(
                id: '${link.id}_imported_${DateTime.now().millisecondsSinceEpoch}',
              );
              await _db.insertLink(newLink);
              imported++;
              break;
          }
        }
      } catch (e) {
        errors.add('Failed to import "${link.title}": $e');
      }
    }

    return ImportResult(
      imported: imported,
      skipped: skipped,
      overwritten: overwritten,
      errors: errors,
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  String _fileTimestamp() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}'
        '_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// Quick validation – just checks top-level keys without full parse.
  bool looksLikeBackup(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.containsKey('links') && decoded['links'] is List;
    } catch (_) {
      return false;
    }
  }
}