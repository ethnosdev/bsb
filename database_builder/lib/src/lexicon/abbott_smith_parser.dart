import 'dart:io';
import 'package:database_builder/src/language/language.dart';
import 'package:xml/xml.dart';
import 'lexicon_record.dart';

class AbbottSmithParser {
  static List<LexiconRecord> parseFile(String filePath) {
    final file = File(filePath);
    final document = XmlDocument.parse(file.readAsStringSync());

    final records = <LexiconRecord>[];
    final entries = document.findAllElements('entry');

    for (final entry in entries) {
      final nAttr = entry.getAttribute('n') ?? '';

      // Extract Strong's numbers (e.g. "ἀγαπάω|G25" or "ἅγιος|G40|G39")
      final strongsMatches = RegExp(r'G(\d+)').allMatches(nAttr);
      final strongsNumbers = <int>[];
      for (final match in strongsMatches) {
        final num = int.tryParse(match.group(1)!);
        if (num != null && !strongsNumbers.contains(num)) {
          strongsNumbers.add(num);
        }
      }

      // Extract lemma
      String lemma = '';
      if (nAttr.contains('|')) {
        lemma = nAttr.split('|')[0].trim();
      } else if (nAttr.isNotEmpty) {
        lemma = nAttr.trim();
      }

      if (lemma.isEmpty) {
        final orth = entry.findAllElements('orth').firstOrNull;
        if (orth != null && orth.innerText.trim().isNotEmpty) {
          lemma = orth.innerText.trim();
        } else {
          final formLemma = entry
              .findAllElements('form')
              .where((e) => e.getAttribute('type') == 'lemma')
              .firstOrNull;
          if (formLemma != null) {
            lemma = formLemma.innerText.trim();
          }
        }
      }

      final markdown = _renderEntryToMarkdown(entry).trim();
      if (markdown.isEmpty) continue;

      if (strongsNumbers.isEmpty) {
        // Untagged lemma (e.g. root/variant not directly in NT text)
        records.add(
          LexiconRecord(
            language: Language.greek.id,
            strongs: -1,
            lemma: lemma,
            content: markdown,
          ),
        );
      } else {
        for (final sn in strongsNumbers) {
          records.add(
            LexiconRecord(
              language: Language.greek.id,
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

  static String _renderEntryToMarkdown(XmlElement entry) {
    final buffer = StringBuffer();

    for (final node in entry.children) {
      if (node is XmlElement) {
        _renderElement(node, buffer);
      } else if (node is XmlText) {
        buffer.write(node.value);
      }
    }

    // Clean up excessive blank lines and spacing
    var text = buffer.toString();
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  static void _renderElement(XmlElement element, StringBuffer buffer) {
    final name = element.name.local;

    switch (name) {
      case 'note':
        // Skip occurrence counts notes
        if (element.getAttribute('type') == 'occurrencesNT') {
          return;
        }
        _renderChildren(element, buffer);

      case 'form':
        _renderChildren(element, buffer);
        buffer.write(' ');

      case 'orth':
        final text = element.innerText.trim();
        if (text.isNotEmpty) {
          buffer.write('**$text** ');
        }

      case 'gloss':
      case 'emph':
        final text = element.innerText.trim();
        if (text.isNotEmpty) {
          buffer.write('*$text*');
        }

      case 'sense':
        final n = element.getAttribute('n');
        buffer.writeln();
        if (n != null && n.isNotEmpty) {
          buffer.write('\n• **$n** ');
        } else {
          buffer.write('\n');
        }
        _renderChildren(element, buffer);

      case 'seg':
        if (element.getAttribute('type') == 'septuagint') {
          buffer.write('\n\n*LXX:* ');
          _renderChildren(element, buffer);
        } else {
          _renderChildren(element, buffer);
        }

      case 're':
        buffer.write('\n\n');
        _renderChildren(element, buffer);

      case 'etym':
        buffer.write('\n\n*Etymology:* ');
        _renderChildren(element, buffer);

      case 'ref':
        final osisRef = element.getAttribute('osisRef') ??
            element.getAttribute('osirisRef') ??
            element.getAttribute('OsirisRef') ??
            element.getAttribute('osirsRef') ??
            element.getAttribute('osisref');
        final target = element.getAttribute('target');
        final innerBuffer = StringBuffer();
        _renderChildren(element, innerBuffer);
        final innerText = innerBuffer.toString().trim();
        if (innerText.isEmpty) return;

        if (osisRef != null) {
          final parts = osisRef.split('.');
          if (parts.length >= 3) {
            final bookId = _osisBookToId[parts[0]];
            final ch = int.tryParse(parts[1]);
            final vs = int.tryParse(parts[2]);
            if (bookId != null && ch != null && vs != null) {
              final packed = bookId * 1000000 + ch * 1000 + vs;
              buffer.write('[$innerText](ref:$packed)');
              return;
            }
          }
          buffer.write('[$innerText](ref:$osisRef)');
          return;
        }

        if (target != null) {
          final cleanTarget = target.replaceAll('#', '').trim();
          buffer.write('[$innerText](lex:$cleanTarget)');
          return;
        }

        buffer.write(innerText);

      default:
        _renderChildren(element, buffer);
    }
  }

  static const Map<String, int> _osisBookToId = {
    'Gen': 1,
    'Exod': 2,
    'Lev': 3,
    'Num': 4,
    'Deut': 5,
    'Josh': 6,
    'Judg': 7,
    'Ruth': 8,
    '1Sam': 9,
    '2Sam': 10,
    '1Kgs': 11,
    '1Ki': 11,
    '2Kgs': 12,
    '2King': 12,
    '1Chr': 13,
    '2Chr': 14,
    'Ezra': 15,
    'Neh': 16,
    'Esth': 17,
    'Job': 18,
    'Ps': 19,
    'Psa': 19,
    'Prov': 20,
    'Eccl': 21,
    'Song': 22,
    'Isa': 23,
    'Jer': 24,
    'Lam': 25,
    'Ezek': 26,
    'Exek': 26,
    'Dan': 27,
    'DAn': 27,
    'Hos': 28,
    'Joel': 29,
    'Amos': 30,
    'Am': 30,
    'Obad': 31,
    'Jonah': 32,
    'Jon': 32,
    'Mic': 33,
    'Nah': 34,
    'Hab': 35,
    'Zeph': 36,
    'Hag': 37,
    'Zech': 38,
    'Mal': 39,
    'Matt': 40,
    'Mat': 40,
    'Mark': 41,
    'Mar': 41,
    'Mark14': 41,
    'Luke': 42,
    'John': 43,
    'Acts': 44,
    'Act': 44,
    'Rom': 45,
    '1Cor': 46,
    '1Cor15': 46,
    '2Cor': 47,
    'Gal': 48,
    'Eph': 49,
    'Phil': 50,
    'Phi': 50,
    'Col': 51,
    '1Thess': 52,
    '2Thess': 53,
    '1Tim': 54,
    '2Tim': 55,
    '2Ti': 55,
    'Titus': 56,
    'Phlm': 57,
    'Heb': 58,
    'Jas': 59,
    'Jam': 59,
    '1Pet': 60,
    '2Pet': 61,
    '1John': 62,
    '2John': 63,
    '3John': 64,
    'Jude': 65,
    'Rev': 66,
    'REv': 66,
  };

  static void _renderChildren(XmlElement element, StringBuffer buffer) {
    for (final node in element.children) {
      if (node is XmlElement) {
        _renderElement(node, buffer);
      } else if (node is XmlText) {
        buffer.write(node.value);
      }
    }
  }
}
