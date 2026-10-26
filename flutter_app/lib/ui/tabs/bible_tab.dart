import 'package:database_builder/database_builder.dart';
import 'package:uuid/uuid.dart';

class BibleTab {
  BibleTab({
    String? id,
    this.bookId,
    this.chapter,
    this.sectionHeading,
    this.targetVerse,
    this.playlistId,
    this.playlistTitle,
    this.scrollOffset = 0.0,
  }) : id = id ?? const Uuid().v4();

  final String id;
  int? bookId;
  int? chapter;
  String? sectionHeading;
  int? targetVerse;
  String? playlistId;
  String? playlistTitle;
  double scrollOffset;

  bool get isPlaylist => playlistId != null;
  bool get isChapter => !isPlaylist;

  String get label {
    if (isPlaylist) {
      return playlistTitle ?? 'Playlist';
    }
    final abbrev = bookIdToAbbreviationMap[bookId] ?? '';
    return '$abbrev $chapter';
  }

  String get fullTitle {
    if (isPlaylist) {
      return playlistTitle ?? 'Playlist';
    }
    final book = bookIdToFullNameMap[bookId] ?? '';
    return '$book $chapter';
  }

  BibleTab copyWith({
    String? id,
    int? bookId,
    int? chapter,
    String? sectionHeading,
    int? targetVerse,
    String? playlistId,
    String? playlistTitle,
    double? scrollOffset,
  }) {
    return BibleTab(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      sectionHeading: sectionHeading ?? this.sectionHeading,
      targetVerse: targetVerse ?? this.targetVerse,
      playlistId: playlistId ?? this.playlistId,
      playlistTitle: playlistTitle ?? this.playlistTitle,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (bookId != null) 'bookId': bookId,
      if (chapter != null) 'chapter': chapter,
      if (sectionHeading != null) 'sectionHeading': sectionHeading,
      if (targetVerse != null) 'targetVerse': targetVerse,
      if (playlistId != null) 'playlistId': playlistId,
      if (playlistTitle != null) 'playlistTitle': playlistTitle,
      'scrollOffset': scrollOffset,
    };
  }

  factory BibleTab.fromJson(Map<String, dynamic> json) {
    return BibleTab(
      id: json['id'] as String?,
      bookId: json['bookId'] as int?,
      chapter: json['chapter'] as int?,
      sectionHeading: json['sectionHeading'] as String?,
      targetVerse: json['targetVerse'] as int?,
      playlistId: json['playlistId'] as String?,
      playlistTitle: json['playlistTitle'] as String?,
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
