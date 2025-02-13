import 'package:database_builder/src/bsb_table.dart';
import 'package:database_builder/src/database_helper.dart';
import 'package:database_builder/src/interlinear_table.dart';

Future<void> createDatabase() async {
  final dbHelper = DatabaseHelper();

  print('Deleting existing database');
  dbHelper.deleteDatabase();

  print('Creating new database');
  dbHelper.init();

  print('Creating BSB Table');
  await createBsbTable(dbHelper);

  print('Creating Foreign Table');
  final (originalMap, posMap, englishMap) = createForeignTables(dbHelper);
  print('Creating Interlinear Table');
  await createInterlinearTable(dbHelper, originalMap, posMap, englishMap);
}
