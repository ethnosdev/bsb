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

  for (String bookFilename in bibleBookFilenames) {
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

const List<String> bibleBookFilenames = [
  'GEN.usfm', // Genesis
  'EXO.usfm', // Exodus
  'LEV.usfm', // Leviticus
  'NUM.usfm', // Numbers
  'DEU.usfm', // Deuteronomy
  'JOS.usfm', // Joshua
  'JDG.usfm', // Judges
  'RUT.usfm', // Ruth
  '1SA.usfm', // 1 Samuel
  '2SA.usfm', // 2 Samuel
  '1KI.usfm', // 1 Kings
  '2KI.usfm', // 2 Kings
  '1CH.usfm', // 1 Chronicles
  '2CH.usfm', // 2 Chronicles
  'EZR.usfm', // Ezra
  'NEH.usfm', // Nehemiah
  'EST.usfm', // Esther
  'JOB.usfm', // Job
  'PSA.usfm', // Psalms
  'PRO.usfm', // Proverbs
  'ECC.usfm', // Ecclesiastes
  'SNG.usfm', // Song of Solomon
  'ISA.usfm', // Isaiah
  'JER.usfm', // Jeremiah
  'LAM.usfm', // Lamentations
  'EZK.usfm', // Ezekiel
  'DAN.usfm', // Daniel
  'HOS.usfm', // Hosea
  'JOL.usfm', // Joel
  'AMO.usfm', // Amos
  'OBA.usfm', // Obadiah
  'JON.usfm', // Jonah
  'MIC.usfm', // Micah
  'NAM.usfm', // Nahum
  'HAB.usfm', // Habakkuk
  'ZEP.usfm', // Zephaniah
  'HAG.usfm', // Haggai
  'ZEC.usfm', // Zechariah
  'MAL.usfm', // Malachi
  'MAT.usfm', // Matthew
  'MRK.usfm', // Mark
  'LUK.usfm', // Luke
  'JHN.usfm', // John
  'ACT.usfm', // Acts
  'ROM.usfm', // Romans
  '1CO.usfm', // 1 Corinthians
  '2CO.usfm', // 2 Corinthians
  'GAL.usfm', // Galatians
  'EPH.usfm', // Ephesians
  'PHP.usfm', // Philippians
  'COL.usfm', // Colossians
  '1TH.usfm', // 1 Thessalonians
  '2TH.usfm', // 2 Thessalonians
  '1TI.usfm', // 1 Timothy
  '2TI.usfm', // 2 Timothy
  'TIT.usfm', // Titus
  'PHM.usfm', // Philemon
  'HEB.usfm', // Hebrews
  'JAS.usfm', // James
  '1PE.usfm', // 1 Peter
  '2PE.usfm', // 2 Peter
  '1JN.usfm', // 1 John
  '2JN.usfm', // 2 John
  '3JN.usfm', // 3 John
  'JUD.usfm', // Jude
  'REV.usfm', // Revelation
];
