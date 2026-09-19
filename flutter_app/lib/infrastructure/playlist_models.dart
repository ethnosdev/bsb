import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:uuid/uuid.dart';

enum PlaylistItemType {
  reference,
  note;

  static PlaylistItemType fromString(String val) {
    return PlaylistItemType.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => PlaylistItemType.reference,
    );
  }
}

class PlaylistItem {
  final String id;
  final PlaylistItemType type;
  final Reference? reference;
  final int? startWordId;
  final int? endWordId;
  final String? noteTitle;
  final String? noteText;
  final int orderIndex;

  PlaylistItem({
    String? id,
    required this.type,
    this.reference,
    this.startWordId,
    this.endWordId,
    this.noteTitle,
    this.noteText,
    required this.orderIndex,
  })  : id = id ?? const Uuid().v4(),
        assert(
          type != PlaylistItemType.reference || reference != null,
          'Reference must not be null for reference item type',
        ),
        assert(
          type != PlaylistItemType.note || (noteText != null),
          'Note text must not be null for note item type',
        );

  factory PlaylistItem.reference({
    String? id,
    required Reference reference,
    int? startWordId,
    int? endWordId,
    required int orderIndex,
  }) {
    return PlaylistItem(
      id: id,
      type: PlaylistItemType.reference,
      reference: reference,
      startWordId: startWordId,
      endWordId: endWordId,
      orderIndex: orderIndex,
    );
  }

  factory PlaylistItem.note({
    String? id,
    String? title,
    String? noteTitle,
    required String text,
    required int orderIndex,
  }) {
    return PlaylistItem(
      id: id,
      type: PlaylistItemType.note,
      noteTitle: noteTitle ?? title,
      noteText: text,
      orderIndex: orderIndex,
    );
  }

  bool get isReference => type == PlaylistItemType.reference;
  bool get isNote => type == PlaylistItemType.note;
  bool get isTrimmed => startWordId != null || endWordId != null;

  static const _sentinel = Object();

  PlaylistItem copyWith({
    String? id,
    PlaylistItemType? type,
    Reference? reference,
    Object? startWordId = _sentinel,
    Object? endWordId = _sentinel,
    bool clearTrim = false,
    String? noteTitle,
    String? noteText,
    int? orderIndex,
    bool clearTitle = false,
  }) {
    return PlaylistItem(
      id: id ?? this.id,
      type: type ?? this.type,
      reference: reference ?? this.reference,
      startWordId: clearTrim
          ? null
          : (identical(startWordId, _sentinel)
              ? this.startWordId
              : startWordId as int?),
      endWordId: clearTrim
          ? null
          : (identical(endWordId, _sentinel)
              ? this.endWordId
              : endWordId as int?),
      noteTitle: clearTitle ? null : (noteTitle ?? this.noteTitle),
      noteText: noteText ?? this.noteText,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'book_id': reference?.bookId,
      'chapter': reference?.chapter,
      'verse': reference?.verse,
      'end_chapter': reference?.endChapter,
      'end_verse': reference?.endVerse,
      'start_word_id': startWordId,
      'end_word_id': endWordId,
      'note_title': noteTitle,
      'note_text': noteText,
      'order_index': orderIndex,
    };
  }

  factory PlaylistItem.fromMap(Map<String, dynamic> map) {
    final type = PlaylistItemType.fromString(map['type'] as String? ?? 'reference');
    Reference? reference;
    if (type == PlaylistItemType.reference && map['book_id'] != null && map['chapter'] != null) {
      final bookId = (map['book_id'] as num).toInt();
      final chapter = (map['chapter'] as num).toInt();
      final verse = (map['verse'] as num?)?.toInt();
      final endChapter = (map['end_chapter'] as num?)?.toInt();
      final endVerse = (map['end_verse'] as num?)?.toInt();
      reference = Reference(
        bookId: bookId,
        chapter: chapter,
        verse: verse,
        endChapter: endChapter,
        endVerse: endVerse,
      );
    }

    return PlaylistItem(
      id: map['id'] as String? ?? const Uuid().v4(),
      type: type,
      reference: reference,
      startWordId: (map['start_word_id'] as num?)?.toInt(),
      endWordId: (map['end_word_id'] as num?)?.toInt(),
      noteTitle: map['note_title'] as String?,
      noteText: map['note_text'] as String?,
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          reference == other.reference &&
          startWordId == other.startWordId &&
          endWordId == other.endWordId &&
          noteTitle == other.noteTitle &&
          noteText == other.noteText &&
          orderIndex == other.orderIndex;

  @override
  int get hashCode =>
      Object.hash(id, type, reference, startWordId, endWordId, noteTitle, noteText, orderIndex);
}

class Playlist {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlaylistItem> items;

  Playlist({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlaylistItem>? items,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        items = List.unmodifiable(
          (items != null)
              ? (List<PlaylistItem>.from(items)
                ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)))
              : const <PlaylistItem>[],
        );

  int get passageCount => items.where((i) => i.isReference).length;
  int get noteCount => items.where((i) => i.isNote).length;
  bool get isEmpty => items.isEmpty;

  Playlist copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlaylistItem>? items,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap({bool includeItems = true}) {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
    if (includeItems) {
      map['items'] = items.map((i) => i.toMap()).toList();
    }
    return map;
  }

  factory Playlist.fromMap(
    Map<String, dynamic> map, [
    List<PlaylistItem>? externalItems,
  ]) {
    DateTime parseDate(dynamic val) {
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val);
      } else if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    List<PlaylistItem> resolvedItems = [];
    if (externalItems != null) {
      resolvedItems = externalItems;
    } else if (map['items'] != null && map['items'] is List) {
      final rawList = map['items'] as List<dynamic>;
      resolvedItems = rawList
          .whereType<Map<String, dynamic>>()
          .map((m) => PlaylistItem.fromMap(m))
          .toList();
    }

    return Playlist(
      id: map['id'] as String? ?? const Uuid().v4(),
      title: map['title'] as String? ?? 'Untitled Playlist',
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      items: resolvedItems,
    );
  }

  String toJson({bool pretty = false}) {
    final map = toMap(includeItems: true);
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return json.encode(map);
  }

  factory Playlist.fromJson(String jsonString) {
    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid playlist JSON');
    }
    return Playlist.fromMap(decoded);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(id, title, Object.hashAll(items));
}
