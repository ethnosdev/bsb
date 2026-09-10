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
  if (_previousLetterIsVowel(transliteration) ||
      transliteration.isEmpty ||
      nextLetter == 'i') {
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

/// Transliterates a pointed Hebrew (or biblical Aramaic) word into Latin
/// characters with syllable division according to Berean Standard Bible /
/// Bible Hub conventions.
String transliterateHebrew(String word) {
  if (word.isEmpty) return '';

  // Special casing for the Divine Name (YHWH) and its prefixed variants
  if (word.contains('יהו') ||
      word.contains('יְהוָ') ||
      word.contains('יְהֹוָ')) {
    if (word.endsWith('-') || word.endsWith('־')) return 'Yah·weh-';
    return 'Yah·weh';
  }

  // Archaic Qere/Ketiv "hi" (pronounced hî)
  if (word.startsWith('הִוא') ||
      word.startsWith('הִ֛וא') ||
      word.startsWith('הִ֥וא') ||
      word.startsWith('הִ֗וא')) {
    return 'hî';
  }

  // Strip end markers (sof pasuq, parashah markers) and capture maqaf
  var clean = word;
  final hasMaqaf = clean.endsWith('־') || clean.endsWith('-');
  clean = clean.replaceAll(RegExp(r'[\u05C3][פס]?$|[פס]$|[־-]$'), '');

  // Strip cantillation marks, meteg, rafe, paseq, and dots, preserving niqqud
  final accentRegex = RegExp(
    r'[\u0591-\u05AF\u05BD\u05BF\u05C0\u05C4\u05C5\u05C6\u200D]',
  );
  clean = clean.replaceAll(accentRegex, '');

  // Initial shuruq: וּ at start of word forms its own syllable 'ū·'
  bool initialShuruq = false;
  if (clean.startsWith('וּ') || clean.startsWith('\u05D5\u05BC')) {
    initialShuruq = true;
    clean = clean.substring(2);
  }

  // Parse into tokens (consonants and their modifying diacritics)
  final tokens = <_HebrewToken>[];
  int i = 0;
  while (i < clean.length) {
    final char = clean[i];
    final code = char.codeUnitAt(0);

    if (code >= 0x05D0 && code <= 0x05EA) {
      final token = _HebrewToken(letter: char);
      i++;
      while (i < clean.length) {
        final markCode = clean[i].codeUnitAt(0);
        if (markCode >= 0x05D0 && markCode <= 0x05EA) break;
        if (markCode == 0x05BC) {
          token.hasDagesh = true;
        } else if (markCode == 0x05C1) {
          token.isShin = true;
        } else if (markCode == 0x05C2) {
          token.isSin = true;
        } else if (markCode >= 0x05B0 && markCode <= 0x05BB) {
          token.vowel = markCode;
        }
        i++;
      }
      tokens.add(token);
    } else {
      i++;
    }
  }

  if (tokens.isEmpty) {
    return initialShuruq ? (hasMaqaf ? 'ū-' : 'ū') : '';
  }

  // Pre-process 3ms plural noun suffix -āyw -> -āw (e.g. פָּנָיו -> pā·nāw)
  if (tokens.length >= 2) {
    final last = tokens.last;
    final secondLast = tokens[tokens.length - 2];
    if (last.letter == 'ו' &&
        !last.hasDagesh &&
        last.vowel == null &&
        secondLast.letter == 'י' &&
        secondLast.vowel == null) {
      if (tokens.length >= 3 && tokens[tokens.length - 3].vowel == 0x05B8) {
        secondLast.isDeleted = true;
        last.isDeleted = true;
        tokens[tokens.length - 3].isAwSuffix = true;
      }
    }
  }

  // Pre-process shuruq on consonants: consonant + וּ -> consonant with vowel 'ū'
  for (int j = 0; j < tokens.length - 1; j++) {
    final cur = tokens[j];
    final nxt = tokens[j + 1];
    if (cur.vowel == null &&
        nxt.letter == 'ו' &&
        nxt.hasDagesh &&
        nxt.vowel == null) {
      cur.vowel = -1; // -1 represents shuruq `ū`
      nxt.isDeleted = true;
    }
  }

  // Pre-process vav-holam (holam male)
  for (int j = 0; j < tokens.length - 1; j++) {
    final cur = tokens[j];
    final nxt = tokens[j + 1];
    if (nxt.letter == 'ו' &&
        (nxt.vowel == 0x05B9 || (cur.vowel == 0x05B9 && nxt.vowel == null))) {
      cur.vowel = 0x05B9; // holam
      cur.hasVavHolam = true;
      nxt.isDeleted = true;
      if (j + 1 == tokens.length - 1) {
        cur.isFinalVavHolam = true;
      }
    }
  }

  final activeTokens = tokens.where((t) => !t.isDeleted).toList();

  final syllables = <String>[];
  if (initialShuruq) {
    syllables.add('ū');
  }

  for (int idx = 0; idx < activeTokens.length; idx++) {
    final tok = activeTokens[idx];
    final isFirst = (idx == 0 && !initialShuruq);
    final isLast = (idx == activeTokens.length - 1);
    final prevTok = idx > 0 ? activeTokens[idx - 1] : null;
    final nextTok = idx + 1 < activeTokens.length ? activeTokens[idx + 1] : null;

    // Quiescent alef (without vowel) is silent
    if (tok.letter == 'א' && tok.vowel == null) {
      continue;
    }

    // Mater lectionis yod without vowel following hiriq, tsere, or segol
    if (tok.letter == 'י' && tok.vowel == null) {
      if (prevTok != null &&
          (prevTok.vowel == 0x05B4 ||
              prevTok.vowel == 0x05B5 ||
              prevTok.vowel == 0x05B6)) {
        continue;
      }
    }

    // Romanize base consonant
    String c = _romanizeHebrewConsonant(tok);

    // Dagesh forte vs lene:
    // Begadkepat at word start or after a closed syllable is dagesh lene (not doubled).
    // Otherwise dagesh is dagesh forte (doubles the consonant across syllables).
    final isBegadkepat = 'בגדכפת'.contains(tok.letter);
    final afterClosed = prevTok != null &&
        prevTok.vowel == 0x05B0 &&
        !_isVocalShva(prevTok, idx - 1, activeTokens);
    final isDageshForte = tok.hasDagesh &&
        !(isBegadkepat && (isFirst || afterClosed)) &&
        !_isHebrewGuttural(tok.letter);

    if (isDageshForte && syllables.isNotEmpty) {
      syllables[syllables.length - 1] += c;
    }

    // Romanize vowel
    String v = '';
    final hasFollowingYod = nextTok != null &&
        nextTok.letter == 'י' &&
        nextTok.vowel == null;

    if (tok.isAwSuffix) {
      v = 'āw';
    } else if (tok.vowel == -1) {
      v = 'ū';
    } else if (tok.vowel == 0x05B0) {
      if (_isVocalShva(tok, idx, activeTokens)) {
        v = 'ə';
      } else {
        // Silent shva: closes the current syllable
        if (tok.prefixWithW) c = 'w$c';
        if (isLast) {
          if (tok.prefixWithW) {
            syllables.add(c);
          } else if (syllables.isNotEmpty) {
            syllables[syllables.length - 1] += c;
          }
        } else if (syllables.isNotEmpty) {
          syllables[syllables.length - 1] += c;
        }
        continue;
      }
    } else if (tok.vowel == 0x05B1) {
      v = 'ĕ';
    } else if (tok.vowel == 0x05B2) {
      v = 'ă';
    } else if (tok.vowel == 0x05B3) {
      v = 'o';
    } else if (tok.vowel == 0x05B4) {
      v = hasFollowingYod ? 'î' : 'i';
    } else if (tok.vowel == 0x05B5) {
      v = 'ê';
    } else if (tok.vowel == 0x05B6) {
      v = 'e';
    } else if (tok.vowel == 0x05B7) {
      // Furtive patach on word-final het or ayin
      if (isLast && (tok.letter == 'ח' || tok.letter == 'ע')) {
        syllables.add('a$c');
        continue;
      }
      v = 'a';
    } else if (tok.vowel == 0x05B8) {
      v = 'ā';
    } else if (tok.vowel == 0x05B9 || tok.vowel == 0x05BA) {
      if (tok.hasVavHolam) {
        if (tok.isFinalVavHolam) {
          v = 'ōw';
        } else {
          // Medial vav-holam
          syllables.add('$cō');
          if (nextTok != null) {
            if (nextTok.vowel != null && nextTok.vowel != 0x05B0) {
              syllables.add('w');
            } else {
              nextTok.prefixWithW = true;
            }
          }
          continue;
        }
      } else {
        v = 'ō';
      }
    } else if (tok.vowel == 0x05BB) {
      v = 'u';
    }

    if (tok.prefixWithW) {
      c = 'w$c';
    }

    if (isLast && v.isEmpty) {
      if (tok.prefixWithW) {
        syllables.add(c);
      } else if (syllables.isNotEmpty) {
        syllables[syllables.length - 1] += c;
      } else {
        syllables.add(c);
      }
    } else {
      syllables.add('$c$v');
    }
  }

  var res = syllables.join('·');
  if (hasMaqaf) res += '-';
  return res;
}

bool _isHebrewGuttural(String letter) => 'אהחער'.contains(letter);

bool _isVocalShva(_HebrewToken tok, int idx, List<_HebrewToken> tokens) {
  if (idx == 0) return true;
  if (idx == tokens.length - 1) return false;
  if (tok.hasDagesh) return true;
  if (idx > 0 && tokens[idx - 1].vowel == 0x05B0) return true;

  final prevVowel = tokens[idx - 1].vowel;
  if (prevVowel == 0x05B7 ||
      prevVowel == 0x05B6 ||
      prevVowel == 0x05B4 ||
      prevVowel == 0x05BB) {
    return false;
  }
  return true;
}

String _romanizeHebrewConsonant(_HebrewToken tok) {
  final l = tok.letter;
  final d = tok.hasDagesh;

  switch (l) {
    case 'א':
      return '’';
    case 'ב':
      return d ? 'b' : 'ḇ';
    case 'ג':
      return d ? 'g' : 'ḡ';
    case 'ד':
      return d ? 'd' : 'ḏ';
    case 'ה':
      return 'h';
    case 'ו':
      return 'w';
    case 'ז':
      return 'z';
    case 'ח':
      return 'ḥ';
    case 'ט':
      return 'ṭ';
    case 'י':
      return 'y';
    case 'כ':
    case 'ך':
      return d ? 'k' : 'ḵ';
    case 'ל':
      return 'l';
    case 'מ':
    case 'ם':
      return 'm';
    case 'נ':
    case 'ן':
      return 'n';
    case 'ס':
      return 's';
    case 'ע':
      return '‘';
    case 'פ':
    case 'ף':
      return d ? 'p' : 'p̄';
    case 'צ':
    case 'ץ':
      return 'ṣ';
    case 'ק':
      return 'q';
    case 'ר':
      return 'r';
    case 'ש':
      if (tok.isSin) return 'ś';
      return 'š';
    case 'ת':
      return d ? 't' : 'ṯ';
  }
  return '';
}

class _HebrewToken {
  final String letter;
  bool hasDagesh = false;
  bool isShin = false;
  bool isSin = false;
  int? vowel;
  bool isDeleted = false;
  bool hasVavHolam = false;
  bool isFinalVavHolam = false;
  bool prefixWithW = false;
  bool isAwSuffix = false;

  _HebrewToken({required this.letter});
}

