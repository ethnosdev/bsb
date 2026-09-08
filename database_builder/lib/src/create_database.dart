import 'package:database_builder/src/bsb_table.dart';
import 'package:database_builder/src/database_helper.dart';
import 'package:database_builder/src/interlinear_table.dart';
import 'package:database_builder/src/lexicon/lexicon_table.dart';
import 'package:database_builder/src/verse_search_table.dart';

Future<void> createDatabase() async {
  final dbHelper = DatabaseHelper();

  print('Deleting existing database');
  dbHelper.deleteDatabase();

  print('Creating new database');
  dbHelper.init();

  print('Creating BSB Table');
  await createBsbTable(dbHelper);

  print('Creating Verse Search Table');
  await createVerseSearchTable(dbHelper);

  print('Creating Foreign Table');
  final (originalMap, posMap, englishMap) = createForeignTables(dbHelper);

  print('Creating Interlinear Table');
  await createInterlinearTable(dbHelper, originalMap, posMap, englishMap);

  print('Creating Lexicon Table');
  await createLexiconTable(dbHelper);

  print('Creating Indexes');
  dbHelper.createIndexes();

  print('Cleaning up resources');
  dbHelper.dispose();

  print('Database creation complete!');
}
