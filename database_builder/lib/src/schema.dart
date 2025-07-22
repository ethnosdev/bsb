class Schema {
  // Bible table
  static const String bibleTextTable = "bible";

  // BSB column names
  static const String colId = '_id';
  static const String colType = 'type'; // ms, mr, d, s1, s2, qa, r, v
  static const String colBookId = 'book';
  static const String colChapter = 'chapter';
  static const String colVerse = 'verse';
  static const String colText = 'text';
  static const String colFormat = 'format'; // m, q1, q2, pmo, li1, li2, pc, qr
  static const String colFootnote = 'footnote';

  // SQL statements
  static const String createBsbTable = '''
  CREATE TABLE IF NOT EXISTS $bibleTextTable (
    $colId INTEGER PRIMARY KEY AUTOINCREMENT,
    $colBookId INTEGER NOT NULL,
    $colChapter INTEGER NOT NULL,
    $colVerse INTEGER NOT NULL,
    $colText TEXT NOT NULL,
    $colType INTEGER NOT NULL,
    $colFormat INTEGER,
    $colFootnote TEXT
  )
  ''';

  // Interlinear table
  static const String interlinearTable = "interlinear";

  // Interlinear column names
  static const String ilColId = '_id';
  static const String ilColBookId = 'book';
  static const String ilColChapter = 'chapter';
  static const String ilColVerse = 'verse';
  static const String ilColLanguage =
      'language'; // 1 Hebrew, 2 Aramaic, 3 Greek
  static const String ilColOriginal =
      'original'; // foreign key to original language table
  // static const String ilColTransliteration = 'translit';
  static const String ilColPartOfSpeech =
      'pos'; // foreign key to part of speech table
  static const String ilColStrongsNumber = 'strongs';
  static const String ilColEnglish = 'english'; // foreign key to english table
  static const String ilColPunctuation = 'punct';

  // SQL statements
  static const String createInterlinearTable = '''
  CREATE TABLE IF NOT EXISTS $interlinearTable (
    $ilColId INTEGER PRIMARY KEY AUTOINCREMENT,
    $ilColBookId INTEGER NOT NULL,
    $ilColChapter INTEGER NOT NULL,
    $ilColVerse INTEGER NOT NULL,
    $ilColLanguage INTEGER NOT NULL,
    $ilColOriginal INTEGER NOT NULL,
    $ilColPartOfSpeech INTEGER NOT NULL,
    $ilColStrongsNumber INTEGER NOT NULL,
    $ilColEnglish INTEGER NOT NULL,
    $ilColPunctuation TEXT
  )
  ''';

  // Part of speech table
  static const String partOfSpeechTable = "pos";

  static const String posColId = '_id';
  static const String posColName = 'name';

  static const String createPartOfSpeechTable = '''
  CREATE TABLE IF NOT EXISTS $partOfSpeechTable (
    $posColId INTEGER PRIMARY KEY AUTOINCREMENT,
    $posColName TEXT NOT NULL
  )
  ''';

  // Original language table
  static const String originalLanguageTable = "original";

  static const String olColId = '_id';
  static const String olColWord = 'word';

  static const String createOriginalLanguageTable = '''
  CREATE TABLE IF NOT EXISTS $originalLanguageTable (
    $olColId INTEGER PRIMARY KEY AUTOINCREMENT,
    $olColWord TEXT NOT NULL
  )
  ''';

  // English language table
  static const String englishTable = "english";

  static const String engColId = '_id';
  static const String engColWord = 'word';

  static const String createEnglishTable = '''
  CREATE TABLE IF NOT EXISTS $englishTable (
    $engColId INTEGER PRIMARY KEY AUTOINCREMENT,
    $engColWord TEXT NOT NULL
  )
  ''';
}

// colType values
enum TextType {
  /// Verse
  v(0),

  /// Descriptive Title (Psalms "Of David")
  d(1),

  /// Cross Reference
  r(2),

  /// Section Heading Level 1
  s1(3),

  /// Section Heading Level 2
  s2(4),

  /// major section (Psalms)
  ms(5),

  /// major section range (Psalms)
  mr(6),

  /// Acrostic Heading (Psalm 119)
  qa(7);

  /// The integer value of the enum, used for database storage.
  final int id;
  const TextType(this.id);

  static TextType fromString(String value) {
    return TextType.values.firstWhere(
      (type) => type.name == value,
    );
  }

  static TextType fromInt(int value) {
    return TextType.values.firstWhere(
      (type) => type.id == value,
    );
  }
}

enum Format {
  m(0), // margin, no indentation
  q1(1), // poetry indentation level 1
  q2(2), // poetry indentation level 2
  pmo(3), // Embedded text opening
  li1(4), // list item level 1
  li2(5), // list item level 2
  pc(6), // centered
  qr(7); // right aligned

  final int id;
  const Format(this.id);

  static Format fromString(String value) {
    return Format.values.firstWhere(
      (format) => format.name == value,
    );
  }

  static Format fromInt(int value) {
    return Format.values.firstWhere(
      (format) => format.id == value,
    );
  }
}
