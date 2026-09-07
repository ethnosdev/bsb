import 'package:database_builder/database_builder.dart';
import 'search_models.dart';

class ScriptureReferenceParser {
  static const Set<int> singleChapterBookIds = {31, 57, 63, 64, 65};

  static final Map<String, int> _bookLookup = _buildBookLookup();

  static Map<String, int> _buildBookLookup() {
    final map = <String, int>{};

    void add(String key, int id) {
      map[key.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim()] = id;
    }

    // Populate from bookIdToFullNameMap
    for (final entry in bookIdToFullNameMap.entries) {
      add(entry.value, entry.key);
    }

    // Populate from bookAbbreviationToIdMap
    for (final entry in bookAbbreviationToIdMap.entries) {
      add(entry.key, entry.value);
    }

    // Canonical names and aliases
    const aliases = <String, int>{
      // OT
      'gen': 1, 'ge': 1, 'gn': 1,
      'exo': 2, 'ex': 2, 'exod': 2,
      'lev': 3, 'le': 3, 'lv': 3,
      'num': 4, 'nu': 4, 'nm': 4, 'nb': 4,
      'deut': 5, 'deu': 5, 'dt': 5,
      'josh': 6, 'jos': 6, 'jsh': 6,
      'judg': 7, 'jdg': 7, 'jg': 7, 'jdgs': 7,
      'ruth': 8, 'rut': 8, 'rth': 8, 'ru': 8,
      '1 samuel': 9, '1 sam': 9, '1 sa': 9, '1sam': 9, '1sa': 9, '1s': 9, 'i samuel': 9, 'i sam': 9, 'i sa': 9,
      '2 samuel': 10, '2 sam': 10, '2 sa': 10, '2sam': 10, '2sa': 10, '2s': 10, 'ii samuel': 10, 'ii sam': 10, 'ii sa': 10,
      '1 kings': 11, '1 kgs': 11, '1 ki': 11, '1ki': 11, '1kgs': 11, '1k': 11, 'i kings': 11, 'i kgs': 11, 'i ki': 11,
      '2 kings': 12, '2 kgs': 12, '2 ki': 12, '2ki': 12, '2kgs': 12, '2k': 12, 'ii kings': 12, 'ii kgs': 12, 'ii ki': 12,
      '1 chronicles': 13, '1 chron': 13, '1 chr': 13, '1 ch': 13, '1chron': 13, '1chr': 13, '1ch': 13, 'i chronicles': 13, 'i chron': 13, 'i chr': 13,
      '2 chronicles': 14, '2 chron': 14, '2 chr': 14, '2 ch': 14, '2chron': 14, '2chr': 14, '2ch': 14, 'ii chronicles': 14, 'ii chron': 14, 'ii chr': 14,
      'ezra': 15, 'ezr': 15,
      'nehemiah': 16, 'neh': 16, 'ne': 16,
      'esther': 17, 'esth': 17, 'est': 17, 'es': 17,
      'job': 18, 'jb': 18,
      'psalms': 19, 'psalm': 19, 'psa': 19, 'ps': 19, 'pss': 19,
      'proverbs': 20, 'proverb': 20, 'prov': 20, 'pro': 20, 'prv': 20, 'pr': 20,
      'ecclesiastes': 21, 'eccles': 21, 'ecc': 21, 'ec': 21, 'qoh': 21,
      'song of solomon': 22, 'song of songs': 22, 'songs': 22, 'song': 22, 'sng': 22, 'sos': 22, 'canticles': 22,
      'isaiah': 23, 'isa': 23, 'is': 23,
      'jeremiah': 24, 'jer': 24, 'jrm': 24,
      'lamentations': 25, 'lam': 25, 'la': 25,
      'ezekiel': 26, 'ezek': 26, 'ezk': 26, 'eze': 26,
      'daniel': 27, 'dan': 27, 'dn': 27,
      'hosea': 28, 'hos': 28, 'ho': 28,
      'joel': 29, 'joe': 29, 'jol': 29, 'jl': 29,
      'amos': 30, 'amo': 30, 'am': 30,
      'obadiah': 31, 'obad': 31, 'oba': 31, 'ob': 31,
      'jonah': 32, 'jon': 32, 'jnh': 32,
      'micah': 33, 'mic': 33, 'mc': 33,
      'nahum': 34, 'nah': 34, 'na': 34, 'nam': 34,
      'habakkuk': 35, 'hab': 35, 'hb': 35,
      'zephaniah': 36, 'zeph': 36, 'zep': 36, 'zp': 36,
      'haggai': 37, 'hag': 37, 'hg': 37,
      'zechariah': 38, 'zech': 38, 'zec': 38, 'zc': 38,
      'malachi': 39, 'mal': 39, 'ml': 39,

      // NT
      'matthew': 40, 'matt': 40, 'mat': 40, 'mt': 40,
      'mark': 41, 'mrk': 41, 'mar': 41, 'mk': 41,
      'luke': 42, 'luk': 42, 'lk': 42, 'lu': 42,
      'john': 43, 'jhn': 43, 'joh': 43, 'jn': 43,
      'acts': 44, 'act': 44, 'ac': 44,
      'romans': 45, 'roman': 45, 'rom': 45, 'ro': 45, 'rm': 45,
      '1 corinthians': 46, '1 cor': 46, '1 co': 46, '1cor': 46, '1co': 46, '1c': 46, 'i corinthians': 46, 'i cor': 46, 'i co': 46,
      '2 corinthians': 47, '2 cor': 47, '2 co': 47, '2cor': 47, '2co': 47, '2c': 47, 'ii corinthians': 47, 'ii cor': 47, 'ii co': 47,
      'galatians': 48, 'gal': 48, 'ga': 48,
      'ephesians': 49, 'ephes': 49, 'eph': 49, 'ep': 49,
      'philippians': 50, 'philip': 50, 'phil': 50, 'php': 50, 'pp': 50,
      'colossians': 51, 'coloss': 51, 'col': 51,
      '1 thessalonians': 52, '1 thess': 52, '1 th': 52, '1thess': 52, '1th': 52, 'i thessalonians': 52, 'i thess': 52, 'i th': 52,
      '2 thessalonians': 53, '2 thess': 53, '2 th': 53, '2thess': 53, '2th': 53, 'ii thessalonians': 53, 'ii thess': 53, 'ii th': 53,
      '1 timothy': 54, '1 tim': 54, '1 ti': 54, '1tim': 54, '1ti': 54, 'i timothy': 54, 'i tim': 54, 'i ti': 54,
      '2 timothy': 55, '2 tim': 55, '2 ti': 55, '2tim': 55, '2ti': 55, 'ii timothy': 55, 'ii tim': 55, 'ii ti': 55,
      'titus': 56, 'tit': 56, 'ti': 56,
      'philemon': 57, 'philem': 57, 'phm': 57, 'phlm': 57, 'pm': 57,
      'hebrews': 58, 'hebrew': 58, 'heb': 58, 'he': 58,
      'james': 59, 'jas': 59, 'jam': 59, 'jm': 59,
      '1 peter': 60, '1 pet': 60, '1 pe': 60, '1 pt': 60, '1peter': 60, '1pet': 60, '1pe': 60, '1pt': 60, 'i peter': 60, 'i pet': 60, 'i pe': 60,
      '2 peter': 61, '2 pet': 61, '2 pe': 61, '2 pt': 61, '2peter': 61, '2pet': 61, '2pe': 61, '2pt': 61, 'ii peter': 61, 'ii pet': 61, 'ii pe': 61,
      '1 john': 62, '1 jhn': 62, '1 jn': 62, '1john': 62, '1jhn': 62, '1jn': 62, '1j': 62, 'i john': 62, 'i jhn': 62, 'i jn': 62,
      '2 john': 63, '2 jhn': 63, '2 jn': 63, '2john': 63, '2jhn': 63, '2jn': 63, '2j': 63, 'ii john': 63, 'ii jhn': 63, 'ii jn': 63,
      '3 john': 64, '3 jhn': 64, '3 jn': 64, '3john': 64, '3jhn': 64, '3jn': 64, '3j': 64, 'iii john': 64, 'iii jhn': 64, 'iii jn': 64,
      'jude': 65, 'jud': 65, 'jd': 65,
      'revelation': 66, 'revelations': 66, 'rev': 66, 're': 66,
    };

    for (final entry in aliases.entries) {
      add(entry.key, entry.value);
    }

    return map;
  }

  /// Parses a string that might be a scripture reference.
  /// Returns a [ParsedReference] if valid, or null if it does not match reference syntax.
  static ParsedReference? tryParse(String query) {
    var raw = query.trim();
    if (raw.isEmpty) return null;

    // Normalizing hyphens and spaces
    raw = raw.replaceAll('–', '-').replaceAll('—', '-');

    // Pattern 1: Book followed by Chapter:Verse[-EndVerse] or Chapter.Verse or Chapter Verse
    // e.g. "John 3:16", "Jn 3.16", "1 Cor 13:4-7", "Romans 8 28"
    final cvRegex = RegExp(
      r'^([1-3iI]{1,3}\s*)?([a-zA-Z\s]+?)\s*(\d+)(?:[:.\s](\d+)(?:-(\d+))?)?$',
    );

    final match = cvRegex.firstMatch(raw);
    if (match == null) return null;

    final prefix = match.group(1) ?? '';
    final namePart = match.group(2) ?? '';
    final num1Str = match.group(3);
    final num2Str = match.group(4);
    final endVerseStr = match.group(5);

    if (num1Str == null) return null;

    final fullBookStr = (prefix + namePart)
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final bookId = _bookLookup[fullBookStr];
    if (bookId == null) return null;

    final num1 = int.tryParse(num1Str);
    if (num1 == null || num1 <= 0) return null;

    final maxChapters = bookIdToChapterCountMap[bookId] ?? 150;

    // Special case: Single chapter books (Obadiah, Philemon, 2 John, 3 John, Jude)
    // If user writes "Jude 5", chapter=1, verse=5
    if (singleChapterBookIds.contains(bookId)) {
      if (num2Str == null) {
        if (num1 > 1) {
          // Jude 5 -> chapter 1, verse 5
          return ParsedReference(
            bookId: bookId,
            chapter: 1,
            verse: num1,
            isExactVerse: true,
          );
        } else {
          // Jude 1 -> chapter 1, verse null
          return ParsedReference(
            bookId: bookId,
            chapter: 1,
            verse: null,
            isExactVerse: false,
          );
        }
      } else {
        // Jude 1:5 -> chapter 1, verse 5
        final verse = int.tryParse(num2Str);
        final endVerse = endVerseStr != null ? int.tryParse(endVerseStr) : null;
        return ParsedReference(
          bookId: bookId,
          chapter: 1,
          verse: verse,
          endVerse: endVerse,
          isExactVerse: verse != null,
        );
      }
    }

    if (num2Str == null) {
      // Chapter only (e.g. "John 3", "Psalm 23")
      if (num1 > maxChapters) return null;
      return ParsedReference(
        bookId: bookId,
        chapter: num1,
        verse: null,
        isExactVerse: false,
      );
    } else {
      // Chapter and Verse (e.g. "John 3:16")
      if (num1 > maxChapters) return null;
      final verse = int.tryParse(num2Str);
      if (verse == null || verse <= 0) return null;
      final endVerse = endVerseStr != null ? int.tryParse(endVerseStr) : null;

      return ParsedReference(
        bookId: bookId,
        chapter: num1,
        verse: verse,
        endVerse: endVerse,
        isExactVerse: true,
      );
    }
  }
}
