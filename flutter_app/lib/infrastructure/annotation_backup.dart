import 'dart:convert';

import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/reference.dart';

enum AnnotationImportMode {
  merge,
  replace,
}

class AnnotationImportResult {
  final int highlightsImported;
  final int notesImported;
  final int playlistsImported;
  final AnnotationImportMode mode;

  const AnnotationImportResult({
    required this.highlightsImported,
    required this.notesImported,
    this.playlistsImported = 0,
    required this.mode,
  });
}

class AnnotationBackup {
  static const int currentVersion = 2;

  final int version;
  final String app;
  final DateTime exportedAt;
  final List<Highlight> highlights;
  final List<Note> notes;
  final List<Playlist> playlists;

  AnnotationBackup({
    this.version = currentVersion,
    this.app = 'bsb',
    required this.exportedAt,
    required this.highlights,
    required this.notes,
    this.playlists = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'app': app,
      'exported_at': exportedAt.toIso8601String(),
      'highlights': highlights.map((h) => h.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'playlists': playlists.map((p) => p.toMap()).toList(),
    };
  }

  factory AnnotationBackup.fromMap(Map<String, dynamic> map) {
    final version = (map['version'] as num?)?.toInt() ?? 1;
    final app = map['app'] as String? ?? 'bsb';

    DateTime exportedAt = DateTime.now();
    if (map['exported_at'] != null) {
      if (map['exported_at'] is String) {
        exportedAt = DateTime.tryParse(map['exported_at'] as String) ?? DateTime.now();
      } else if (map['exported_at'] is int) {
        exportedAt = DateTime.fromMillisecondsSinceEpoch(map['exported_at'] as int);
      }
    }

    final rawHighlights = map['highlights'] as List<dynamic>? ?? [];
    final highlights = rawHighlights
        .whereType<Map<String, dynamic>>()
        .map((m) => Highlight.fromMap(m))
        .toList();

    final rawNotes = map['notes'] as List<dynamic>? ?? [];
    final notes = rawNotes
        .whereType<Map<String, dynamic>>()
        .map((m) => Note.fromMap(m))
        .toList();

    final rawPlaylists = map['playlists'] as List<dynamic>? ?? [];
    final playlists = rawPlaylists
        .whereType<Map<String, dynamic>>()
        .map((m) => Playlist.fromMap(m))
        .toList();

    return AnnotationBackup(
      version: version,
      app: app,
      exportedAt: exportedAt,
      highlights: highlights,
      notes: notes,
      playlists: playlists,
    );
  }

  String toJson({bool pretty = true}) {
    final map = toMap();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return json.encode(map);
  }

  factory AnnotationBackup.fromJson(String jsonString) {
    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup format: root must be a JSON object');
    }
    return AnnotationBackup.fromMap(decoded);
  }

  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# BSB Highlights & Notes');
    buffer.writeln();
    buffer.writeln('*Exported on ${_formatDate(exportedAt)}*');
    buffer.writeln();

    if (highlights.isNotEmpty) {
      buffer.writeln('## Highlights (${highlights.length})');
      buffer.writeln();
      for (final h in highlights) {
        final ref = Reference.fromWordId(
          packedInt: h.startWordId,
          packedIntEnd: h.endWordId,
        );
        buffer.writeln('### $ref (${h.color.name})');
        if (h.text != null && h.text!.isNotEmpty) {
          buffer.writeln('> ${h.text}');
        }
        buffer.writeln();
      }
    }

    if (notes.isNotEmpty) {
      buffer.writeln('## Notes (${notes.length})');
      buffer.writeln();
      for (final n in notes) {
        final ref = Reference.fromWordId(
          packedInt: n.startWordId,
          packedIntEnd: n.endWordId,
        );
        buffer.writeln('### $ref');
        if (n.passageText != null && n.passageText!.isNotEmpty) {
          buffer.writeln('> ${n.passageText}');
          buffer.writeln();
        }
        buffer.writeln(n.content);
        buffer.writeln();
      }
    }

    if (playlists.isNotEmpty) {
      buffer.writeln('## Playlists (${playlists.length})');
      buffer.writeln();
      for (final p in playlists) {
        buffer.writeln('### ${p.title}');
        buffer.writeln();
        for (int i = 0; i < p.items.length; i++) {
          final item = p.items[i];
          if (item.isReference) {
            buffer.writeln('${i + 1}. **${item.reference}**');
          } else {
            buffer.writeln('> Note: ${item.noteText}');
          }
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
