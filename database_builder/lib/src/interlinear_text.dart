import 'dart:io';

void createInterlinearText() {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();
  final text = StringBuffer();
  const colLanguage = 4;
  const colHebrew = 5;
  const colReference = 12;
  const colEnglish = 18;
  const colPunctuation = 19;
  int lineCount = 0;
  for (int i = 1; i < lines.length; i++) {
    var line = lines[i];
    final columns = line.split('\t');
    final language = columns[colLanguage];
    if (language == 'Greek') break;
    final hebrew = columns[colHebrew].trim();
    if (hebrew.isEmpty) continue;

    final reference = columns[colReference];
    if (reference.isNotEmpty) {
      text.write('\n\n');
      text.writeln(reference);
    }
    final english = columns[colEnglish].trim();
    final punctuation = columns[colPunctuation].trim();
    text.write(' $hebrew ($english)$punctuation');
    lineCount++;
    if (lineCount % 10000 == 0) {
      print('$lineCount lines');
    }
  }
  // print(text);
  final outputFile = File('interlinear_text.txt');
  outputFile.createSync(recursive: true);
  outputFile.writeAsStringSync(text.toString());
}
