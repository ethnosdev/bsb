import 'dart:io';

void transliterate() {
  final uniqueWords = uniqueGreekWords();
  for (var greekWord in uniqueWords) {
    final transliterated = transliterateWord(greekWord);
    print('greekWord: $greekWord, transliterated: $transliterated');
  }
}

Set<String> uniqueGreekWords() {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();
  int colLanguage = 4;
  int colGreek = 5;

  final Set<String> uniqueValues = {};

  for (var line in lines) {
    final columns = line.split('\t');
    if (columns[colLanguage] != 'Greek') continue;

    final word = columns[colGreek].trim();
    if (word.isNotEmpty && !uniqueValues.contains(word)) {
      uniqueValues.add(word);
    }
  }

  print('Unique Greek Words: ${uniqueValues.length}');
  return uniqueValues;
}

String transliterateWord(String word) {
  final transliteration = StringBuffer();
  for (int i = 0; i < word.length; i++) {
    final greekLetter = word[i];
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
};

void testTransliterator() {
  // get the file
  final file = File('bsb_tables/bsb_tables.csv');
  // get all of the lines in the file
  final lines = file.readAsLinesSync();
  // loop through every line
  for (var line in lines) {
    final columns = line.split('\t');
    if (columns[4] != 'Greek') continue;
    final officialTranslit = columns[7];
    final greekWord = columns[5];
    final ourTranslit = transliterateWord(greekWord);
    if (ourTranslit != officialTranslit) {
      print('Greek: $greekWord, Official: $officialTranslit, Ours: $ourTranslit');
      break;
    }
  }
  // get all of the columns in the line
  // if this isn't a greek line, then skip it
  // get the greek word
  // get the official transliteration
  // get our transliteration
  // compare the two
  // if they are different, then print them both and stop
}

// Greek: ἐστε, Official: este, Ours: esta
