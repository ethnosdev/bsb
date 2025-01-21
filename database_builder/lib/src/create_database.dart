import 'package:database_builder/src/bsb_table.dart';
import 'package:database_builder/src/database_helper.dart';

Future<void> createDatabase() async {
  final dbHelper = DatabaseHelper();
  dbHelper.deleteDatabase();
  dbHelper.init();

  await createBsbTable(dbHelper);
}
