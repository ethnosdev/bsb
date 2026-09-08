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

  static const String createBsbTable = '''
  CREATE TABLE IF NOT EXISTS $bibleTextTable (
    $colId INTEGER PRIMARY KEY AUTOINCREMENT,
    $colReference INTEGER NOT NULL,
    $colText TEXT NOT NULL,
    $colFormat TEXT NOT NULL
  )
  ''';

  static const String insertBsbLine = '''
    INSERT INTO $bibleTextTable (
      $colReference, $colText, $colFormat
    ) VALUES (?, ?, ?)
  ''';

  // Verse search table (FTS4)
  static const String verseSearchTable = "verses_search";
  static const String colBookId = "book_id";
  static const String colChapter = "chapter";
  static const String colVerse = "verse";

  static const String createVerseSearchTable = '''
  CREATE VIRTUAL TABLE IF NOT EXISTS $verseSearchTable USING fts4(
    $colReference,
    $colBookId,
    $colChapter,
    $colVerse,
    $colText,
    notindexed=$colReference,
    notindexed=$colBookId,
    notindexed=$colChapter,
    notindexed=$colVerse
  )
  ''';

  static const String insertVerseSearch = '''
    INSERT INTO $verseSearchTable (
      $colReference, $colBookId, $colChapter, $colVerse, $colText
    ) VALUES (?, ?, ?, ?, ?)
  ''';

  // Interlinear table
  static const String interlinearTable = "interlinear";

  // Interlinear column names
  static const String ilColId = '_id';
  // BBCCCVVV packed integer
  static const String ilColReference = 'reference';
  // 0 Hebrew, 1 Aramaic, 2 Greek
  static const String ilColLanguage = 'language';
  // foreign key to original language table
  static const String ilColOriginal = 'original';
  // foreign key to part of speech table
  static const String ilColPartOfSpeech = 'pos';
  static const String ilColStrongsNumber = 'strongs';
  // foreign key to english table
  static const String ilColEnglish = 'english';
  static const String ilColPunctuation = 'punct';
  static const String ilColBsbSort = 'bsb_sort';

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
    $ilColPunctuation TEXT,
    $ilColBsbSort INTEGER NOT NULL
  )
  ''';

  static const String createInterlinearIndexes = '''
  CREATE INDEX IF NOT EXISTS idx_il_ref ON $interlinearTable($ilColReference);
  CREATE INDEX IF NOT EXISTS idx_il_strongs ON $interlinearTable($ilColLanguage, $ilColStrongsNumber);
  CREATE INDEX IF NOT EXISTS idx_il_original ON $interlinearTable($ilColOriginal);
  ''';

  static const String insertInterlinear = '''
    INSERT INTO $interlinearTable (
      $ilColReference, $ilColLanguage,
      $ilColOriginal, $ilColPartOfSpeech, $ilColStrongsNumber,
      $ilColEnglish, $ilColPunctuation, $ilColBsbSort
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  // Lexicon entry table
  static const String lexiconEntryTable = "lexicon_entry";

  static const String lexColId = '_id';
  static const String lexColLanguage = 'language';
  static const String lexColStrongs = 'strongs';
  static const String lexColLemma = 'lemma';
  static const String lexColContent = 'content';

  static const String createLexiconEntryTable = '''
  CREATE TABLE IF NOT EXISTS $lexiconEntryTable (
    $lexColId INTEGER PRIMARY KEY AUTOINCREMENT,
    $lexColLanguage INTEGER NOT NULL,
    $lexColStrongs INTEGER NOT NULL,
    $lexColLemma TEXT NOT NULL,
    $lexColContent TEXT NOT NULL
  )
  ''';

  static const String createLexiconIndexes = '''
  CREATE INDEX IF NOT EXISTS idx_lex_strongs ON $lexiconEntryTable($lexColLanguage, $lexColStrongs);
  CREATE INDEX IF NOT EXISTS idx_lex_lemma ON $lexiconEntryTable($lexColLemma);
  ''';

  static const String insertLexiconEntry = '''
    INSERT INTO $lexiconEntryTable (
      $lexColLanguage, $lexColStrongs, $lexColLemma, $lexColContent
    ) VALUES (?, ?, ?, ?)
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
