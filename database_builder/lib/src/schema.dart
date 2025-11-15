class Schema {
  // Bible table
  static const String bibleTextTable = "bible";

  // BSB column names
  static const String colId = '_id';
  // BBCCCVVV packed integer
  static const String colReference = 'reference';
  static const String colText = 'text';
  // paragraph format
  static const String colFormat = 'format';
  static const String colFootnote = 'footnote';

  static const String createBsbTable = '''
  CREATE TABLE IF NOT EXISTS $bibleTextTable (
    $colId INTEGER PRIMARY KEY AUTOINCREMENT,
    $colReference INTEGER NOT NULL,
    $colText TEXT NOT NULL,
    $colFormat TEXT NOT NULL,
    $colFootnote TEXT
  )
  ''';

  static const String insertBsbLine = '''
    INSERT INTO $bibleTextTable (
      $colReference, $colText, $colFormat, $colFootnote
    ) VALUES (?, ?, ?, ?)
  ''';

  // Interlinear table
  static const String interlinearTable = "interlinear";

  // Interlinear column names
  static const String ilColId = '_id';
  // BBCCCVVV packed integer
  static const String ilColReference = 'reference';
  // 1 Hebrew, 2 Aramaic, 3 Greek
  static const String ilColLanguage = 'language';
  // foreign key to original language table
  static const String ilColOriginal = 'original';
  // foreign key to part of speech table
  static const String ilColPartOfSpeech = 'pos';
  static const String ilColStrongsNumber = 'strongs';
  // foreign key to english table
  static const String ilColEnglish = 'english';
  static const String ilColPunctuation = 'punct';

  // SQL statements
  static const String createInterlinearTable = '''
  CREATE TABLE IF NOT EXISTS $interlinearTable (
    $ilColId INTEGER PRIMARY KEY AUTOINCREMENT,
    $ilColReference INTEGER NOT NULL,
    $ilColLanguage INTEGER NOT NULL,
    $ilColOriginal INTEGER NOT NULL,
    $ilColPartOfSpeech INTEGER NOT NULL,
    $ilColStrongsNumber INTEGER NOT NULL,
    $ilColEnglish INTEGER NOT NULL,
    $ilColPunctuation TEXT
  )
  ''';

  static const String insertInterlinear = '''
    INSERT INTO $interlinearTable (
      $ilColReference, $ilColLanguage,
      $ilColOriginal, $ilColPartOfSpeech, $ilColStrongsNumber,
      $ilColEnglish, $ilColPunctuation
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
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

  static const String insertPartOfSpeech = '''
    INSERT INTO $partOfSpeechTable ($posColName) VALUES (?)
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

  static const String insertOriginalLanguage = '''
    INSERT INTO $originalLanguageTable ($olColWord) VALUES (?)
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

  static const String insertEnglish = '''
    INSERT INTO $englishTable ($engColWord) VALUES (?)
  ''';
}
