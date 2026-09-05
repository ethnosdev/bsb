import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';

enum HighlightColor {
  yellow,
  green,
  blue,
  pink,
  purple;

  Color get previewColor {
    switch (this) {
      case HighlightColor.yellow:
        return const Color(0xFFFFF176);
      case HighlightColor.green:
        return const Color(0xFFA5D6A7);
      case HighlightColor.blue:
        return const Color(0xFF90CAF9);
      case HighlightColor.pink:
        return const Color(0xFFF48FB1);
      case HighlightColor.purple:
        return const Color(0xFFCE93D8);
    }
  }

  Color resolve(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (this) {
      case HighlightColor.yellow:
        return isDark ? const Color(0x59FFC107) : const Color(0xFFFFF59D);
      case HighlightColor.green:
        return isDark ? const Color(0x594CAF50) : const Color(0xFFA5D6A7);
      case HighlightColor.blue:
        return isDark ? const Color(0x592196F3) : const Color(0xFF90CAF9);
      case HighlightColor.pink:
        return isDark ? const Color(0x59E91E63) : const Color(0xFFF48FB1);
      case HighlightColor.purple:
        return isDark ? const Color(0x599C27B0) : const Color(0xFFCE93D8);
    }
  }

  static HighlightColor fromString(String? name) {
    return HighlightColor.values.firstWhere(
      (c) => c.name == name,
      orElse: () => HighlightColor.yellow,
    );
  }
}

class Highlight {
  final String id;
  final int bookId;
  final int chapter;
  final int startWordId;
  final int endWordId;
  final HighlightColor color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Highlight({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.startWordId,
    required this.endWordId,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(startWordId <= endWordId);

  Highlight copyWith({
    String? id,
    int? bookId,
    int? chapter,
    int? startWordId,
    int? endWordId,
    HighlightColor? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Highlight(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      startWordId: startWordId ?? this.startWordId,
      endWordId: endWordId ?? this.endWordId,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'chapter': chapter,
      'start_word_id': startWordId,
      'end_word_id': endWordId,
      'color': color.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Highlight.fromMap(Map<String, dynamic> map) {
    final rawColor = map['color'];
    HighlightColor color;
    if (rawColor is String) {
      color = HighlightColor.fromString(rawColor);
    } else if (rawColor is int &&
        rawColor >= 0 &&
        rawColor < HighlightColor.values.length) {
      color = HighlightColor.values[rawColor];
    } else {
      color = HighlightColor.yellow;
    }

    return Highlight(
      id: map['id'] as String,
      bookId: map['book_id'] as int,
      chapter: map['chapter'] as int,
      startWordId: map['start_word_id'] as int,
      endWordId: map['end_word_id'] as int,
      color: color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  HighlightRange toHighlightRange(Brightness brightness) {
    return HighlightRange(
      startId: startWordId,
      endId: endWordId,
      color: color.resolve(brightness),
    );
  }
}

class Note {
  final String id;
  final int bookId;
  final int chapter;
  final int startWordId;
  final int endWordId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.startWordId,
    required this.endWordId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(startWordId <= endWordId);

  Note copyWith({
    String? id,
    int? bookId,
    int? chapter,
    int? startWordId,
    int? endWordId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      startWordId: startWordId ?? this.startWordId,
      endWordId: endWordId ?? this.endWordId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'chapter': chapter,
      'start_word_id': startWordId,
      'end_word_id': endWordId,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      bookId: map['book_id'] as int,
      chapter: map['chapter'] as int,
      startWordId: map['start_word_id'] as int,
      endWordId: map['end_word_id'] as int,
      content: map['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  NoteMarker toNoteMarker() {
    return NoteMarker(
      id: id,
      wordId: endWordId,
    );
  }
}
