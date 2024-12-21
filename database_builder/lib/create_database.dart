import 'dart:io';

import 'package:database_builder/database_helper.dart';
import 'package:database_builder/utils/utils.dart';

Future<void> createDatabase() async {
  final dbHelper = DatabaseHelper();
  await dbHelper.init();

  final directory = Directory('bsb_usfm');

  if (!await directory.exists()) {
    print('Directory does not exist');
    return;
  }

  int bookId = 0;
  int chapter = 0;
  int verse = 0;
  int line = 0;

  for (String bookFilename in bibleBooks) {
    print('Processing: $bookFilename');
    final file = File('${directory.path}/$bookFilename');

    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (String line in lines) {
        final marker = line.split(RegExp(r'[ \n]'))[0];
        print(marker);
      }
    }
  }
}
