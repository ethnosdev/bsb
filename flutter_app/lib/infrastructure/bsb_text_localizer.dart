/// Stateless read-time British English localization for canonical BSB text.
///
/// Transforms verses, inline USFM footnotes, section headings, and interlinear
/// English glosses 1-to-1 at read time without modifying `assets/database/database.db`
/// or altering `BBCCCVVVWWW` word IDs.
class BsbTextLocalizer {
  BsbTextLocalizer._();

  /// Packed `BBCCCVVV` verses where `practice` is a noun and must stay `practice`.
  /// Everywhere else, `\bpractice\b` is converted to `practise`.
  static const Set<int> _nounPracticeVerses = {
    5027026, // Deut 27:26
    18001005, // Job 1:5
    19119056, // Ps 119:56
    26033031, // Ezek 33:31
    26033032, // Ezek 33:32
    46011016, // 1 Cor 11:16
    49004019, // Eph 4:19
    50004009, // Phil 4:9
    59003016, // Jas 3:16
  };

  /// Packed `BBCCCVVV` verses where `practices` is a finite verb (-> `practises`).
  static const Set<int> _verbPracticesVerses = {
    5018010, // Deut 18:10
    16009029, // Neh 9:29
    19015002, // Ps 15:2
    19101007, // Ps 101:7
    23032006, // Isa 32:6
    26018024, // Ezek 18:24
    26018026, // Ezek 18:26
    28006010, // Hos 6:10
    40005019, // Matt 5:19
    43003021, // John 3:21
    62002029, // 1 John 2:29
    62003004, // 1 John 3:4
    62003007, // 1 John 3:7
    62003008, // 1 John 3:8
    66021027, // Rev 21:27
    66022015, // Rev 22:15
  };

  /// Packed `BBCCCVVV` verses where `story`/`stories` are architectural levels.
  static const Set<int> _storeyVerses = {
    26041007, // Ezek 41:7
    26042006, // Ezek 42:6
    44020009, // Acts 20:9
  };

  /// Packed `BBCCCVVV` verses where `spit` is past/participle (-> `spat`).
  static const Set<int> _pastSpitVerses = {
    4012014, // Num 12:14
    40026067, // Matt 26:67
    40027030, // Matt 27:30
    41007033, // Mark 7:33
    41008023, // Mark 8:23
    42018032, // Luke 18:32
    43009006, // John 9:6
  };

  /// 187 unambiguous American -> British word pairs (170 from the report excluding
  /// `anymore`, plus 17 corpus-verified additions across verses, headings, and footnotes).
  static const Map<String, String> _ukDictionary = {
    'among': 'amongst',
    'armor': 'armour',
    'armory': 'armoury',
    'authorization': 'authorisation',
    'authorized': 'authorised',
    'baptize': 'baptise',
    'baptized': 'baptised',
    'baptizes': 'baptises',
    'baptizing': 'baptising',
    'behavior': 'behaviour',
    'beveled': 'bevelled',
    'burned': 'burnt',
    'canceled': 'cancelled',
    'capitalized': 'capitalised',
    'center': 'centre',
    'centimeters': 'centimetres',
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
    'dwelled': 'dwelt',
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
    'inquiring': 'enquiring',
    'inquiry': 'enquiry',
    'install': 'instal',
    'instill': 'instil',
    'jeopardize': 'jeopardise',
    'jeopardized': 'jeopardised',
    'jewelry': 'jewellery',
    'judgment': 'judgement',
    'judgments': 'judgements',
    'kilometers': 'kilometres',
    'labor': 'labour',
    'labored': 'laboured',
    'laborer': 'labourer',
    'laborers': 'labourers',
    'labors': 'labours',
    'leaped': 'leapt',
    'learned': 'learnt',
    'leveled': 'levelled',
    'license': 'licence',
    'liters': 'litres',
    'marveled': 'marvelled',
    'marveling': 'marvelling',
    'marvelous': 'marvellous',
    'meters': 'metres',
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
    'organizes': 'organises',
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
    'revocalization': 'revocalisation',
    'revocalizations': 'revocalisations',
    'rumor': 'rumour',
    'rumors': 'rumours',
    'sandaled': 'sandalled',
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
    'smelled': 'smelt',
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
    'unplowed': 'unploughed',
    'unsandaled': 'unsandalled',
    'valor': 'valour',
    'vapor': 'vapour',
    'vigor': 'vigour',
    'willful': 'wilful',
    'willfully': 'wilfully',
    'worshiped': 'worshipped',
    'worshiper': 'worshipper',
    'worshipers': 'worshippers',
    'worshiping': 'worshipping',
  };

  /// British target words that also appear naturally in canonical `verses_search`
  /// (`burnt`: 265 canonical rows vs `burned`: 157; `dwelt`: 14 canonical rows vs `dwelled`: 1).
  static const Set<String> _canonicalCollisionTargets = {'burnt', 'dwelt'};

  static const Map<String, String> _contextualBritishToAmerican = {
    'practise': 'practice',
    'practises': 'practices',
    'storey': 'story',
    'storeys': 'stories',
    'spat': 'spit',
  };

  static final RegExp _practiceRegex = RegExp(
    r'\bpractice\b',
    caseSensitive: false,
  );
  static final RegExp _practicesRegex = RegExp(
    r'\bpractices\b',
    caseSensitive: false,
  );
  static final RegExp _storyRegex = RegExp(
    r'\bstor(?:y|ies)\b',
    caseSensitive: false,
  );
  static final RegExp _spitRegex = RegExp(
    r'\bspit\b',
    caseSensitive: false,
  );

  static final RegExp _ukRegex = RegExp(
    r'\b(' + _ukDictionary.keys.join('|') + r')\b',
    caseSensitive: false,
  );

  static final Map<String, List<String>> _britishToAmerican =
      _buildBritishToAmericanMap();

  static Map<String, List<String>> _buildBritishToAmericanMap() {
    final map = <String, List<String>>{};
    void addEntry(String american, String british) {
      map.putIfAbsent(british, () => <String>[]).add(american);
    }

    _ukDictionary.forEach(addEntry);
    _contextualBritishToAmerican.forEach((british, american) {
      addEntry(american, british);
    });
    return map;
  }

  /// Applies casing from [original] (ALLCAPS, TitleCase, or lowercase) to [replacement].
  static String _matchCase(String original, String replacement) {
    if (original.isEmpty || replacement.isEmpty) return replacement;
    if (original == original.toUpperCase()) {
      return replacement.toUpperCase();
    }
    final first = original[0];
    if (first == first.toUpperCase() && first != first.toLowerCase()) {
      return '${replacement[0].toUpperCase()}${replacement.substring(1)}';
    }
    return replacement;
  }

  /// Transforms verse text, inline USFM footnotes, or interlinear glosses for [packedVerse].
  static String localize(int packedVerse, String text) {
    if (text.isEmpty) return text;
    var result = text;

    if (!_nounPracticeVerses.contains(packedVerse)) {
      result = result.replaceAllMapped(
        _practiceRegex,
        (m) => _matchCase(m.group(0)!, 'practise'),
      );
    }
    if (_verbPracticesVerses.contains(packedVerse)) {
      result = result.replaceAllMapped(
        _practicesRegex,
        (m) => _matchCase(m.group(0)!, 'practises'),
      );
    }
    if (_storeyVerses.contains(packedVerse)) {
      result = result.replaceAllMapped(_storyRegex, (m) {
        final orig = m.group(0)!;
        final lower = orig.toLowerCase();
        final replacement = lower == 'story' ? 'storey' : 'storeys';
        return _matchCase(orig, replacement);
      });
    }
    if (_pastSpitVerses.contains(packedVerse)) {
      result = result.replaceAllMapped(
        _spitRegex,
        (m) => _matchCase(m.group(0)!, 'spat'),
      );
    }

    return localizeHeading(result);
  }

  /// Transforms unambiguous dictionary spellings in section headings or normalized strings.
  static String localizeHeading(String text) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(_ukRegex, (m) {
      final orig = m.group(0)!;
      final replacement = _ukDictionary[orig.toLowerCase()];
      if (replacement == null) return orig;
      return _matchCase(orig, replacement);
    });
  }

  /// Expands a lowercase alphanumeric search token into canonical SQLite FTS4 lookup terms.
  ///
  /// When [isPrefix] is false, exact 1:1 British words omit the British term if
  /// it has zero canonical occurrences (e.g. `favour` -> `['favor']`), while
  /// words with canonical collisions retain both (`burnt` -> `['burnt', 'burned']`).
  /// When [isPrefix] is true, adds any canonical American stem matching a British
  /// target starting with [cleanWord] unless that American stem already begins
  /// with [cleanWord].
  static List<String> expandFtsToken(String cleanWord, {bool isPrefix = false}) {
    final word = cleanWord.toLowerCase();
    if (word.isEmpty) return const [];

    if (!isPrefix) {
      final americanForms = _britishToAmerican[word];
      if (americanForms == null) return [word];
      final result = <String>[];
      if (_canonicalCollisionTargets.contains(word)) {
        result.add(word);
      }
      for (final american in americanForms) {
        if (!result.contains(american)) {
          result.add(american);
        }
      }
      return result;
    }

    final result = <String>[word];
    for (final entry in _britishToAmerican.entries) {
      if (!entry.key.startsWith(word)) continue;
      for (final american in entry.value) {
        if (!american.startsWith(word) && !result.contains(american)) {
          result.add(american);
        }
      }
    }
    return result;
  }

  /// Exposed for corpus-completeness tests against Appendix A counts.
  static int get dictionarySize => _ukDictionary.length;

  /// Exposed for corpus-completeness tests.
  static Set<int> get nounPracticeVerses => _nounPracticeVerses;

  /// Exposed for corpus-completeness tests.
  static Set<int> get verbPracticesVerses => _verbPracticesVerses;

  /// Exposed for corpus-completeness tests.
  static Set<int> get storeyVerses => _storeyVerses;

  /// Exposed for corpus-completeness tests.
  static Set<int> get pastSpitVerses => _pastSpitVerses;
}
