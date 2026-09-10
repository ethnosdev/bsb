import 'package:database_builder/database_builder.dart';

/// Mapping of canonical book IDs (1 to 66) to OpenBible Souer file prefixes.
const Map<int, String> bookIdToSouerPrefix = {
  1: 'BSB_01_Gen',
  2: 'BSB_02_Exo',
  3: 'BSB_03_Lev',
  4: 'BSB_04_Num',
  5: 'BSB_05_Deu',
  6: 'BSB_06_Jos',
  7: 'BSB_07_Jdg',
  8: 'BSB_08_Rut',
  9: 'BSB_09_1Sa',
  10: 'BSB_10_2Sa',
  11: 'BSB_11_1Ki',
  12: 'BSB_12_2Ki',
  13: 'BSB_13_1Ch',
  14: 'BSB_14_2Ch',
  15: 'BSB_15_Ezr',
  16: 'BSB_16_Neh',
  17: 'BSB_17_Est',
  18: 'BSB_18_Job',
  19: 'BSB_19_Psa',
  20: 'BSB_20_Pro',
  21: 'BSB_21_Ecc',
  22: 'BSB_22_Sng',
  23: 'BSB_23_Isa',
  24: 'BSB_24_Jer',
  25: 'BSB_25_Lam',
  26: 'BSB_26_Ezk',
  27: 'BSB_27_Dan',
  28: 'BSB_28_Hos',
  29: 'BSB_29_Jol',
  30: 'BSB_30_Amo',
  31: 'BSB_31_Oba',
  32: 'BSB_32_Jon',
  33: 'BSB_33_Mic',
  34: 'BSB_34_Nam',
  35: 'BSB_35_Hab',
  36: 'BSB_36_Zep',
  37: 'BSB_37_Hag',
  38: 'BSB_38_Zec',
  39: 'BSB_39_Mal',
  40: 'BSB_40_Mat',
  41: 'BSB_41_Mrk',
  42: 'BSB_42_Luk',
  43: 'BSB_43_Jhn',
  44: 'BSB_44_Act',
  45: 'BSB_45_Rom',
  46: 'BSB_46_1Co',
  47: 'BSB_47_2Co',
  48: 'BSB_48_Gal',
  49: 'BSB_49_Eph',
  50: 'BSB_50_Php',
  51: 'BSB_51_Col',
  52: 'BSB_52_1Th',
  53: 'BSB_53_2Th',
  54: 'BSB_54_1Ti',
  55: 'BSB_55_2Ti',
  56: 'BSB_56_Tts',
  57: 'BSB_57_Phm',
  58: 'BSB_58_Heb',
  59: 'BSB_59_Jas',
  60: 'BSB_60_1Pe',
  61: 'BSB_61_2Pe',
  62: 'BSB_62_1Jn',
  63: 'BSB_63_2Jn',
  64: 'BSB_64_3Jn',
  65: 'BSB_65_Jud',
  66: 'BSB_66_Rev',
};

class AudioUrlResolver {
  static const String defaultBaseUrl = 'https://openbible.com/audio/souer/';

  final String baseUrl;

  const AudioUrlResolver({this.baseUrl = defaultBaseUrl});

  /// Resolves the streaming audio URL for a given book and chapter.
  String getChapterUrl(int bookId, int chapter) {
    final prefix = bookIdToSouerPrefix[bookId];
    if (prefix == null) {
      throw ArgumentError('Invalid bookId: $bookId');
    }
    final paddedChapter = chapter.toString().padLeft(3, '0');
    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return '$cleanBase${prefix}_$paddedChapter.mp3';
  }

  /// Formats the chapter title (e.g. "Genesis 1").
  String getChapterTitle(int bookId, int chapter) {
    final bookName = bookIdToFullNameMap[bookId] ?? 'Book $bookId';
    return '$bookName $chapter';
  }

  /// Calculates the next chapter (advancing across books if needed).
  /// Returns `null` if at Revelation 22 (end of the Bible).
  (int, int)? getNextChapter(int bookId, int chapter) {
    final totalChapters = bookIdToChapterCountMap[bookId] ?? 1;
    if (chapter < totalChapters) {
      return (bookId, chapter + 1);
    } else if (bookId < 66) {
      return (bookId + 1, 1);
    }
    return null;
  }

  /// Calculates the previous chapter (moving to previous book if needed).
  /// Returns `null` if at Genesis 1.
  (int, int)? getPreviousChapter(int bookId, int chapter) {
    if (chapter > 1) {
      return (bookId, chapter - 1);
    } else if (bookId > 1) {
      final prevBookId = bookId - 1;
      final prevTotal = bookIdToChapterCountMap[prevBookId] ?? 1;
      return (prevBookId, prevTotal);
    }
    return null;
  }
}
