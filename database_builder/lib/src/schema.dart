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

// enum ParagraphFormat {
//   /// margin, no indentation
//   m(0),

//   /// break, blank vertical space
//   b(1),

//   /// poetry indentation level 1
//   q1(2),

//   /// poetry indentation level 2
//   q2(3),

//   /// Embedded text opening
//   pmo(4),

//   /// list item level 1
//   li1(5),

//   /// list item level 2
//   li2(6),

//   /// centered
//   pc(7),

//   /// right aligned
//   qr(8),

//   /// Descriptive Title (Psalms "Of David")
//   d(9),

//   /// Cross Reference
//   r(10),

//   /// Section Heading Level 1
//   s1(11),

//   /// Section Heading Level 2
//   s2(12),

//   /// major section (Psalms)
//   ms(13),

//   /// major section range (Psalms)
//   mr(14),

//   /// Acrostic Heading (Psalm 119)
//   qa(15);

//   /// The integer value of the enum, used for database storage.
//   final int id;
//   const ParagraphFormat(this.id);

//   bool get isBiblicalText => id < 10;

//   static ParagraphFormat fromString(String value) {
//     return ParagraphFormat.values.firstWhere(
//       (type) => type.name == value,
//     );
//   }

//   static ParagraphFormat fromInt(int value) {
//     return ParagraphFormat.values.firstWhere(
//       (type) => type.id == value,
//     );
//   }
// }

// // colType values
// enum TextType {
//   /// Verse
//   v(0),

//   /// Descriptive Title (Psalms "Of David")
//   d(1),

//   /// Cross Reference
//   r(2),

//   /// Section Heading Level 1
//   s1(3),

//   /// Section Heading Level 2
//   s2(4),

//   /// major section (Psalms)
//   ms(5),

//   /// major section range (Psalms)
//   mr(6),

//   /// Acrostic Heading (Psalm 119)
//   qa(7);

//   /// The integer value of the enum, used for database storage.
//   final int id;
//   const TextType(this.id);

//   static TextType fromString(String value) {
//     return TextType.values.firstWhere(
//       (type) => type.name == value,
//     );
//   }

//   static TextType fromInt(int value) {
//     return TextType.values.firstWhere(
//       (type) => type.id == value,
//     );
//   }
// }

// enum Format {
//   m(0), // margin, no indentation
//   q1(1), // poetry indentation level 1
//   q2(2), // poetry indentation level 2
//   pmo(3), // Embedded text opening
//   li1(4), // list item level 1
//   li2(5), // list item level 2
//   pc(6), // centered
//   qr(7); // right aligned

//   final int id;
//   const Format(this.id);

//   static Format fromString(String value) {
//     return Format.values.firstWhere(
//       (format) => format.name == value,
//     );
//   }

//   static Format fromInt(int value) {
//     return Format.values.firstWhere(
//       (format) => format.id == value,
//     );
//   }
// }
