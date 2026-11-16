import 'dart:io';

import 'package:bsb/infrastructure/bsb_text_localizer.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/infrastructure/word_cluster.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('BsbTextLocalizer dictionary and casing', () {
    test('exposes expected dictionary and contextual verse counts', () {
      expect(BsbTextLocalizer.dictionarySize, equals(187));
      expect(BsbTextLocalizer.nounPracticeVerses.length, equals(9));
      expect(BsbTextLocalizer.verbPracticesVerses.length, equals(16));
      expect(BsbTextLocalizer.storeyVerses.length, equals(3));
      expect(BsbTextLocalizer.pastSpitVerses.length, equals(7));
    });

    test('converts all 170 unambiguous report entries and excludes anymore', () {
      const reportEntries = <String, String>{
        'among': 'amongst',
        'armor': 'armour',
        'armory': 'armoury',
        'authorization': 'authorisation',
        'authorized': 'authorised',
        'baptize': 'baptise',
        'baptized': 'baptised',
        'baptizing': 'baptising',
        'behavior': 'behaviour',
        'beveled': 'bevelled',
        'burned': 'burnt',
        'canceled': 'cancelled',
        'center': 'centre',
        'channeled': 'channelled',
        'chiseled': 'chiselled',
        'clamor': 'clamour',
        'clamoring': 'clamouring',
        'colored': 'coloured',
        'colorful': 'colourful',
        'colors': 'colours',
        'counseled': 'counselled',
        'counselor': 'counsellor',
        'counselors': 'counsellors',
        'criticized': 'criticised',
        'defense': 'defence',
        'defenses': 'defences',
        'defenseless': 'defenceless',
        'demeanor': 'demeanour',
        'disheveled': 'dishevelled',
        'dishonor': 'dishonour',
        'dishonorable': 'dishonourable',
        'dishonored': 'dishonoured',
        'dishonoring': 'dishonouring',
        'dishonors': 'dishonours',
        'distill': 'distil',
        'dreamed': 'dreamt',
        'emphasize': 'emphasise',
        'endeavor': 'endeavour',
        'enroll': 'enrol',
        'favor': 'favour',
        'favorable': 'favourable',
        'favorably': 'favourably',
        'favored': 'favoured',
        'favorite': 'favourite',
        'favoritism': 'favouritism',
        'favors': 'favours',
        'fertilize': 'fertilise',
        'fervor': 'fervour',
        'flavor': 'flavour',
        'fulfill': 'fulfil',
        'fulfillment': 'fulfilment',
        'fulfills': 'fulfils',
        'gray': 'grey',
        'harbor': 'harbour',
        'harbored': 'harboured',
        'harbors': 'harbours',
        'honor': 'honour',
        'honorable': 'honourable',
        'honorably': 'honourably',
        'honored': 'honoured',
        'honoring': 'honouring',
        'honors': 'honours',
        'inquire': 'enquire',
        'inquired': 'enquired',
        'inquires': 'enquires',
        'inquiry': 'enquiry',
        'install': 'instal',
        'instill': 'instil',
        'jeopardize': 'jeopardise',
        'jeopardized': 'jeopardised',
        'jewelry': 'jewellery',
        'judgment': 'judgement',
        'labor': 'labour',
        'labored': 'laboured',
        'laborer': 'labourer',
        'laborers': 'labourers',
        'labors': 'labours',
        'leaped': 'leapt',
        'learned': 'learnt',
        'leveled': 'levelled',
        'license': 'licence',
        'marveled': 'marvelled',
        'marveling': 'marvelling',
        'marvelous': 'marvellous',
        'mobilize': 'mobilise',
        'mobilized': 'mobilised',
        'mobilizing': 'mobilising',
        'molded': 'moulded',
        'molding': 'moulding',
        'molds': 'moulds',
        'moldy': 'mouldy',
        'multicolored': 'multicoloured',
        'mustache': 'moustache',
        'neighbor': 'neighbour',
        'neighboring': 'neighbouring',
        'neighbors': 'neighbours',
        'odor': 'odour',
        'offense': 'offence',
        'offenses': 'offences',
        'organized': 'organised',
        'paneled': 'panelled',
        'paneling': 'panelling',
        'paralyzed': 'paralysed',
        'parceled': 'parcelled',
        'plow': 'plough',
        'plowed': 'ploughed',
        'plowing': 'ploughing',
        'plowman': 'ploughman',
        'plowmen': 'ploughmen',
        'plows': 'ploughs',
        'plowshare': 'ploughshare',
        'plowshares': 'ploughshares',
        'practiced': 'practised',
        'practicing': 'practising',
        'pretense': 'pretence',
        'pretenses': 'pretences',
        'pulverized': 'pulverised',
        'quarreled': 'quarrelled',
        'quarreling': 'quarrelling',
        'realize': 'realise',
        'realized': 'realised',
        'realizes': 'realises',
        'realizing': 'realising',
        'recognize': 'recognise',
        'recognized': 'recognised',
        'recognizes': 'recognises',
        'recognizing': 'recognising',
        'revelers': 'revellers',
        'reveling': 'revelling',
        'rumor': 'rumour',
        'rumors': 'rumours',
        'savior': 'saviour',
        'savor': 'savour',
        'scepter': 'sceptre',
        'scepters': 'sceptres',
        'scrutinize': 'scrutinise',
        'shriveled': 'shrivelled',
        'signaled': 'signalled',
        'signaling': 'signalling',
        'skillful': 'skilful',
        'skillfully': 'skilfully',
        'smolder': 'smoulder',
        'smoldering': 'smouldering',
        'smolders': 'smoulders',
        'somber': 'sombre',
        'spilled': 'spilt',
        'splendor': 'splendour',
        'sulfur': 'sulphur',
        'symbolizes': 'symbolises',
        'sympathize': 'sympathise',
        'sympathized': 'sympathised',
        'terrorize': 'terrorise',
        'totaled': 'totalled',
        'toward': 'towards',
        'tranquility': 'tranquillity',
        'traveled': 'travelled',
        'traveler': 'traveller',
        'travelers': 'travellers',
        'traveling': 'travelling',
        'tumor': 'tumour',
        'tumors': 'tumours',
        'unauthorized': 'unauthorised',
        'valor': 'valour',
        'vapor': 'vapour',
        'vigor': 'vigour',
        'willful': 'wilful',
        'willfully': 'wilfully',
        'worshiped': 'worshipped',
        'worshiper': 'worshipper',
        'worshiping': 'worshipping',
      };
      expect(reportEntries.length, equals(170));

      for (final entry in reportEntries.entries) {
        expect(
          BsbTextLocalizer.localize(1001001, 'word ${entry.key}.'),
          equals('word ${entry.value}.'),
          reason: 'Expected ${entry.key} -> ${entry.value}',
        );
      }

      // Single-token invariant: anymore must stay anymore
      expect(
        BsbTextLocalizer.localize(1001001, 'never anymore'),
        equals('never anymore'),
      );
    });

    test('converts all 17 corpus additions', () {
      const additions = <String, String>{
        'baptizes': 'baptises',
        'capitalized': 'capitalised',
        'centimeters': 'centimetres',
        'dwelled': 'dwelt',
        'inquiring': 'enquiring',
        'judgments': 'judgements',
        'kilometers': 'kilometres',
        'liters': 'litres',
        'meters': 'metres',
        'organizes': 'organises',
        'revocalization': 'revocalisation',
        'revocalizations': 'revocalisations',
        'sandaled': 'sandalled',
        'smelled': 'smelt',
        'unplowed': 'unploughed',
        'unsandaled': 'unsandalled',
        'worshipers': 'worshippers',
      };
      expect(additions.length, equals(17));

      for (final entry in additions.entries) {
        expect(
          BsbTextLocalizer.localize(1001001, entry.key),
          equals(entry.value),
          reason: 'Expected ${entry.key} -> ${entry.value}',
        );
      }
    });

    test('applies contextual disambiguation for all 35 listed verse IDs', () {
      for (final id in BsbTextLocalizer.nounPracticeVerses) {
        expect(BsbTextLocalizer.localize(id, 'practice'), equals('practice'));
      }
      expect(BsbTextLocalizer.localize(1001001, 'practice'), equals('practise'));

      for (final id in BsbTextLocalizer.verbPracticesVerses) {
        expect(BsbTextLocalizer.localize(id, 'practices'), equals('practises'));
      }
      expect(
        BsbTextLocalizer.localize(1001001, 'practices'),
        equals('practices'),
      );

      for (final id in BsbTextLocalizer.storeyVerses) {
        expect(
          BsbTextLocalizer.localize(id, 'story and stories'),
          equals('storey and storeys'),
        );
      }
      // Genesis 39 narrative story stays story
      expect(
        BsbTextLocalizer.localize(1039001, 'story and stories'),
        equals('story and stories'),
      );

      for (final id in BsbTextLocalizer.pastSpitVerses) {
        expect(BsbTextLocalizer.localize(id, 'spit'), equals('spat'));
      }
      // Present/infinitive spit stays spit (Lev 15:8, Deut 25:9, Job 30:10, Mark 10:34, Mark 14:65)
      for (final id in const [3015008, 5025009, 18030010, 41010034, 41014065]) {
        expect(BsbTextLocalizer.localize(id, 'spit'), equals('spit'));
      }
    });

    test('preserves lowercase, TitleCase, and ALLCAPS precedence', () {
      expect(BsbTextLocalizer.localize(1001001, 'honor'), equals('honour'));
      expect(BsbTextLocalizer.localize(1001001, 'Honor'), equals('Honour'));
      expect(BsbTextLocalizer.localize(1001001, 'HONOR'), equals('HONOUR'));

      expect(BsbTextLocalizer.localize(1001001, 'Practice'), equals('Practise'));
      expect(BsbTextLocalizer.localize(1001001, 'PRACTICE'), equals('PRACTISE'));
      expect(BsbTextLocalizer.localize(40026067, 'SPIT'), equals('SPAT'));
      expect(BsbTextLocalizer.localize(44020009, 'Stories'), equals('Storeys'));
    });

    test('localizeHeading converts dictionary words and skips contextual rules', () {
      expect(
        BsbTextLocalizer.localizeHeading("God's Judgment and Honor"),
        equals("God's Judgement and Honour"),
      );
      expect(
        BsbTextLocalizer.localizeHeading('The Story of Practice'),
        equals('The Story of Practice'),
      );
    });

    test('expandFtsToken handles 1:1 words, collisions, and prefixes', () {
      expect(BsbTextLocalizer.expandFtsToken(''), isEmpty);
      expect(BsbTextLocalizer.expandFtsToken('grace'), equals(['grace']));
      expect(BsbTextLocalizer.expandFtsToken('favour'), equals(['favor']));
      expect(BsbTextLocalizer.expandFtsToken('storey'), equals(['story']));
      expect(BsbTextLocalizer.expandFtsToken('practise'), equals(['practice']));

      expect(
        BsbTextLocalizer.expandFtsToken('burnt'),
        equals(['burnt', 'burned']),
      );
      expect(
        BsbTextLocalizer.expandFtsToken('dwelt'),
        equals(['dwelt', 'dwelled']),
      );

      expect(
        BsbTextLocalizer.expandFtsToken('burnt', isPrefix: true),
        equals(['burnt', 'burned']),
      );
      expect(
        BsbTextLocalizer.expandFtsToken('fa', isPrefix: true),
        equals(['fa']),
      );
      expect(
        BsbTextLocalizer.expandFtsToken('honou', isPrefix: true),
        equals([
          'honou',
          'honor',
          'honorable',
          'honorably',
          'honored',
          'honoring',
          'honors',
        ]),
      );
      expect(
        BsbTextLocalizer.expandFtsToken('enqui', isPrefix: true),
        containsAll(['enqui', 'inquire', 'inquired', 'inquires', 'inquiring', 'inquiry']),
      );
    });
  });

  group('BsbTextLocalizer full SQLite corpus audit', () {
    late Database db;

    setUpAll(() async {
      final dbPath = '${Directory.current.path}/assets/database/database.db';
      db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
    });

    tearDownAll(() async {
      await db.close();
    });

    test('preserves exact word IDs across all 31,086 verses in database.db', () async {
      final rows = await db.query(
        Schema.bibleTextTable,
        columns: [Schema.colReference, Schema.colText, Schema.colFormat],
        orderBy: '${Schema.colId} ASC',
      );
      expect(rows.length, greaterThanOrEqualTo(31086));

      var transformedVerses = 0;
      for (final row in rows) {
        final ref = row[Schema.colReference] as int;
        final rawText = row[Schema.colText] as String;
        final format = ParagraphFormat.fromJson(row[Schema.colFormat] as String);
        final localizedText = BsbTextLocalizer.localize(ref, rawText);
        if (localizedText != rawText) {
          transformedVerses++;
        }

        final rawWords = UsfmParser.getWords(
          UsfmLine(bookChapterVerse: ref, text: rawText, format: format),
          0,
        ).whereType<Word>().toList();
        final localizedWords = UsfmParser.getWords(
          UsfmLine(bookChapterVerse: ref, text: localizedText, format: format),
          0,
        ).whereType<Word>().toList();

        expect(
          localizedWords.map((w) => w.id).toList(),
          equals(rawWords.map((w) => w.id).toList()),
          reason: 'Word ID shift detected in verse $ref',
        );
      }

      expect(transformedVerses, greaterThan(1000));
    });

    test('interlinear gloss localization before resolveWordClusters updates vvv companions', () async {
      // Genesis 6:8 (1006008): "Noah found favor in the eyes of the LORD."
      final rows = await db.rawQuery(
        'SELECT i.${Schema.ilColId} as token_id, '
        'o.${Schema.olColId} as original_id, '
        'o.${Schema.olColWord} as ${Schema.ilColOriginal}, '
        'e.${Schema.engColWord} as ${Schema.ilColEnglish}, '
        'i.${Schema.ilColStrongsNumber}, '
        'p.${Schema.posColName} as ${Schema.ilColPartOfSpeech}, '
        'i.${Schema.ilColLanguage}, '
        'i.${Schema.ilColPunctuation}, '
        'i.${Schema.ilColBsbSort} '
        'FROM ${Schema.interlinearTable} i '
        'JOIN ${Schema.englishTable} e ON i.${Schema.ilColEnglish} = e.${Schema.engColId} '
        'JOIN ${Schema.partOfSpeechTable} p ON i.${Schema.ilColPartOfSpeech} = p.${Schema.posColId} '
        'JOIN ${Schema.originalLanguageTable} o ON i.${Schema.ilColOriginal} = o.${Schema.olColId} '
        'WHERE i.${Schema.ilColReference} = ? '
        'ORDER BY i.${Schema.ilColId} ASC',
        [1006008],
      );

      final htmlTagRegex = RegExp(r'<[^>]+>');
      final words = rows.map((row) {
        final rawEnglish = row[Schema.ilColEnglish] as String;
        final englishGloss = rawEnglish
            .replaceAll(htmlTagRegex, ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final localizedGloss = BsbTextLocalizer.localize(1006008, englishGloss);
        return OriginalWord(
          id: (row['token_id'] as int?) ?? 0,
          originalId: (row['original_id'] as int?) ?? 0,
          language: Language.fromInt(row[Schema.ilColLanguage] as int),
          word: row[Schema.ilColOriginal] as String,
          transliteration: '',
          englishGloss: localizedGloss,
          strongsNumber: row[Schema.ilColStrongsNumber] as int,
          partOfSpeech: row[Schema.ilColPartOfSpeech] as String,
          punctuation: row[Schema.ilColPunctuation] as String?,
          bsbSort: (row[Schema.ilColBsbSort] as int?) ?? 0,
        );
      }).toList();

      final resolved = resolveWordClusters(words).whereType<OriginalWord>();

      expect(
        resolved.any(
          (w) =>
              w.englishGloss.contains('favour') ||
              (w.partOfTranslation?.contains('favour') ?? false),
        ),
        isTrue,
      );
      expect(
        resolved.any(
          (w) =>
              w.englishGloss == 'favor' || w.partOfTranslation == 'favor',
        ),
        isFalse,
      );
      for (final word in resolved) {
        expect(word.englishGloss.contains('vvv'), isFalse);
        expect(word.partOfTranslation?.contains('vvv') ?? false, isFalse);
      }
    });
  });
}
