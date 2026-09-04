import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

/// Opens the SQLite database for testing, with helpful error messaging if missing.
Database openTestDatabase([String path = 'database.db']) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Database file not found at "$path". '
      'Run `dart run bin/main.dart` from database_builder first to generate it.',
    );
  }
  return sqlite3.open(path);
}

/// Helper functions for BBCCCVVV packed references
int unpackBook(int reference) => reference ~/ 1000000;
int unpackChapter(int reference) => (reference % 1000000) ~/ 1000;
int unpackVerse(int reference) => reference % 1000;
int packReference(int book, int chapter, int verse) =>
    book * 1000000 + chapter * 1000 + verse;

/// Canonical Bible Constants
const int kTotalBooks = 66;
const int kOldTestamentBooks = 39;
const int kNewTestamentBooks = 27;

const int kTotalChapters = 1189;
const int kOldTestamentChapters = 929;
const int kNewTestamentChapters = 260;

const int kTotalCanonicalVerses = 31086;
const int kOldTestamentVerses = 23145;
const int kNewTestamentVerses = 7941;

/// Total canonical verses in interlinear table.
/// Nehemiah 7:68 (16007068) is not in MT / Hebrew interlinear sources,
/// resulting in 31,085 verses.
const int kInterlinearCanonicalVerses = 31085;
const int kNehemiah7Verse68 = 16007068;

/// Standard Protestant canon chapter counts for books 1..66
const Map<int, int> kExpectedChaptersPerBook = {
  1: 50, // Genesis
  2: 40, // Exodus
  3: 27, // Leviticus
  4: 36, // Numbers
  5: 34, // Deuteronomy
  6: 24, // Joshua
  7: 21, // Judges
  8: 4,  // Ruth
  9: 31, // 1 Samuel
  10: 24, // 2 Samuel
  11: 22, // 1 Kings
  12: 25, // 2 Kings
  13: 29, // 1 Chronicles
  14: 36, // 2 Chronicles
  15: 10, // Ezra
  16: 13, // Nehemiah
  17: 10, // Esther
  18: 42, // Job
  19: 150, // Psalms
  20: 31, // Proverbs
  21: 12, // Ecclesiastes
  22: 8,  // Song of Solomon
  23: 66, // Isaiah
  24: 52, // Jeremiah
  25: 5,  // Lamentations
  26: 48, // Ezekiel
  27: 12, // Daniel
  28: 14, // Hosea
  29: 3,  // Joel
  30: 9,  // Amos
  31: 1,  // Obadiah
  32: 4,  // Jonah
  33: 7,  // Micah
  34: 3,  // Nahum
  35: 3,  // Habakkuk
  36: 3,  // Zephaniah
  37: 2,  // Haggai
  38: 14, // Zechariah
  39: 4,  // Malachi
  40: 28, // Matthew
  41: 16, // Mark
  42: 24, // Luke
  43: 21, // John
  44: 28, // Acts
  45: 16, // Romans
  46: 16, // 1 Corinthians
  47: 13, // 2 Corinthians
  48: 6,  // Galatians
  49: 6,  // Ephesians
  50: 4,  // Philippians
  51: 4,  // Colossians
  52: 5,  // 1 Thessalonians
  53: 3,  // 2 Thessalonians
  54: 6,  // 1 Timothy
  55: 4,  // 2 Timothy
  56: 3,  // Titus
  57: 1,  // Philemon
  58: 13, // Hebrews
  59: 5,  // James
  60: 5,  // 1 Peter
  61: 3,  // 2 Peter
  62: 5,  // 1 John
  63: 1,  // 2 John
  64: 1,  // 3 John
  65: 1,  // Jude
  66: 22, // Revelation
};

/// Standard Protestant canon verse counts for books 1..66 in the BSB
const Map<int, int> kExpectedVersesPerBook = {
  1: 1533, // Genesis
  2: 1213, // Exodus
  3: 859,  // Leviticus
  4: 1288, // Numbers
  5: 959,  // Deuteronomy
  6: 658,  // Joshua
  7: 618,  // Judges
  8: 85,   // Ruth
  9: 810,  // 1 Samuel
  10: 695, // 2 Samuel
  11: 816, // 1 Kings
  12: 719, // 2 Kings
  13: 942, // 1 Chronicles
  14: 822, // 2 Chronicles
  15: 280, // Ezra
  16: 406, // Nehemiah
  17: 167, // Esther
  18: 1070, // Job
  19: 2461, // Psalms
  20: 915, // Proverbs
  21: 222, // Ecclesiastes
  22: 117, // Song of Solomon
  23: 1292, // Isaiah
  24: 1364, // Jeremiah
  25: 154, // Lamentations
  26: 1273, // Ezekiel
  27: 357, // Daniel
  28: 197, // Hosea
  29: 73,  // Joel
  30: 146, // Amos
  31: 21,  // Obadiah
  32: 48,  // Jonah
  33: 105, // Micah
  34: 47,  // Nahum
  35: 56,  // Habakkuk
  36: 53,  // Zephaniah
  37: 38,  // Haggai
  38: 211, // Zechariah
  39: 55,  // Malachi
  40: 1068, // Matthew
  41: 673, // Mark
  42: 1149, // Luke
  43: 878, // John
  44: 1003, // Acts
  45: 432, // Romans
  46: 437, // 1 Corinthians
  47: 257, // 2 Corinthians
  48: 149, // Galatians
  49: 155, // Ephesians
  50: 104, // Philippians
  51: 95,  // Colossians
  52: 89,  // 1 Thessalonians
  53: 47,  // 2 Thessalonians
  54: 113, // 1 Timothy
  55: 83,  // 2 Timothy
  56: 46,  // Titus
  57: 25,  // Philemon
  58: 303, // Hebrews
  59: 108, // James
  60: 105, // 1 Peter
  61: 61,  // 2 Peter
  62: 105, // 1 John
  63: 13,  // 2 John
  64: 14,  // 3 John
  65: 25,  // Jude
  66: 404, // Revelation
};
