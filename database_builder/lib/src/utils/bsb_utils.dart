import 'dart:io';

Future<void> printAllFilenames() async {
  final directory = Directory('bsb_usfm');
  if (await directory.exists()) {
    await for (var entity in directory.list()) {
      if (entity is File) {
        print(entity.path.split('/').last);
      }
    }
  } else {
    print('Directory does not exist');
  }
}

Future<void> printAllParatextMarkers() async {
  final directory = Directory('bsb_usfm');
  final Map<String, int> markerFrequency = {};

  if (!await directory.exists()) {
    print('Directory does not exist');
    return;
  }

  for (String bookFilename in bibleBooks) {
    print('Processing: $bookFilename');
    final file = File('${directory.path}/$bookFilename');

    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (String line in lines) {
        if (line.startsWith('\\')) {
          // Extract marker up to first space or end of line
          final marker = line.split(RegExp(r'[ \n]'))[0];
          markerFrequency[marker] = (markerFrequency[marker] ?? 0) + 1;
        }
      }
    }
  }

  // Print frequency counts
  print('\nParatext Marker Frequencies:');
  final sortedMarkers = markerFrequency.keys.toList()..sort();
  for (String marker in sortedMarkers) {
    print('$marker: ${markerFrequency[marker]}');
  }
}

const List<String> bibleBooks = [
  '01GENBSB.SFM', // Genesis
  '02EXOBSB.SFM', // Exodus
  '03LEVBSB.SFM', // Leviticus
  '04NUMBSB.SFM', // Numbers
  '05DEUBSB.SFM', // Deuteronomy
  '06JOSBSB.SFM', // Joshua
  '07JDGBSB.SFM', // Judges
  '08RUTBSB.SFM', // Ruth
  '091SABSB.SFM', // 1 Samuel
  '102SABSB.SFM', // 2 Samuel
  '111KIBSB.SFM', // 1 Kings
  '122KIBSB.SFM', // 2 Kings
  '131CHBSB.SFM', // 1 Chronicles
  '142CHBSB.SFM', // 2 Chronicles
  '15EZRBSB.SFM', // Ezra
  '16NEHBSB.SFM', // Nehemiah
  '17ESTBSB.SFM', // Esther
  '18JOBBSB.SFM', // Job
  '19PSABSB.SFM', // Psalms
  '20PROBSB.SFM', // Proverbs
  '21ECCBSB.SFM', // Ecclesiastes
  '22SNGBSB.SFM', // Song of Solomon
  '23ISABSB.SFM', // Isaiah
  '24JERBSB.SFM', // Jeremiah
  '25LAMBSB.SFM', // Lamentations
  '26EZKBSB.SFM', // Ezekiel
  '27DANBSB.SFM', // Daniel
  '28HOSBSB.SFM', // Hosea
  '29JOLBSB.SFM', // Joel
  '30AMOBSB.SFM', // Amos
  '31OBABSB.SFM', // Obadiah
  '32JONBSB.SFM', // Jonah
  '33MICBSB.SFM', // Micah
  '34NAMBSB.SFM', // Nahum
  '35HABBSB.SFM', // Habakkuk
  '36ZEPBSB.SFM', // Zephaniah
  '37HAGBSB.SFM', // Haggai
  '38ZECBSB.SFM', // Zechariah
  '39MALBSB.SFM', // Malachi
  '41MATBSB.SFM', // Matthew
  '42MRKBSB.SFM', // Mark
  '43LUKBSB.SFM', // Luke
  '44JHNBSB.SFM', // John
  '45ACTBSB.SFM', // Acts
  '46ROMBSB.SFM', // Romans
  '471COBSB.SFM', // 1 Corinthians
  '482COBSB.SFM', // 2 Corinthians
  '49GALBSB.SFM', // Galatians
  '50EPHBSB.SFM', // Ephesians
  '51PHPBSB.SFM', // Philippians
  '52COLBSB.SFM', // Colossians
  '531THBSB.SFM', // 1 Thessalonians
  '542THBSB.SFM', // 2 Thessalonians
  '551TIBSB.SFM', // 1 Timothy
  '562TIBSB.SFM', // 2 Timothy
  '57TITBSB.SFM', // Titus
  '58PHMBSB.SFM', // Philemon
  '59HEBBSB.SFM', // Hebrews
  '60JASBSB.SFM', // James
  '611PEBSB.SFM', // 1 Peter
  '622PEBSB.SFM', // 2 Peter
  '631JNBSB.SFM', // 1 John
  '642JNBSB.SFM', // 2 John
  '653JNBSB.SFM', // 3 John
  '66JUDBSB.SFM', // Jude
  '67REVBSB.SFM', // Revelation
];
