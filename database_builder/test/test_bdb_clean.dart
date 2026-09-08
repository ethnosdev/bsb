import 'dart:io';
import 'package:database_builder/src/lexicon/abbott_smith_parser.dart';
import 'package:database_builder/src/lexicon/bdb_parser.dart';
import 'package:test/test.dart';

void main() {
  test('test BDB entries inspection', () {
    final file = File('lexicon/unabridged-BDB-Hebrew-lexicon.csv');
    final lines = file.readAsLinesSync();
    print('Total lines: ${lines.length}');
    int printed = 0;
    final bdbParserClean = (String html) {
      var text = html;

      // 1. Remove header and navigation
      text = text.replaceAll(RegExp(r'<h1>.*?</h1>', dotAll: true), '');
      text = text.replaceAll(RegExp(r'<div class="navigation">.*?</div>', dotAll: true), '');

      // 2. Remove self-closing editorial tags and placeholders
      text = text.replaceAll(RegExp(r'<placeholder\d+/>'), '');
      text = text.replaceAll(RegExp(r'<checkingNeeded\s*/?>'), '');
      text = text.replaceAll(RegExp(r'<wrongReferenceRemoved\s*/?>'), '');

      // 3. Convert <ref> to markdown links: [Text](ref:BBCCCVVV)
      final refRegex = RegExp(
        r'<ref\b[^>]*\bb="(\d+)"[^>]*\bcBegin="(\d+)"[^>]*\bvBegin="(\d+)"[^>]*>(.*?)</ref>',
        dotAll: true,
      );
      text = text.replaceAllMapped(refRegex, (m) {
        final b = int.parse(m.group(1)!);
        final c = int.parse(m.group(2)!);
        final v = int.parse(m.group(3)!);
        final packed = b * 1000000 + c * 1000 + v;
        final inner = m.group(4)?.trim() ?? '';
        return '[$inner](ref:$packed)';
      });
      // Fallback for any remaining <ref>
      text = text.replaceAllMapped(RegExp(r'<ref\b[^>]*>(.*?)</ref>', dotAll: true), (m) => m.group(1) ?? '');

      // 4. Handle <reflink>:
      // Hebrew words -> [word](lex:word)
      // Non-Hebrew (J, E, P, ᵐ5, etc.) -> plain text
      final hebRegex = RegExp(r'[\u0590-\u05FF]');
      text = text.replaceAllMapped(RegExp(r'<reflink\b[^>]*>(.*?)</reflink>', dotAll: true), (m) {
        final inner = m.group(1)?.trim() ?? '';
        if (hebRegex.hasMatch(inner)) {
          return '[$inner](lex:$inner)';
        }
        return inner;
      });

      // 5. Unwrap <lookup> and <entry>
      text = text.replaceAllMapped(RegExp(r'<lookup\b[^>]*>(.*?)</lookup>', dotAll: true), (m) => m.group(1) ?? '');
      text = text.replaceAllMapped(RegExp(r'<entry\b[^>]*>(.*?)</entry>', dotAll: true), (m) => m.group(1) ?? '');

      // 6. Section headers for stems (Qal, Niphal, Piel, etc.)
      const stems = [
        r'Qal', r'Niph`al', r'Niph\.', r'Niphal',
        r'Pi`el', r'Pi\.', r'Piel', r'Pu`al', r'Pual',
        r'Hiph`il', r'Hiph\.', r'Hiphil', r'Hoph`al', r'Hophal',
        r'Hithpa`el', r'Hithp\.', r'Hithpael',
        r'Po`el', r'Po`al', r'Pilpel', r'Polpal', r'Hithpolel', r'Hithpalpel',
        r'Pe`al', r'Pa`el', r'Aph`el', r'Haph`el', r'Ithpe`el', r'Ithpa`al', r'Shaph`el',
      ];
      final stemRegex = RegExp('(?:<div class="point">|\\.\\s*|—\\s*|\\n\\s*)<b>(${stems.join('|')})</b>\\s*(?:—\\s*)?');
      text = text.replaceAllMapped(stemRegex, (m) {
        final stem = m.group(1)!.replaceAll('`', "'");
        return '\n\n### $stem\n\n';
      });

      // 7. Senses and sub-senses:
      // Numbered senses: 1., 2., 3.
      text = text.replaceAllMapped(
        RegExp(r'(?:<div class="point">|\n\s*|;\s*)<b>(\d+\.)</b>\s*'),
        (m) => '\n\n• **${m.group(1)}** ',
      );
      // Lettered sub-senses: a., b., c.
      text = text.replaceAllMapped(
        RegExp(r'(?:<div class="point">|\n\s*|;\s*)<b>([a-z]\.)</b>\s*'),
        (m) => '\n   • **${m.group(1)}** ',
      );

      // Remaining <div class="point"> and </div>
      text = text.replaceAll('<div class="point">', '\n\n• ');
      text = text.replaceAll('</div>', '\n');

      // 8. Grammatical categories (Conjugations) onto new lines
      const conjugations = [
        'Perfect', 'Imperfect', 'Infinitive absolute', 'Infinitive construct',
        'Infinitive', 'Participle', 'Imperative', 'Cohortative', 'Jussive',
      ];
      final conjRegex = RegExp('(?:;\\s*|—\\s*|\\.\\s*)<highlight>(${conjugations.join('|')})</highlight>');
      text = text.replaceAllMapped(conjRegex, (m) => '\n\n- *${m.group(1)}*');

      // 9. Formatting tags
      text = text.replaceAllMapped(RegExp(r'<b>(.*?)</b>', dotAll: true), (m) => '**${m.group(1)}**');
      text = text.replaceAllMapped(RegExp(r'<highlightword>(.*?)</highlightword>', dotAll: true), (m) => '**${m.group(1)}**');
      text = text.replaceAllMapped(RegExp(r'<highlight>(.*?)</highlight>', dotAll: true), (m) => '*${m.group(1)}*');
      text = text.replaceAllMapped(RegExp(r'<transliteration>(.*?)</transliteration>', dotAll: true), (m) => '*${m.group(1)}*');

      // 10. Superscripts and subscripts
      text = text.replaceAllMapped(RegExp(r'<sup>(.*?)</sup>', dotAll: true), (m) => '^${m.group(1)}');
      text = text.replaceAllMapped(RegExp(r'<sub>(.*?)</sub>', dotAll: true), (m) => '_${m.group(1)}');

      // 11. Foreign tags and unneeded tags
      text = text.replaceAll(RegExp(r'</?(?:bdbheb|bdbarc|grk|entry|big|u)>'), '');

      // 12. Paragraphs and breaks
      text = text.replaceAll(RegExp(r'</?p>'), '\n\n');
      text = text.replaceAll(RegExp(r'<hr\s*/?>'), '\n\n---\n\n');
      text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');

      // 13. Semicolons followed by sub-definitions (e.g. ; *perish, be ruined...*) -> new indented bullet
      text = text.replaceAllMapped(
        RegExp(r';\s*(?:—\s*)?\*([a-z][^*]{3,40}\*)'),
        (m) => ';\n   - *${m.group(1)}',
      );

      // 14. HTML entities
      text = text
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'");

      // 15. Whitespace cleanup
      text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
      text = text.replaceAll(RegExp(r' *\n *'), '\n');
      text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
      return text.trim();
    };

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
