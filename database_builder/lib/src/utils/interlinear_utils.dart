import 'dart:io';

void compareColumns() {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();
  int count = 0;

  for (var line in lines) {
    if (count >= 100) break;

    final columns = line.split('\t');
    if (columns.length >= 7) {
      final col6 = columns[5].trim();
      final col7 = columns[6].trim();

      if (col6 != col7) {
        print('Column 6: $col6');
        print('Column 7: $col7');
        print('---');
        count++;
      }
    }
  }
}

void uniqueLanguageValues() {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();
  int column = 4;

  final Set<String> uniqueValues = {};

  for (var line in lines) {
    final columns = line.split('\t');
    if (columns.length > column) {
      final value = columns[column].trim();
      if (value.isNotEmpty && !uniqueValues.contains(value)) {
        uniqueValues.add(value);
        print(value);
        // if (value == 'z') {
        //   print(line);
        // }
      }
    }
  }
}

void uniquePosValues() {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();
  int langColumn = 4;
  int posColumn = 8;

  final Set<String> uniqueHebrew = {};
  final Set<String> uniqueGreek = {};

  for (var line in lines) {
    final columns = line.split('\t');
    if (columns.length > posColumn) {
      final language = columns[langColumn].trim();
      final pos = columns[posColumn].trim();
      if (language == 'Hebrew' || language == 'Aramaic') {
        if (pos.isNotEmpty && !uniqueHebrew.contains(pos)) {
          uniqueHebrew.add(pos);
          print('Hebrew: $pos');
        }
      } else if (language == 'Aramaic') {
        if (pos.isNotEmpty && !uniqueHebrew.contains(pos)) {
          uniqueHebrew.add(pos);
          print('Aramaic: $pos');
        }
      } else if (language == 'Greek') {
        if (pos.isNotEmpty && !uniqueGreek.contains(pos)) {
          uniqueGreek.add(pos);
          print('Greek: $pos');
        }
      }
    }
  }

  final Set<String> splitHebrewValues = {};
  for (var value in uniqueHebrew) {
    final parts = value.split(RegExp(r'[,|]'));
    for (var part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.isNotEmpty && !splitHebrewValues.contains(trimmedPart)) {
        splitHebrewValues.add(trimmedPart);
        print('Split Hebrew: $trimmedPart');
      }
    }
  }

  final Set<String> splitGreekValues = {};
  for (var value in uniqueGreek) {
    final parts = value.split(RegExp(r'[-/]'));
    for (var part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.isNotEmpty && !splitGreekValues.contains(trimmedPart)) {
        splitGreekValues.add(trimmedPart);
        print('Split Greek: $trimmedPart');
      }
    }
  }

  print('Unique Hebrew: ${uniqueHebrew.length}');
  print('Unique Greek: ${uniqueGreek.length}');
}
