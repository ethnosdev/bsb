String transliterateGreek(String word) {
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

bool _isUpperUpsilon(String char) => 'Υ'.contains(char);

bool _isLowerUpsilon(String char) => 'υΰὐϋύὒὔὖὺύῢῦ'.contains(char);

bool _isUpperGamma(String char) => char == 'Γ';

bool _isLowerGamma(String char) => char == 'γ';

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
