import '../database.dart';
import '../reference.dart';
import 'scripture_reference_parser.dart';
import 'search_models.dart';

class BibleSearchService {
  final DatabaseHelper dbHelper;

  BibleSearchService({required this.dbHelper});

  ParsedReference? parseReference(String query) {
    return ScriptureReferenceParser.tryParse(query);
  }

  Future<String?> getVerseText(Reference reference) async {
    return dbHelper.getVerseText(reference.packedVerse);
  }

  Future<List<SearchResult>> searchVerses({
    required String query,
    SearchScope scope = SearchScope.all,
    int? specificBookId,
    int? limit,
    bool isExact = false,
  }) async {
    final rawResults = await dbHelper.searchVerses(
      query: query,
      scope: scope,
      specificBookId: specificBookId,
      limit: limit,
      isExact: isExact,
    );

    return rawResults.map((result) {
      final spans = computeMatchSpans(result.text, query, isExact: isExact);
      return SearchResult(
        reference: result.reference,
        text: result.text,
        matchSpans: spans,
      );
    }).toList();
  }

  static List<(int, int)> computeMatchSpans(
    String text,
    String query, {
    bool isExact = false,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty || text.isEmpty) return const [];

    if (isExact) {
      var clean = trimmed;
      if (clean.startsWith('"') && clean.endsWith('"') && clean.length >= 2) {
        clean = clean.substring(1, clean.length - 1).trim();
      }
      clean = clean.replaceAll('"', '').trim();
      if (clean.isEmpty) return const [];

      final words = clean
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map(RegExp.escape)
          .join(r'\s+');
      if (words.isEmpty) return const [];

      final pattern = RegExp(r'\b' + words + r'\b', caseSensitive: false);
      final matches = pattern
          .allMatches(text)
          .map((m) => (m.start, m.end))
          .toList();
      if (matches.isNotEmpty) {
        return matches;
      }
      final fallbackPattern = RegExp(words, caseSensitive: false);
      return fallbackPattern
          .allMatches(text)
          .map((m) => (m.start, m.end))
          .toList();
    }

    final tokens = <String>[];
    final tokenRegex = RegExp(r'"([^"]+)"|(\S+)');
    for (final match in tokenRegex.allMatches(trimmed)) {
      final quoted = match.group(1);
      final unquoted = match.group(2);
      if (quoted != null && quoted.trim().isNotEmpty) {
        tokens.add(quoted.trim());
      } else if (unquoted != null) {
        final clean = unquoted.replaceAll(RegExp(r'[^\w]'), '');
        if (clean.isNotEmpty) {
          tokens.add(clean);
        }
      }
    }

    if (tokens.isEmpty) return const [];

    final allMatches = <(int, int)>[];
    for (final token in tokens) {
      final pattern = RegExp(RegExp.escape(token), caseSensitive: false);
      for (final m in pattern.allMatches(text)) {
        allMatches.add((m.start, m.end));
      }
    }

    if (allMatches.isEmpty) return const [];

    // Sort by start index
    allMatches.sort((a, b) => a.$1.compareTo(b.$1));

    // Merge overlapping or adjacent intervals
    final merged = <(int, int)>[];
    var current = allMatches.first;

    for (int i = 1; i < allMatches.length; i++) {
      final next = allMatches[i];
      if (next.$1 <= current.$2) {
        // Overlapping or touching
        final maxEnd = next.$2 > current.$2 ? next.$2 : current.$2;
        current = (current.$1, maxEnd);
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);

    return merged;
  }
}
