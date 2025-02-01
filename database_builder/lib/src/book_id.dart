final bookAbbreviationToIdMap = {
  'GEN': 1,
  'EXO': 2,
  'LEV': 3,
  'NUM': 4,
  'DEU': 5,
  'JOS': 6,
  'JDG': 7,
  'RUT': 8,
  '1SA': 9,
  '2SA': 10,
  '1KI': 11,
  '2KI': 12,
  '1CH': 13,
  '2CH': 14,
  'EZR': 15,
  'NEH': 16,
  'EST': 17,
  'JOB': 18,
  'PSA': 19,
  'PRO': 20,
  'ECC': 21,
  'SNG': 22,
  'ISA': 23,
  'JER': 24,
  'LAM': 25,
  'EZK': 26,
  'DAN': 27,
  'HOS': 28,
  'JOL': 29,
  'AMO': 30,
  'OBA': 31,
  'JON': 32,
  'MIC': 33,
  'NAM': 34,
  'HAB': 35,
  'ZEP': 36,
  'HAG': 37,
  'ZEC': 38,
  'MAL': 39,
  'MAT': 40,
  'MRK': 41,
  'LUK': 42,
  'JHN': 43,
  'ACT': 44,
  'ROM': 45,
  '1CO': 46,
  '2CO': 47,
  'GAL': 48,
  'EPH': 49,
  'PHP': 50,
  'COL': 51,
  '1TH': 52,
  '2TH': 53,
  '1TI': 54,
  '2TI': 55,
  'TIT': 56,
  'PHM': 57,
  'HEB': 58,
  'JAS': 59,
  '1PE': 60,
  '2PE': 61,
  '1JN': 62,
  '2JN': 63,
  '3JN': 64,
  'JUD': 65,
  'REV': 66
};

const bookIdToFullNameMap = {
  1: 'Genesis',
  2: 'Exodus',
  3: 'Leviticus',
  4: 'Numbers',
  5: 'Deuteronomy',
  6: 'Joshua',
  7: 'Judges',
  8: 'Ruth',
  9: '1 Samuel',
  10: '2 Samuel',
  11: '1 Kings',
  12: '2 Kings',
  13: '1 Chronicles',
  14: '2 Chronicles',
  15: 'Ezra',
  16: 'Nehemiah',
  17: 'Esther',
  18: 'Job',
  19: 'Psalm',
  20: 'Proverbs',
  21: 'Ecclesiastes',
  22: 'Song of Solomon',
  23: 'Isaiah',
  24: 'Jeremiah',
  25: 'Lamentations',
  26: 'Ezekiel',
  27: 'Daniel',
  28: 'Hosea',
  29: 'Joel',
  30: 'Amos',
  31: 'Obadiah',
  32: 'Jonah',
  33: 'Micah',
  34: 'Nahum',
  35: 'Habakkuk',
  36: 'Zephaniah',
  37: 'Haggai',
  38: 'Zechariah',
  39: 'Malachi',
  40: 'Matthew',
  41: 'Mark',
  42: 'Luke',
  43: 'John',
  44: 'Acts',
  45: 'Romans',
  46: '1 Corinthians',
  47: '2 Corinthians',
  48: 'Galatians',
  49: 'Ephesians',
  50: 'Philippians',
  51: 'Colossians',
  52: '1 Thessalonians',
  53: '2 Thessalonians',
  54: '1 Timothy',
  55: '2 Timothy',
  56: 'Titus',
  57: 'Philemon',
  58: 'Hebrews',
  59: 'James',
  60: '1 Peter',
  61: '2 Peter',
  62: '1 John',
  63: '2 John',
  64: '3 John',
  65: 'Jude',
  66: 'Revelation'
};

const fullNameToBookIdMap = {
  'Genesis': 1,
  'Exodus': 2,
  'Leviticus': 3,
  'Numbers': 4,
  'Deuteronomy': 5,
  'Joshua': 6,
  'Judges': 7,
  'Ruth': 8,
  '1 Samuel': 9,
  '2 Samuel': 10,
  '1 Kings': 11,
  '2 Kings': 12,
  '1 Chronicles': 13,
  '2 Chronicles': 14,
  'Ezra': 15,
  'Nehemiah': 16,
  'Esther': 17,
  'Job': 18,
  'Psalms': 19,
  'Proverbs': 20,
  'Ecclesiastes': 21,
  'Song of Solomon': 22,
  'Isaiah': 23,
  'Jeremiah': 24,
  'Lamentations': 25,
  'Ezekiel': 26,
  'Daniel': 27,
  'Hosea': 28,
  'Joel': 29,
  'Amos': 30,
  'Obadiah': 31,
  'Jonah': 32,
  'Micah': 33,
  'Nahum': 34,
  'Habakkuk': 35,
  'Zephaniah': 36,
  'Haggai': 37,
  'Zechariah': 38,
  'Malachi': 39,
  'Matthew': 40,
  'Mark': 41,
  'Luke': 42,
  'John': 43,
  'Acts': 44,
  'Romans': 45,
  '1 Corinthians': 46,
  '2 Corinthians': 47,
  'Galatians': 48,
  'Ephesians': 49,
  'Philippians': 50,
  'Colossians': 51,
  '1 Thessalonians': 52,
  '2 Thessalonians': 53,
  '1 Timothy': 54,
  '2 Timothy': 55,
  'Titus': 56,
  'Philemon': 57,
  'Hebrews': 58,
  'James': 59,
  '1 Peter': 60,
  '2 Peter': 61,
  '1 John': 62,
  '2 John': 63,
  '3 John': 64,
  'Jude': 65,
  'Revelation': 66
};

final bookIdToChapterIndexMap = {
  1: 0, // Genesis
  2: 50, // Exodus
  3: 90, // Leviticus
  4: 117, // Numbers
  5: 153, // Deuteronomy
  6: 187, // Joshua
  7: 211, // Judges
  8: 232, // Ruth
  9: 236, // 1 Samuel
  10: 267, // 2 Samuel
  11: 291, // 1 Kings
  12: 313, // 2 Kings
  13: 338, // 1 Chronicles
  14: 367, // 2 Chronicles
  15: 403, // Ezra
  16: 413, // Nehemiah
  17: 426, // Esther
  18: 436, // Job
  19: 478, // Psalms
  20: 628, // Proverbs
  21: 659, // Ecclesiastes
  22: 671, // Song of Solomon
  23: 679, // Isaiah
  24: 745, // Jeremiah
  25: 797, // Lamentations
  26: 802, // Ezekiel
  27: 850, // Daniel
  28: 862, // Hosea
  29: 876, // Joel
  30: 879, // Amos
  31: 888, // Obadiah
  32: 889, // Jonah
  33: 893, // Micah
  34: 900, // Nahum
  35: 903, // Habakkuk
  36: 906, // Zephaniah
  37: 909, // Haggai
  38: 911, // Zechariah
  39: 925, // Malachi
  40: 929, // Matthew
  41: 957, // Mark
  42: 973, // Luke
  43: 997, // John
  44: 1018, // Acts
  45: 1046, // Romans
  46: 1062, // 1 Corinthians
  47: 1078, // 2 Corinthians
  48: 1091, // Galatians
  49: 1097, // Ephesians
  50: 1103, // Philippians
  51: 1107, // Colossians
  52: 1111, // 1 Thessalonians
  53: 1116, // 2 Thessalonians
  54: 1119, // 1 Timothy
  55: 1125, // 2 Timothy
  56: 1129, // Titus
  57: 1132, // Philemon
  58: 1133, // Hebrews
  59: 1146, // James
  60: 1151, // 1 Peter
  61: 1156, // 2 Peter
  62: 1159, // 1 John
  63: 1164, // 2 John
  64: 1165, // 3 John
  65: 1166, // Jude
  66: 1167, // Revelation
};

final Map<int, int> bookIdToChapterCountMap = {
  1: 50, // Genesis
  2: 40, // Exodus
  3: 27, // Leviticus
  4: 36, // Numbers
  5: 34, // Deuteronomy
  6: 24, // Joshua
  7: 21, // Judges
  8: 4, // Ruth
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
  22: 8, // Song of Solomon
  23: 66, // Isaiah
  24: 52, // Jeremiah
  25: 5, // Lamentations
  26: 48, // Ezekiel
  27: 12, // Daniel
  28: 14, // Hosea
  29: 3, // Joel
  30: 9, // Amos
  31: 1, // Obadiah
  32: 4, // Jonah
  33: 7, // Micah
  34: 3, // Nahum
  35: 3, // Habakkuk
  36: 3, // Zephaniah
  37: 2, // Haggai
  38: 14, // Zechariah
  39: 4, // Malachi
  40: 28, // Matthew
  41: 16, // Mark
  42: 24, // Luke
  43: 21, // John
  44: 28, // Acts
  45: 16, // Romans
  46: 16, // 1 Corinthians
  47: 13, // 2 Corinthians
  48: 6, // Galatians
  49: 6, // Ephesians
  50: 4, // Philippians
  51: 4, // Colossians
  52: 5, // 1 Thessalonians
  53: 3, // 2 Thessalonians
  54: 6, // 1 Timothy
  55: 4, // 2 Timothy
  56: 3, // Titus
  57: 1, // Philemon
  58: 13, // Hebrews
  59: 5, // James
  60: 5, // 1 Peter
  61: 3, // 2 Peter
  62: 5, // 1 John
  63: 1, // 2 John
  64: 1, // 3 John
  65: 1, // Jude
  66: 22, // Revelation
};
