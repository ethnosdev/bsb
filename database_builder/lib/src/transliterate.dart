import 'dart:io';

void transliterate() {
  final uniqueWords = uniqueGreekWords();
  final uniqueChars = uniqueGreekChars(uniqueWords);
  print(uniqueChars);
  // for (var greekWord in uniqueWords) {
  //   final transliterated = transliterateWord(greekWord);
  //   print('greekWord: $greekWord, transliterated: $transliterated');
  // }
}

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
    final ourTranslit = transliterateWord(greekWord);
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

String transliterateWord(String word) {
  final transliteration = <String>[];
  for (int i = 0; i < word.length; i++) {
    final letter = word[i];
    final latin = _directReplacements[letter];
    final nextLetter = i + 1 < word.length ? word[i + 1] : null;

    if (latin != null) {
      transliteration.add(latin);
      continue;
    }

    if (_isUpperUpsilon(letter)) {
      _addU(transliteration, nextLetter: nextLetter, isUpper: true);
      continue;
    }

    if (_isLowerUpsilon(letter)) {
      _addU(transliteration, nextLetter: nextLetter, isUpper: false);
      continue;
    }

    if (_isUpperGamma(letter)) {
      if (_nextLetterIsGksch(nextLetter)) {
        transliteration.add('N');
      } else {
        transliteration.add('G');
      }
      continue;
    }

    if (_isLowerGamma(letter)) {
      if (_nextLetterIsGksch(nextLetter)) {
        transliteration.add('n');
      } else {
        transliteration.add('g');
      }
      continue;
    }

    final hReplacement = _hReplacements[letter];
    if (hReplacement != null) {
      _insertH(transliteration);
      if (hReplacement == 'u') {
        _addU(transliteration, nextLetter: nextLetter, isUpper: false);
      } else {
        transliteration.add(hReplacement);
      }
      continue;
    }
  }

  final result = transliteration.join();
  final specialCase = _specialCases[result];
  return specialCase ?? result;
}

final _specialCases = {
  'OUTOS': 'HOUTOS',
  'O': 'Ho',
  'ThEŌ': 'THEŌ',
  'ChRISTOS': 'CHRISTOS',
};

void _insertH(List<String> transliteration) {
  if (transliteration.isEmpty) {
    transliteration.add('h');
    return;
  }

  final first = transliteration.first;
  if (_isUppercase(first)) {
    transliteration.insert(0, 'H');
    transliteration[1] = first.toLowerCase();
  } else {
    transliteration.insert(0, 'h');
  }
}

bool _isUppercase(String letter) {
  return letter == letter.toUpperCase();
}

void _addU(
  List<String> transliteration, {
  required String? nextLetter,
  required bool isUpper,
}) {
  if (nextLetter != null) {
    nextLetter = _directReplacements[nextLetter];
  }
  if (_previousLetterIsVowel(transliteration) || transliteration.isEmpty || nextLetter == 'i') {
    transliteration.add(isUpper ? 'U' : 'u');
  } else {
    transliteration.add(isUpper ? 'Y' : 'y');
  }
}

bool _previousLetterIsVowel(List<String> transliteration) {
  if (transliteration.isEmpty) return false;
  return 'AEĒIOUYaeēioōuy'.contains(transliteration.last);
}

bool _nextLetterIsGksch(String? nextLetter) {
  if (nextLetter == null) return false;
  return 'γκξχ'.contains(nextLetter);
}

bool _isUpperUpsilon(String char) {
  return 'Υ'.contains(char);
}

bool _isLowerUpsilon(String char) {
  return 'υΰὐϋύὒὔὖὺύῢῦ'.contains(char);
}

bool _isUpperGamma(String char) {
  return char == 'Γ';
}

bool _isLowerGamma(String char) {
  return char == 'γ';
}

final _hReplacements = {
  'Ἱ': 'I',
  'Ἵ': 'I',
  'ἵ': 'i',
  'ἷ': 'i',
  'ἱ': 'i',
  'ἳ': 'i',
  'ὕ': 'u',
  'ὑ': 'u',
  'ὗ': 'u',
  'ὓ': 'u',
};

final _directReplacements = {
  'Α': 'A',
  'Ἀ': 'A',
  'Ἄ': 'A',
  'Ἆ': 'A',
  'ά': 'a',
  'ἀ': 'a',
  'ἂ': 'a',
  'ἄ': 'a',
  'ἆ': 'a',
  'ᾳ': 'a',
  'ᾶ': 'a',
  'ᾷ': 'a',
  'ὰ': 'a',
  'ά': 'a',
  'ᾴ': 'a',
  'α': 'a',
  'ᾄ': 'a',
  'Β': 'B',
  'β': 'b',
  'Χ': 'Ch',
  'χ': 'ch',
  'Δ': 'D',
  'δ': 'd',
  'Ε': 'E',
  'Ἐ': 'E',
  'Ἔ': 'E',
  'ἐ': 'e',
  'ἔ': 'e',
  'έ': 'e',
  'ε': 'e',
  'ὲ': 'e',
  'έ': 'e',
  'Η': 'Ē',
  'Ἠ': 'Ē',
  'Ἢ': 'Ē',
  'Ἤ': 'Ē',
  'Ἦ': 'Ē',
  // 'Ἣ': 'Ē',
  'ἤ': 'ē',
  'η': 'ē',
  'ἠ': 'ē',
  'ἢ': 'ē',
  'ἦ': 'ē',
  'ή': 'ē',
  'ὴ': 'ē',
  'ή': 'ē',
  'ᾐ': 'ē',
  'ᾔ': 'ē',
  'ᾖ': 'ē',
  'ῃ': 'ē',
  'ῄ': 'ē',
  'ῆ': 'ē',
  'ῇ': 'ē',
  'Ἅ': 'Ha',
  'Ἁ': 'Ha',
  'Ἃ': 'Ha',
  'ἁ': 'ha',
  'ἅ': 'ha',
  'ἃ': 'ha',
  'ᾅ': 'ha',
  'Ἓ': 'He',
  'Ἕ': 'He',
  'Ἑ': 'He',
  'ἑ': 'he',
  'ἕ': 'he',
  'ἓ': 'he',
  'Ἡ': 'Hē',
  'Ἥ': 'Hē',
  'Ἣ': 'Hē',
  'ἡ': 'hē',
  'ἧ': 'hē',
  'ἥ': 'hē',
  'ἣ': 'hē',
  'ᾑ': 'hē',
  'ᾗ': 'hē',
  'Ἱ': 'Hi',
  'Ἵ': 'Hi',
  'Ὁ': 'Ho',
  'Ὅ': 'Ho',
  'Ὃ': 'Ho',
  'ὁ': 'ho',
  'ὅ': 'ho',
  'ὃ': 'ho',
  'Ὡ': 'Hō',
  'Ὥ': 'Hō',
  'Ὧ': 'Hō',
  'ὡ': 'hō',
  'ᾧ': 'hō',
  'ὥ': 'hō',
  'ὧ': 'hō',
  'Ὑ': 'Hy',
  'Ὕ': 'Hy',
  'Ὗ': 'Hy',
  'Ι': 'I',
  'Ἰ': 'I',
  'Ἴ': 'I',
  'ι': 'i',
  'ϊ': 'i',
  'ἰ': 'i',
  'ἴ': 'i',
  'ἶ': 'i',
  'ί': 'i',
  'ΐ': 'i',
  'ὶ': 'i',
  'ί': 'i',
  'ῒ': 'i',
  'ΐ': 'i',
  'ῖ': 'i',
  'Κ': 'K',
  'κ': 'k',
  'Λ': 'L',
  'λ': 'l',
  'Μ': 'M',
  'μ': 'm',
  'Ν': 'N',
  'ν': 'n',
  'Ο': 'O',
  'Ὀ': 'O',
  'Ὄ': 'O',
  'ο': 'o',
  'ὸ': 'o',
  'ό': 'o',
  'ὀ': 'o',
  'ὄ': 'o',
  'ὂ': 'o',
  'ό': 'o',
  'Ὠ': 'Ō',
  'Ω': 'Ō',
  'Ὢ': 'Ō',
  'Ὤ': 'Ō',
  'Ὦ': 'Ō',
  'ω': 'ō',
  'ώ': 'ō',
  'ῳ': 'ō',
  'ῴ': 'ō',
  'ῶ': 'ō',
  'ῷ': 'ō',
  'ὼ': 'ō',
  'ώ': 'ō',
  'ὠ': 'ō',
  'ὢ': 'ō',
  'ὤ': 'ō',
  'ὦ': 'ō',
  'ᾠ': 'ō',
  'Π': 'P',
  'π': 'p',
  'Φ': 'Ph',
  'φ': 'ph',
  'Ψ': 'Ps',
  'ψ': 'ps',
  'Ρ': 'R',
  'ρ': 'r',
  'Ῥ': 'Rh',
  'ῥ': 'rh',
  'Σ': 'S',
  'ς': 's',
  'σ': 's',
  'Τ': 'T',
  'τ': 't',
  'Θ': 'Th',
  'θ': 'th',
  'Ξ': 'X',
  'ξ': 'x',
  'Ζ': 'Z',
  'ζ': 'z',
  '’': '’',
  '᾽': '᾽',
  '¦': '¦',
};

// ¦-¦: 4
// Α-A: 31
// Ἀ-A: 167
// Ἄ-A: 28
// Ἆ-A: 3
// ά-a: 1453
// ἀ-a: 1254
// ἂ-a: 3
// ἄ-a: 154
// ἆ-a: 5
// ᾳ-a: 83
// ᾶ-a: 118
// ᾷ-a: 35
// ὰ-a: 167
// ά-a: 8
// α-a: 7735
// ᾄ-a: 2
// Β-B: 69
// β-b: 978
// Δ-D: 92
// δ-d: 2008
// Ε-E: 44
// Ἐ-E: 111
// Ἔ-E: 37
// ἐ-e: 1407
// ἔ-e: 197
// έ-e: 1686
// ε-e: 6664
// ὲ-e: 33
// έ-e: 2
// Η-Ē: 8
// Ἠ-Ē: 16
// Ἢ-Ē: 2
// Ἤ-Ē: 9
// Ἦ-Ē: 5
// ἤ-Ē: 4
// η-ē: 1692
// ἠ-ē: 100
// ἢ-ē: 1
// ἤ-ē: 44
// ἦ-ē: 9
// ή-ē: 818
// ὴ-ē: 169
// ή-ē: 5
// ᾐ-ē: 5
// ᾔ-ē: 6
// ᾖ-ē: 2
// ῃ-ē: 262
// ῄ-ē: 8
// ῆ-ē: 220
// ῇ-ē: 73
// Γ-G: 62
// γ-g: 1877
// Ἱ-Hi: 1
// Ἵ-Hi: 1
// ἵ-h: 1 ////
// οἵ-hoi
// Οἵ-Hoi
// αἵ-hai
// εἵ-hei
// ἱ-h: 1 ////
// οἱ-hoi
// Αἱ-Hai
// αἱ-hai
// Υἱ-Hui
// υἱ-hui
// Ι-I: 10
// Ἰ-I: 101
// Ἴ-I: 3
// ι-i: 5322
// ϊ-i: 21
// ἰ-i: 304
// ἴ-i: 96
// ἶ-i: 43
// ί-i: 2007
// ΐ-i: 15
// ὶ-i: 161
// ί-i: 13
// ῒ-i: 5
// ΐ-i: 1
// ῖ-i: 540
// Κ-K: 120
// κ-k: 3476
// Λ-L: 61
// λ-l: 3326
// Μ-M: 105
// μ-m: 3310
// Ν-N: 54
// ν-n: 8837
// γ-n: 285  /// next letter is γ, κ, ξ
// γγ-ng: 285
// γκ-ng: 999
// γξ-nx: 999
// Ο-O: 30
// Ὀ-O: 9
// Ὄ-O: 3
// ο-o: 6520
// ὸ-o: 227
// ό-o: 1167
// ὀ-o: 109
// ὄ-o: 28
// ὂ-o: 1
// ό-o: 11
// Ω-Ō: 10
// Ὢ-Ō: 1
// Ὤ-Ō: 1
// Ὦ-Ō: 1
// ω-ō: 1503
// ώ-ō: 412
// ῳ-ō: 182
// ῴ-ō: 19
// ῶ-ō: 482
// ῷ-ō: 63
// ὼ-ō: 69
// ώ-ō: 7
// ὠ-ō: 16
// ὢ-ō: 1
// ὤ-ō: 5
// ὦ-ō: 5
// ᾠ-ō: 6
// Π-P: 181
// π-p: 3863
// Ρ-R: 6
// ρ-r: 3991
// Σ-S: 143
// ς-s: 2933
// σ-s: 5064
// Τ-T: 87
// τ-t: 5793
// θ-th:
// Υ-U: 3     /// after vowel
// υ-u: 1187  /// after vowel
// ΰ-u: 5
// ϋ-u: 7
// ύ-u: 608
// ὐ-u: 246
// ὒ-u: 2
// ὔ-u: 19
// ὖ-u: 9
// ὺ-u: 69
// ύ-u: 2
// ῢ-u: 1
// ῦ-u: 461
// Ξ-X: 1
// ξ-x: 585
// Υ-Y: 4     /// after consonant
// υ-y: 917   /// after consonant
// κυ-ky: 999
// τυ-ty: 999
// πυ-py: 999
// ύ-y: 401
// ὺ-y: 13
// ύ-y: 3
// ῦ-y: 19
// Ζ-Z: 21
// ζ-z: 547
// ’-’: 16
