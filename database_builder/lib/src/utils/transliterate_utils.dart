import 'dart:io';

import 'package:database_builder/src/language/transliterate.dart';

void mapTransliteration() {
  final uniqueWords = uniqueGreekWords();
  final frequencyMap = <String, int>{};
  final mismatch = <(String, String)>{};
  for (final (greek, translit) in uniqueWords) {
    if (greek.length == translit.length) {
      for (int i = 0; i < greek.length; i++) {
        final key = '${greek[i]}-${translit[i]}';
        if (key == 'ἤ-Ē') {
          print('greek: $greek, translit: $translit');
        }
        if (frequencyMap.containsKey(key)) {
          frequencyMap[key] = frequencyMap[key]! + 1;
        } else {
          frequencyMap[key] = 1;
        }
      }
    } else {
      mismatch.add((greek, translit));
    }
  }
  // print(frequencyMap);
  // final sortedKeys = frequencyMap.keys.toList()..sort();
  // for (final key in sortedKeys) {
  //   print('$key: ${frequencyMap[key]}');
  // }
  // print(mismatch.length);
}

// For the return value, the first string is the greek word
// and the second string is the transliteration.
Set<(String, String)> uniqueGreekWords() {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();
  int colLanguage = 4;
  int colGreek = 5;
  int translitCol = 7;

  final Set<(String, String)> uniqueValues = {};

  for (var line in lines) {
    final columns = line.split('\t');
    if (columns[colLanguage] != 'Greek') continue;

    final word = columns[colGreek].trim();
    final transliteration = columns[translitCol].trim();
    if (word.isNotEmpty && !uniqueValues.contains((word, transliteration))) {
      uniqueValues.add((word, transliteration));
    }
  }

  print('Unique Greek Words: ${uniqueValues.length}');
  return uniqueValues;
}

Set<String> uniqueGreekChars(Set<(String, String)> uniqueWords) {
  final uniqueChars = <String>{};
  for (var word in uniqueWords) {
    for (var char in word.$1.split('')) {
      if (!uniqueChars.contains(char)) {
        uniqueChars.add(char);
      }
    }
  }
  return uniqueChars;
}

void testTransliterator() {
  // get the file
  final file = File('bsb_tables/bsb_tables.csv');
  // get all of the lines in the file
  final lines = file.readAsLinesSync();
  // loop through every line
  String verse = '';
  int errorCount = 0;
  for (var line in lines) {
    final columns = line.split('\t');
    if (columns[4] != 'Greek') continue;
    final reference = columns[12];
    if (reference.isNotEmpty) {
      verse = reference;
    }
    final officialTranslit = columns[7];
    final greekWord = columns[5];
    final ourTranslit = transliterateGreek(greekWord);
    if (ourTranslit != officialTranslit) {
      final difference = '$greekWord, $officialTranslit, $ourTranslit';
      if (!_ignore.contains(difference)) {
        errorCount++;
        print('$verse, $difference');
      }
      if (errorCount > 5) break;
    }
  }
}

final _ignore = {
  'ἴσθι, Isthi, isthi',
  'Ὁ, HO, Ho',
  'Ο, HO, Ho',
  'Ἡ, HĒ, Hē',
  'Ὅ¦τι, HO¦ti, Ho¦ti',
  'ἤρξαντο, Ērxanto, ērxanto',
  'ἤγαγεν, Ēgagen, ēgagen',
  'ἤκουσαν, Ēkousan, ēkousan',
  'ἴδε, Ide, ide',
  'ἤδη, Ēdē, ēdē',
};
