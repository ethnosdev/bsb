import 'database_helper.dart';
import 'schema.dart';

final _footnoteRegex = RegExp(r'\\f\s*[+-]?\s*.*?(?:\\f\*|$)', dotAll: true);
final _usfmTagRegex = RegExp(r'\\[a-zA-Z0-9*]+');
final _whitespaceRegex = RegExp(r'\s+');

String cleanVerseText(String rawText) {
  var clean = rawText.replaceAll(_footnoteRegex, '');
  clean = clean.replaceAll(_usfmTagRegex, '');
  clean = clean.replaceAll(_whitespaceRegex, ' ').trim();
  return clean;
}

Future<void> createVerseSearchTable(DatabaseHelper dbHelper) async {
  final db = dbHelper.database;

  final rows = db.select('''
    SELECT ${Schema.colReference}, ${Schema.colText}
    FROM ${Schema.bibleTextTable}
    WHERE ${Schema.colFormat} NOT IN ('s1', 's2', 'r', 'd', 'ms', 'mr', 'b', 'qa')
      AND ${Schema.colReference} % 1000 != 0
    ORDER BY ${Schema.colId} ASC
  ''');

  final verses = <int, List<String>>{};
  for (final row in rows) {
    final ref = row[Schema.colReference] as int;
    final text = row[Schema.colText] as String;
    final clean = cleanVerseText(text);
    if (clean.isEmpty) continue;
    verses.putIfAbsent(ref, () => []).add(clean);
  }

  dbHelper.beginTransaction();
  for (final entry in verses.entries) {
    final ref = entry.key;
    final bookId = ref ~/ 1000000;
    final chapter = (ref % 1000000) ~/ 1000;
    final verse = ref % 1000;
    final fullText = entry.value.join(' ');

    dbHelper.insertVerseSearch(
      reference: ref,
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      text: fullText,
    );
  }
  dbHelper.commitTransaction();
}
