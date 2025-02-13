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
  print(frequencyMap);
  print(mismatch.length);
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

String transliterateWord(String word) {
  final transliteration = StringBuffer();
  for (int i = 0; i < word.length; i++) {
    final greekLetter = word[i];
    if (i == 0 && greekLetter == 'υ') {
      transliteration.write('h');
    }
    final latinLetter = greekToLatinMap[greekLetter];
    transliteration.write(latinLetter);
  }
  return transliteration.toString();
}

// add transliteration for this word. (Don't delete anything that already exists!!!)
final greekToLatinMap = {
  'Β': 'B',
  'ί': 'i',
  'β': 'b',
  'λ': 'l',
  'ο': 'o',
  'ς': 's',
  'γ': 'g',
  'ε': 'e',
  'ν': 'n',
  'έ': 'e',
  'σ': 's',
  'ω': 'ō',
  'Ἰ': 'I',
  'η': 'ē',
  'ῦ': 'u',
  'Χ': 'Ch',
  'ρ': 'r',
  'ι': 'i',
  'τ': 't',
  'ἱ': 'i',
  'υ': 'u',
  'Δ': 'D',
  'α': 'a',
  'ὶ': 'i',
  'δ': 'd',
  'Ἀ': 'A',
  'ά': 'a',
  'μ': 'm',
  'ὰ': 'a',
  'ἐ': 'e',
  'ὸ': 'o',
  'κ': 'k',
  'ὲ': 'e',
  'ώ': 'ō',
  'ὼ': 'ō',
  'ύ': 'u',
  'ὺ': 'y',
  'ἀ': 'a',
  'φ': 'ph',
  'ὐ': 'u',
  'Φ': 'Ph',
  'Ζ': 'Z',
  'ῆ': 'ē',
  'Θ': 'Th',
  'Ἑ': 'He',
  'Ν': 'N',
  'Σ': 'S',
  'ό': 'o',
  'Ῥ': 'Rh',
  'χ': 'ch',
  'ὴ': 'ē',
  'θ': 'th',
  'ῶ': 'ō',
  'Ο': 'O',
  'Ὀ': 'O',
  'ζ': 'z',
  'Ἄ': 'A',
  'Μ': 'M',
  'π': 'p',
  'ή': 'ē',
  'Ἐ': 'E',
  'ἄ': 'a',
  'ξ': 'x',
  'ἧ': 'ē',
  'ὁ': 'ho',
  'Π': 'P',
  'ᾶ': 'a',
  'ὖ': 'u',
  'ἕ': 'he',
  'Τ': 'T',
  'ἡ': 'hē',
  'ὕ': 'hu',
  'ἦ': 'ē',
  'ῷ': 'ō',
  'ἢ': 'ē',
  'ῖ': 'i',
  'ὑ': 'hu',
  'ἔ': 'e',
  'ἁ': 'ha',
  'ὢ': 'ō',
  'ᾳ': 'a',
  'ἰ': 'i',
  'Κ': 'K',
  'ὄ': 'o',
  'ῇ': 'ē',
  'Ἁ': 'Ha',
  'ὅ': 'ho',
  'ἵ': 'hi',
  'ῥ': 'rh',
  'ὡ': 'hō',
  'ὗ': 'hu',
  'Ἡ': 'Hē',
  'ῴ': 'ō',
  'Ἱ': 'Hi',
  'ἴ': 'i',
  'ἤ': 'ē',
  'ἶ': 'i',
  'ἠ': 'ē',
  'ψ': 'ps',
  'ὃ': 'ho',
  'Α': 'A',
  'ἂ': 'a',
  'Ὁ': 'Ho',
  'ὀ': 'o',
  'ῳ': 'ō',
  'Γ': 'G',
  'Ἠ': 'Ē',
  'ΐ': 'i',
  'ῃ': 'ē',
  'ἑ': 'he',
  'ἅ': 'ha',
  'Υ': 'Hu',
  'ᾧ': 'hō',
  'Ε': 'E',
  '‿': '',
  'Ἔ': 'E',
  'Ὕ': 'Hu',
  'ᾷ': 'a',
  'Ὅ': 'Ho',
  'Ὑ': 'Hu',
  'ἓ': 'he',
  'Ὃ': 'Ho',
  'ὒ': 'u',
  'ὔ': 'u',
  'ἥ': 'hē',
  '¦': '',
  'ὥ': 'hō',
  'ᾖ': 'ē',
  'ὧ': 'hō',
  'Ὡ': 'Hō',
  'ῄ': 'ē',
  'Ἢ': 'Ē',
  'ᾠ': 'ō',
  'ϋ': 'u',
  'ἷ': 'hi',
  'Ἕ': 'He',
  'Ἦ': 'Hē',
  'Ἵ': 'Hi',
  'ἆ': 'a',
  'Λ': 'L',
  'Ἤ': 'Ē',
  'ἣ': 'hē',
  'ἃ': 'ha',
  'ὦ': 'ō',
  'Η': 'Ē',
  'ὠ': 'ō',
  'ϊ': 'i',
  'ᾅ': 'ha',
  'ΰ': 'u',
  'ᾑ': 'hē',
  'Ὥ': 'Hō',
  'Ὧ': 'Hō',
  'Ὦ': 'Hō',
  'ὤ': 'ō',
  'ῒ': 'i',
  'ῢ': 'u',
  'ὓ': 'hu',
  'Ἅ': 'Ha',
  'ᾔ': 'hē',
  'ᾗ': 'hē',
  'Ἥ': 'Hē',
  'Ι': 'I',
  'Ω': 'Ō',
  'ᾐ': 'hē',
  'Ἴ': 'I',
  'ἳ': 'hi',
  'ὂ': 'o',
  'Ρ': 'R',
  'Ὤ': 'Ō',
  'Ὢ': 'Ō',
  'Ψ': 'Ps',
  'Ὄ': 'O',
  'Ἓ': 'He',
  'Ὠ': 'Ō',
  'Ἆ': 'A',
  'Ἣ': 'Hē',
  'Ἃ': 'Ha',
  'ᾴ': 'a',
  'Ξ': 'X',
  'ᾄ': 'ha',
  '᾽': '',
  'Ὗ': 'Hu',
  'ά': 'a',
  'ί': 'i',
};

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
      errorCount++;
      print('$verse, Greek: $greekWord, Official: $officialTranslit, Ours: $ourTranslit');
      if (errorCount > 100) break;
    }
  }
}
