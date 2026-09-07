import 'package:database_builder/database_builder.dart';
import 'package:uuid/uuid.dart';

class BibleTab {
  BibleTab({
    String? id,
    required this.bookId,
    required this.chapter,
    this.sectionHeading,
    this.targetVerse,
    this.scrollOffset = 0.0,
  }) : id = id ?? const Uuid().v4();

  final String id;
  int bookId;
  int chapter;
  String? sectionHeading;
  int? targetVerse;
  double scrollOffset;

  String get label {
    final abbrev = bookIdToAbbreviationMap[bookId] ?? '';
    return '$abbrev $chapter';
  }

  String get fullTitle {
    final book = bookIdToFullNameMap[bookId] ?? '';
    return '$book $chapter';
  }

  BibleTab copyWith({
    String? id,
    int? bookId,
    int? chapter,
    String? sectionHeading,
    int? targetVerse,
    double? scrollOffset,
  }) {
    return BibleTab(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      sectionHeading: sectionHeading ?? this.sectionHeading,
      targetVerse: targetVerse ?? this.targetVerse,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapter': chapter,
      if (sectionHeading != null) 'sectionHeading': sectionHeading,
      if (targetVerse != null) 'targetVerse': targetVerse,
      'scrollOffset': scrollOffset,
    };
  }

  factory BibleTab.fromJson(Map<String, dynamic> json) {
    return BibleTab(
      id: json['id'] as String?,
      bookId: json['bookId'] as int,
      chapter: json['chapter'] as int,
      sectionHeading: json['sectionHeading'] as String?,
      targetVerse: json['targetVerse'] as int?,
      scrollOffset: (json['scrollOffset'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleTab &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
