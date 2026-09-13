import 'dart:io';
import 'package:database_builder/src/lexicon/abbott_smith_parser.dart';
import 'package:database_builder/src/lexicon/bdb_parser.dart';
import 'package:test/test.dart';

void main() {
  test('test BDB entries inspection', () {
    final file = File('lexicon/unabridged-BDB-Hebrew-lexicon.csv');
    final lines = file.readAsLinesSync();
    print('Total lines: ${lines.length}');
    int countWithHtmlArtifacts = 0;
    final forbidden = RegExp(r'onclick|reflink|<ref\b|<lookup\b|placeholder\d|<checkingNeeded|<wrongReferenceRemoved|&emsp|&ensp|&nbsp|&thinsp|\\&');

    for (int i = 1; i < lines.length; i++) {
      final cols = lines[i].split('\t');
      final cleaned = BdbParser.cleanHtmlToMarkdown(cols[2]);
      if (forbidden.hasMatch(cleaned)) {
        countWithHtmlArtifacts++;
        if (countWithHtmlArtifacts <= 3) {
          print('Found artifact in ${cols[0]}:');
          final m = forbidden.firstMatch(cleaned)!;
          final start = (m.start - 40).clamp(0, cleaned.length);
          final end = (m.end + 40).clamp(0, cleaned.length);
          print(cleaned.substring(start, end));
        }
      }
    }
    print('Total entries with leaked artifacts: $countWithHtmlArtifacts');
    expect(countWithHtmlArtifacts, equals(0));
  });

  test('test Abbott-Smith references', () {
    final records = AbbottSmithParser.parseFile('lexicon/abbott-smith.tei.xml');
    expect(records.isNotEmpty, isTrue);
    final agapao = records.firstWhere((r) => r.strongs == 25);
    print('=== Abbott-Smith G25 (ἀγαπάω) Sample ===');
    print(agapao.content.substring(0, agapao.content.length > 800 ? 800 : agapao.content.length));
    expect(agapao.content.contains('ref:'), isTrue);
  });
}
