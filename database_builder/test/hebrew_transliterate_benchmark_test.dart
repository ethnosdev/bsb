import 'dart:io';
import 'package:database_builder/database_builder.dart';
import 'package:test/test.dart';

void main() {
  test('transliterateHebrew achieves >96% match rate across bsb_tables.csv', () {
    final file = File('bsb_tables/bsb_tables.csv');
    if (!file.existsSync()) {
      print('bsb_tables.csv not found, skipping benchmark test.');
      return;
    }

    final lines = file.readAsLinesSync();
    int total = 0;
    int matches = 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final columns = line.split('\t');
      if (columns.length < 8) continue;
      final lang = columns[4].trim();
      if (lang != 'Hebrew' && lang != 'Aramaic') continue;

      final word = columns[5].trim();
      final expected = columns[7].trim();
      if (word.isEmpty || expected.isEmpty) continue;

      total++;
      final actual = transliterateHebrew(word);
      if (actual == expected) {
        matches++;
      }
    }

    final matchRate = matches / total;
    print('Benchmark: $matches / $total words matched (${(matchRate * 100).toStringAsFixed(2)}%)');
    expect(total, greaterThan(300000));
    expect(matchRate, greaterThan(0.96));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
