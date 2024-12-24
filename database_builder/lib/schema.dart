class Schema {
  // Bible table
  static const String bibleTextTable = "bible";

  // Column names
  static const String colId = '_id';
  static const String colType = 'type'; // ms, mr, d, s1, s2, qa, r, v
  static const String colBookId = 'book';
  static const String colChapter = 'chapter';
  static const String colVerse = 'verse';
  static const String colLine = 'line';
  static const String colText = 'text';
  static const String colFormat = 'format'; // m, q1, q2, pmo, li1, li2, pc, qr
  static const String colFootnote = 'footnote';

  // SQL statements
  static const String createTable = '''
  CREATE TABLE IF NOT EXISTS $bibleTextTable (
    $colId INTEGER PRIMARY KEY AUTOINCREMENT,
    $colType INTEGER NOT NULL,
    $colBookId INTEGER NOT NULL,
    $colChapter INTEGER NOT NULL,
    $colVerse INTEGER NOT NULL,
    $colLine INTEGER NOT NULL,
    $colText TEXT NOT NULL,
    $colFormat INTEGER,
    $colFootnote TEXT
  )
  ''';
}

// colType values
enum TextType {
  v(0), // verse
  d(1), // Descriptive Title (Psalms "Of David")
  r(2), // Cross Reference
  s1(3), // Section Heading Level 1
  s2(4), // Section Heading Level 2
  ms(5), // major section (Psalms)
  mr(6), // major section range (Psalms)
  qa(7); // Acrostic Heading (Psalm 119)

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

  static Format fromInt(int value) {
    return Format.values.firstWhere(
      (format) => format.id == value,
    );
  }
}
