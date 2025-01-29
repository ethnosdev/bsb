enum Language {
  hebrew(0, 'Hebrew'),
  aramaic(1, 'Aramaic'),
  greek(2, 'Greek');

  final int id;
  final String displayName;

  const Language(this.id, this.displayName);

  static Language fromString(String value) {
    return Language.values.firstWhere(
      (language) => language.name == value.toLowerCase(),
    );
  }

  static Language fromInt(int value) {
    return Language.values.firstWhere(
      (language) => language.id == value,
    );
  }

  bool get isRTL {
    return this != greek;
  }
}

const _ezra = 15;
const _jeremiah = 24;
const _daniel = 27;
const _matthew = 40;

/// Returns the language of the verse.
///
/// Note that Daniel 2:4a is Hebrew while Daniel 2:4b is Aramaic, but this function
/// will return Aramaic for the verse.
Language languageForVerse({
  required int bookId,
  required int chapter,
  required int verse,
}) {
  // The New Testament books are all Greek.
  if (bookId >= _matthew) return Language.greek;

  // Ezra 4:8–6:18 and 7:12-26 are in Aramaic.
  if (bookId == _ezra) {
    if (chapter == 4) {
      if (verse >= 8) {
        return Language.aramaic;
      }
    }
    if (chapter == 5) return Language.aramaic;
    if (chapter == 6) {
      if (verse <= 18) {
        return Language.aramaic;
      }
    }
    if (chapter == 7) {
      if (verse >= 12 && verse <= 26) {
        return Language.aramaic;
      }
    }
  }

  // Jeremiah 10:11 is in Aramaic.
  if (bookId == _jeremiah && chapter == 10 && verse == 11) {
    return Language.aramaic;
  }

  // Daniel 2:4b–7:28 is in Aramaic.
  if (bookId == _daniel) {
    // The first part of Daniel 2:4 is in Hebrew, while the rest is in Aramaic.
    // For now we will just label it as Aramaic. Another solution would be to
    // return a list of languages, but that might not be worth it for a single verse.
    if (chapter == 2 && verse >= 4) {
      return Language.aramaic;
    }
    if (chapter >= 3 && chapter <= 7) {
      return Language.aramaic;
    }
  }

  // Everything else is in Hebrew.
  return Language.hebrew;
}
