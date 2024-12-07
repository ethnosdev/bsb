import 'package:flutter/painting.dart';

/// Bible repository.
///
/// This class is responsible for retrieving formatted Bible text from a
/// data source.
abstract interface class BibleRepo {
  /// Get a chapter from the Bible.
  ///
  /// The [book] parameter is the book number. The [chapter] parameter is the
  /// chapter number.
  ///
  /// Each verse should be clickable and footnote markers should be clickable
  /// and should display the footnote text.
  Future<TextSpan> getChapter({required int book, required int chapter});

  /// Search for a string in the Bible.
  ///
  /// Returns a list of verses lines that match the search term. The matched
  /// text is highlighted with the [highlightColor].
  Future<List<TextSpan>> search({
    required String searchTerm,
    required Color highlightColor,
  });
}
