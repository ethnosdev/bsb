import 'package:database_builder/database_builder.dart';
import 'package:test/test.dart';

void main() {
  group('Language Enum', () {
    test('enum properties and IDs', () {
      expect(Language.hebrew.id, equals(0));
      expect(Language.hebrew.displayName, equals('Hebrew'));
      expect(Language.hebrew.isLTR, isFalse);
      expect(Language.hebrew.isRTL, isTrue);

      expect(Language.aramaic.id, equals(1));
      expect(Language.aramaic.displayName, equals('Aramaic'));
      expect(Language.aramaic.isLTR, isFalse);
      expect(Language.aramaic.isRTL, isTrue);

      expect(Language.greek.id, equals(2));
      expect(Language.greek.displayName, equals('Greek'));
      expect(Language.greek.isLTR, isTrue);
      expect(Language.greek.isRTL, isFalse);
    });

    test('fromString lookup', () {
      expect(Language.fromString('hebrew'), equals(Language.hebrew));
      expect(Language.fromString('Hebrew'), equals(Language.hebrew));
      expect(Language.fromString('HEBREW'), equals(Language.hebrew));

      expect(Language.fromString('aramaic'), equals(Language.aramaic));
      expect(Language.fromString('Aramaic'), equals(Language.aramaic));

      expect(Language.fromString('greek'), equals(Language.greek));
      expect(Language.fromString('Greek'), equals(Language.greek));

      expect(() => Language.fromString('latin'), throwsStateError);
    });

    test('fromInt lookup', () {
      expect(Language.fromInt(0), equals(Language.hebrew));
      expect(Language.fromInt(1), equals(Language.aramaic));
      expect(Language.fromInt(2), equals(Language.greek));
      expect(() => Language.fromInt(99), throwsStateError);
    });
  });

  group('languageForVerse', () {
    test('all New Testament books return Greek', () {
      // Books 40 (Matthew) through 66 (Revelation)
      for (int book = 40; book <= 66; book++) {
        expect(
          languageForVerse(bookId: book, chapter: 1, verse: 1),
          equals(Language.greek),
          reason: 'Book $book should be Greek',
        );
      }
    });

    test('standard Old Testament verses return Hebrew', () {
      expect(
        languageForVerse(bookId: 1, chapter: 1, verse: 1), // Gen 1:1
        equals(Language.hebrew),
      );
      expect(
        languageForVerse(bookId: 19, chapter: 23, verse: 1), // Ps 23:1
        equals(Language.hebrew),
      );
      expect(
        languageForVerse(bookId: 39, chapter: 4, verse: 6), // Mal 4:6
        equals(Language.hebrew),
      );
    });

    test('Aramaic portions in Ezra return Aramaic', () {
      // Ezra = 15
      // Ezra 4:7 is Hebrew, 4:8 is Aramaic
      expect(
        languageForVerse(bookId: 15, chapter: 4, verse: 7),
        equals(Language.hebrew),
      );
      expect(
        languageForVerse(bookId: 15, chapter: 4, verse: 8),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 15, chapter: 5, verse: 1),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 15, chapter: 6, verse: 18),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 15, chapter: 6, verse: 19),
        equals(Language.hebrew),
      );

      // Ezra 7:12-26 is Aramaic
      expect(
        languageForVerse(bookId: 15, chapter: 7, verse: 11),
        equals(Language.hebrew),
      );
      expect(
        languageForVerse(bookId: 15, chapter: 7, verse: 12),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 15, chapter: 7, verse: 26),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 15, chapter: 7, verse: 27),
        equals(Language.hebrew),
      );
    });

    test('Jeremiah 10:11 returns Aramaic', () {
      // Jeremiah = 24
      expect(
        languageForVerse(bookId: 24, chapter: 10, verse: 10),
        equals(Language.hebrew),
      );
      expect(
        languageForVerse(bookId: 24, chapter: 10, verse: 11),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 24, chapter: 10, verse: 12),
        equals(Language.hebrew),
      );
    });

    test('Aramaic portions in Daniel return Aramaic', () {
      // Daniel = 27
      // Dan 2:4b-7:28 is Aramaic
      expect(
        languageForVerse(bookId: 27, chapter: 2, verse: 3),
        equals(Language.hebrew),
      );
      expect(
        languageForVerse(bookId: 27, chapter: 2, verse: 4),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 27, chapter: 5, verse: 1),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 27, chapter: 7, verse: 28),
        equals(Language.aramaic),
      );
      expect(
        languageForVerse(bookId: 27, chapter: 8, verse: 1),
        equals(Language.hebrew),
      );
    });
  });

  group('transliterateGreek', () {
    test('transliterates basic Greek words', () {
      expect(transliterateGreek('Ἐν'), equals('En'));
      expect(transliterateGreek('ἀρχῇ'), equals('archē'));
      expect(transliterateGreek('ἦν'), equals('ēn'));
      expect(transliterateGreek('ὁ'), equals('ho'));
      expect(transliterateGreek('Λόγος'), equals('Logos'));
      expect(transliterateGreek('Θεός'), equals('Theos'));
    });
  });

  group('transliterateHebrew', () {
    test('transliterates Genesis 1:1 words', () {
      expect(transliterateHebrew('בְּרֵאשִׁ֖ית'), equals('bə·rê·šîṯ'));
      expect(transliterateHebrew('בָּרָ֣א'), equals('bā·rā'));
      expect(transliterateHebrew('אֱלֹהִ֑ים'), equals('’ĕ·lō·hîm'));
      expect(transliterateHebrew('אֵ֥ת'), equals('’êṯ'));
      expect(transliterateHebrew('הַשָּׁמַ֖יִם'), equals('haš·šā·ma·yim'));
      expect(transliterateHebrew('וְאֵ֥ת'), equals('wə·’êṯ'));
      expect(transliterateHebrew('הָאָֽרֶץ׃'), equals('hā·’ā·reṣ'));
    });

    test('transliterates Divine Name (YHWH) and prefixed variants', () {
      expect(transliterateHebrew('יְהוָ֥ה'), equals('Yah·weh'));
      expect(transliterateHebrew('יְהוָֽה׃'), equals('Yah·weh'));
      expect(transliterateHebrew('לַיהוָ֖ה'), equals('Yah·weh'));
      expect(transliterateHebrew('מֵיְהוָ֖ה'), equals('Yah·weh'));
      expect(transliterateHebrew('יְהוָֽה־'), equals('Yah·weh-'));
    });

    test('transliterates Holam male and Shuruq', () {
      expect(transliterateHebrew('י֔וֹם'), equals('yō·wm'));
      expect(transliterateHebrew('ט֑וֹב'), equals('ṭō·wḇ'));
      expect(transliterateHebrew('בּ֥וֹ'), equals('bōw'));
      expect(transliterateHebrew('אֹת֑וֹ'), equals('’ō·ṯōw'));
      expect(transliterateHebrew('תֹ֙הוּ֙'), equals('ṯō·hū'));
      expect(transliterateHebrew('וּבֵ֥ין'), equals('ū·ḇên'));
    });

    test('transliterates furtive patach correctly', () {
      expect(transliterateHebrew('וְר֣וּחַ'), equals('wə·rū·aḥ'));
      expect(transliterateHebrew('רָקִ֖יעַ'), equals('rā·qî·a‘'));
    });

    test('transliterates 3ms plural noun suffix -āw', () {
      expect(transliterateHebrew('פָּנָֽיו׃'), equals('pā·nāw'));
      expect(transliterateHebrew('בְּאַפָּ֖יו'), equals('bə·’ap·pāw'));
      expect(transliterateHebrew('מִצַּלְעֹתָ֔יו'), equals('miṣ·ṣal·‘ō·ṯāw'));
    });

    test('transliterates maqaf and hyphenated words', () {
      expect(transliterateHebrew('עַל־'), equals('‘al-'));
      expect(transliterateHebrew('אֶת־'), equals('’eṯ-'));
      expect(transliterateHebrew('כִּי־'), equals('kî-'));
    });

    test('transliterates biblical Aramaic words', () {
      expect(transliterateHebrew('וּמַלְכוּתֵ֔הּ'), equals('ū·mal·ḵū·ṯêh'));
      expect(transliterateHebrew('אֱלָהָא֙'), equals('’ĕ·lā·hā'));
    });
  });
}

