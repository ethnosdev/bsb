import 'package:database_builder/src/database_helper.dart';
import 'abbott_smith_parser.dart';
import 'bdb_parser.dart';

Future<void> createLexiconTable(DatabaseHelper dbHelper) async {
  print('Parsing Abbott-Smith Greek lexicon...');
  final greekRecords = AbbottSmithParser.parseFile('lexicon/abbott-smith.tei.xml');
  print('Loaded ${greekRecords.length} Abbott-Smith entries.');

  print('Parsing Brown-Driver-Briggs Hebrew/Aramaic lexicon...');
  final otRecords = BdbParser.parseFile('lexicon/unabridged-BDB-Hebrew-lexicon.csv');
  print('Loaded ${otRecords.length} BDB entries.');

  print('Inserting lexicon records into database...');
  dbHelper.beginTransaction();
  int count = 0;

  for (final record in greekRecords) {
    dbHelper.insertLexiconEntry(
      language: record.language,
      strongs: record.strongs,
      lemma: record.lemma,
      content: record.content,
    );
    count++;
    if (count % 5000 == 0) {
      print('Inserted $count lexicon records...');
    }
  }

  for (final record in otRecords) {
    dbHelper.insertLexiconEntry(
      language: record.language,
      strongs: record.strongs,
      lemma: record.lemma,
      content: record.content,
    );
    count++;
    if (count % 5000 == 0) {
      print('Inserted $count lexicon records...');
    }
  }

  dbHelper.commitTransaction();
  print('Finished inserting $count lexicon records.');
}
