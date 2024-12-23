class Schema {
  // Bible table
  static const String tableName = "bible";

  // Column names
  static const String colId = '_id';
  static const String colBookId = 'book';
  static const String colChapter = 'chapter';
  static const String colVerse = 'verse';
  static const String colLine = 'line';
  static const String colText = 'text';

  // SQL statements
  static const String createTable = '''
  CREATE TABLE IF NOT EXISTS $tableName (
    $colId INTEGER PRIMARY KEY AUTOINCREMENT,
    $colBookId INTEGER NOT NULL,
    $colChapter INTEGER NOT NULL,
    $colVerse INTEGER NOT NULL,
    $colLine INTEGER NOT NULL,
    $colText TEXT NOT NULL
  )
  ''';
}
