import 'dart:io';
import 'package:database_builder/src/language/language.dart';
import 'lexicon_record.dart';

class BdbParser {
  static List<LexiconRecord> parseFile(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final records = <LexiconRecord>[];

    final lemmaRegex = RegExp(r'<(?:bdbheb|bdbarc)>([^<]+)</(?:bdbheb|bdbarc)>');
    final strongsRegex = RegExp(r'H(\d+)');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final cols = line.split('\t');
      if (cols.length < 3) continue;

      final snCol = cols[1];
      final html = cols[2];

      final isAramaic = html.contains('BIBLICAL ARAMAIC');
      final language = isAramaic ? Language.aramaic.id : Language.hebrew.id;

      // Extract Strong's numbers
      final strongsNumbers = <int>[];
      for (final match in strongsRegex.allMatches(snCol)) {
        final num = int.tryParse(match.group(1)!);
        if (num != null && !strongsNumbers.contains(num)) {
          strongsNumbers.add(num);
        }
      }

      // Extract lemma
      final lemmaMatch = lemmaRegex.firstMatch(html);
      final lemma = lemmaMatch != null ? lemmaMatch.group(1)!.trim() : '';

      final markdown = cleanHtmlToMarkdown(html);
      if (markdown.isEmpty) continue;

      if (strongsNumbers.isEmpty) {
        records.add(
          LexiconRecord(
            language: language,
            strongs: -1,
            lemma: lemma,
            content: markdown,
          ),
        );
      } else {
        for (final sn in strongsNumbers) {
          records.add(
            LexiconRecord(
              language: language,
              strongs: sn,
              lemma: lemma,
              content: markdown,
            ),
          );
        }
      }
    }

    return records;
  }

  static String cleanHtmlToMarkdown(String html) {
    var text = html;

    // 1. Remove top headers and navigation boilerplate
    text = text.replaceAll(RegExp(r'<h1>.*?</h1>', dotAll: true), '');
    text = text.replaceAll(
      RegExp(r'<div class="navigation">.*?</div>', dotAll: true),
      '',
    );

    // 2. Remove placeholder tags and editorial flags
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
    // Fallback for any remaining <ref> tags
    text = text.replaceAllMapped(
      RegExp(r'<ref\b[^>]*>(.*?)</ref>', dotAll: true),
      (m) => m.group(1) ?? '',
    );

    // 4. Handle <reflink>:
    // Hebrew words -> [word](lex:word)
    // Non-Hebrew (J, E, P, ᵐ5, etc.) -> plain text
    final hebRegex = RegExp(r'[\u0590-\u05FF]');
    text = text.replaceAllMapped(
      RegExp(r'<reflink\b[^>]*>(.*?)</reflink>', dotAll: true),
      (m) {
        final inner = m.group(1)?.trim() ?? '';
        if (hebRegex.hasMatch(inner)) {
          return '[$inner](lex:$inner)';
        }
        return inner;
      },
    );

    // 5. Unwrap <lookup> and <entry> tags
    text = text.replaceAllMapped(
      RegExp(r'<lookup\b[^>]*>(.*?)</lookup>', dotAll: true),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'<entry\b[^>]*>(.*?)</entry>', dotAll: true),
      (m) => m.group(1) ?? '',
    );

    // Replace space entities before sense matching (e.g. <br>\&emsp;\&emsp;<b>a.</b>)
    text = text.replaceAll(RegExp(r'\\?&(?:emsp|ensp|nbsp|thinsp);?'), ' ');

    // 6. Section headers for stems (Qal, Niphal, Piel, etc.)
    const stems = [
      r'Qal', r'Niph`al', r'Niph\.', r'Niphal',
      r'Pi`el', r'Pi\.', r'Piel', r'Pu`al', r'Pual',
      r'Hiph`il', r'Hiph\.', r'Hiphil', r'Hoph`al', r'Hophal',
      r'Hithpa`el', r'Hithp\.', r'Hithpael',
      r'Po`el', r'Po`al', r'Pilpel', r'Polpal', r'Hithpolel', r'Hithpalpel',
      r'Pe`al', r'Pa`el', r'Aph`el', r'Haph`el', r'Ithpe`el', r'Ithpa`al', r'Shaph`el',
    ];
    final stemRegex = RegExp(
      '(?:<div class="point">|\\.\\s*|—\\s*|\\n\\s*)<b>(${stems.join('|')})</b>\\s*(?:—\\s*)?',
    );
    text = text.replaceAllMapped(stemRegex, (m) {
      final stem = m.group(1)!.replaceAll('`', "'");
      return '\n\n### $stem\n\n';
    });

    // 7. Senses and sub-senses:
    // Numbered senses: 1., 2., 3. -> bullet points
    text = text.replaceAllMapped(
      RegExp(r'(?:<div class="point">|\n\s*|;\s*|<br\s*/?>\s*)<b>(\d+\.)</b>\s*'),
      (m) => '\n\n• **${m.group(1)}** ',
    );
    // Lettered sub-senses: a., b., c. -> indented bullets
    text = text.replaceAllMapped(
      RegExp(r'(?:<div class="point">|\n\s*|;\s*|<br\s*/?>\s*)<b>([a-z]\.)</b>\s*'),
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
    final conjRegex = RegExp(
      '(?:;\\s*|—\\s*|\\.\\s*)<highlight>(${conjugations.join('|')})</highlight>',
    );
    text = text.replaceAllMapped(conjRegex, (m) => '\n\n- *${m.group(1)}*');

    // 9. Formatting tags
    text = text.replaceAllMapped(
      RegExp(r'<b>(.*?)</b>', dotAll: true),
      (m) => '**${m.group(1)}**',
    );
    text = text.replaceAllMapped(
      RegExp(r'<highlightword>(.*?)</highlightword>', dotAll: true),
      (m) => '**${m.group(1)}**',
    );
    text = text.replaceAllMapped(
      RegExp(r'<highlight>(.*?)</highlight>', dotAll: true),
      (m) => '*${m.group(1)}*',
    );
    text = text.replaceAllMapped(
      RegExp(r'<transliteration>(.*?)</transliteration>', dotAll: true),
      (m) => '*${m.group(1)}*',
    );

    // 10. Superscripts and subscripts
    text = text.replaceAllMapped(
      RegExp(r'<sup>(.*?)</sup>', dotAll: true),
      (m) => '^${m.group(1)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'<sub>(.*?)</sub>', dotAll: true),
      (m) => '_${m.group(1)}',
    );

    // 11. Foreign tags and unneeded tags
    text = text.replaceAll(
      RegExp(r'</?(?:bdbheb|bdbarc|grk|entry|big|u)>'),
      '',
    );

    // 12. Paragraphs and breaks
    text = text.replaceAll(RegExp(r'</?p>'), '\n\n');
    text = text.replaceAll(RegExp(r'<hr\s*/?>'), '\n\n---\n\n');
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');

    // 13. Semicolons followed by sub-definitions (e.g. ; *perish, be ruined...*) -> new indented bullet
    text = text.replaceAllMapped(
      RegExp(r';\s*(?:—\s*)?\*([a-z][^*]{3,40}\*)'),
      (m) => ';\n   - *${m.group(1)}',
    );

    // 14. HTML entities and space entities
    text = text
        .replaceAll(RegExp(r'\\?&(?:emsp|ensp|nbsp|thinsp);?'), ' ')
        .replaceAll(RegExp(r'\\&'), '&')
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
  }
}
