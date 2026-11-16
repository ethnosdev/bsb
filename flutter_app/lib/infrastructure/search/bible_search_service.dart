import '../database.dart';
import '../reference.dart';
import 'search_models.dart';

class _ParsedQueryTokens {
  const _ParsedQueryTokens({
    required this.exactPhrases,
    required this.unquotedTokens,
  });

  final List<String> exactPhrases;
  final List<String> unquotedTokens;

  bool get isEmpty => exactPhrases.isEmpty && unquotedTokens.isEmpty;
}

class BibleSearchService {
  final DatabaseHelper dbHelper;

  BibleSearchService({required this.dbHelper});

  bool get useBritishSpelling => dbHelper.useBritishSpelling;

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
    final isBritish = dbHelper.useBritishSpelling;
    final rawResults = await dbHelper.searchVerses(
      query: query,
      scope: scope,
      specificBookId: specificBookId,
      limit: isBritish ? null : limit,
      isExact: isExact,
    );

    final results = <SearchResult>[];
    for (final result in rawResults) {
      if (isBritish &&
          !matchesLocalizedText(result.text, query, isExact: isExact)) {
        continue;
      }
      final spans = computeMatchSpans(
        result.text,
        query,
        isExact: isExact,
        strictExactBoundary: isBritish,
      );
      if (isBritish && spans.isEmpty) {
        continue;
      }
      results.add(
        SearchResult(
          reference: result.reference,
          text: result.text,
          matchSpans: spans,
        ),
      );
      if (isBritish && limit != null && limit > 0 && results.length >= limit) {
        break;
      }
    }
    return results;
  }

  static _ParsedQueryTokens _parseQueryTokens(
    String query, {
    bool isExact = false,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const _ParsedQueryTokens(exactPhrases: [], unquotedTokens: []);
    }

    if (isExact) {
      var clean = trimmed;
      if (clean.startsWith('"') && clean.endsWith('"') && clean.length >= 2) {
        clean = clean.substring(1, clean.length - 1).trim();
      }
      clean = clean.replaceAll('"', '').trim();
      if (clean.isEmpty || !RegExp(r'\w').hasMatch(clean)) {
        return const _ParsedQueryTokens(exactPhrases: [], unquotedTokens: []);
      }
      return _ParsedQueryTokens(
        exactPhrases: [clean],
        unquotedTokens: const [],
      );
    }

    final exactPhrases = <String>[];
    final unquotedTokens = <String>[];
    final tokenRegex = RegExp(r'"([^"]+)"|(\S+)');
    for (final match in tokenRegex.allMatches(trimmed)) {
      final quoted = match.group(1);
      final unquoted = match.group(2);
      if (quoted != null) {
        final cleanQuoted = quoted.trim();
        if (cleanQuoted.isNotEmpty && RegExp(r'\w').hasMatch(cleanQuoted)) {
          exactPhrases.add(cleanQuoted);
        }
      } else if (unquoted != null) {
        final clean = unquoted.replaceAll(RegExp(r'[^\w]'), '');
        if (clean.isNotEmpty) {
          unquotedTokens.add(clean);
        }
      }
    }
    return _ParsedQueryTokens(
      exactPhrases: exactPhrases,
      unquotedTokens: unquotedTokens,
    );
  }

  static RegExp? _buildExactPhraseRegex(String phrase) {
    final words = phrase
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map(RegExp.escape)
        .join(r'\s+');
    if (words.isEmpty) return null;
    return RegExp(r'\b' + words + r'\b', caseSensitive: false);
  }

  static bool matchesLocalizedText(
    String localizedText,
    String query, {
    bool isExact = false,
  }) {
    if (localizedText.isEmpty) return false;
    final parsed = _parseQueryTokens(query, isExact: isExact);
    if (parsed.isEmpty) return false;

    for (final phrase in parsed.exactPhrases) {
      final regex = _buildExactPhraseRegex(phrase);
      if (regex == null || !regex.hasMatch(localizedText)) {
        return false;
      }
    }
    for (final token in parsed.unquotedTokens) {
      final regex = RegExp(r'\b' + RegExp.escape(token), caseSensitive: false);
      if (!regex.hasMatch(localizedText)) {
        return false;
      }
    }
    return true;
  }

  static List<(int, int)> computeMatchSpans(
    String text,
    String query, {
    bool isExact = false,
    bool strictExactBoundary = false,
  }) {
    if (text.isEmpty) return const [];
    final parsed = _parseQueryTokens(query, isExact: isExact);
    if (parsed.isEmpty) return const [];

    if (isExact) {
      final clean = parsed.exactPhrases.first;
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
      if (matches.isNotEmpty || strictExactBoundary) {
        return matches;
      }
      final fallbackPattern = RegExp(words, caseSensitive: false);
      return fallbackPattern
          .allMatches(text)
          .map((m) => (m.start, m.end))
          .toList();
    }

    final allMatches = <(int, int)>[];
    for (final phrase in parsed.exactPhrases) {
      final pattern = strictExactBoundary
          ? _buildExactPhraseRegex(phrase)
          : RegExp(RegExp.escape(phrase), caseSensitive: false);
      if (pattern == null) continue;
      for (final m in pattern.allMatches(text)) {
        allMatches.add((m.start, m.end));
      }
    }
    for (final token in parsed.unquotedTokens) {
      final pattern = strictExactBoundary
          ? RegExp(r'\b' + RegExp.escape(token), caseSensitive: false)
          : RegExp(RegExp.escape(token), caseSensitive: false);
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
