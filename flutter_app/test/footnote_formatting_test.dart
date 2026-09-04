import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dummyKeywords = RegExp(r'\b(2 Corinthians 4:6|1 Corinthians 15:45|LXX|MT)\b');

  test('formatFootnote preserves spaces around fqa text', () {
    final TextSpan span = formatFootnote(
      footnote:
          r'\fqa Selah\fqa* or \fqa Interlude\fqa* is probably a musical or literary term; here and throughout the Psalms.',
      highlightColor: Colors.blue,
      keywords: dummyKeywords,
      onTapKeyword: (kw, count) {},
    );

    final fullText = span.toPlainText();
    expect(
      fullText,
      equals(
        'Selah or Interlude is probably a musical or literary term;\nhere and throughout the Psalms.',
      ),
    );

    // Verify italic styles on Selah and Interlude
    final children = span.children!;
    expect(children.length, greaterThanOrEqualTo(4));

    // Selah should be italic
    final selahSpan = children[0] as TextSpan;
    expect(selahSpan.text, equals('Selah'));
    expect(selahSpan.style?.fontStyle, equals(FontStyle.italic));

    // " or " should NOT be italic
    final orSpan = children[1] as TextSpan;
    expect(orSpan.text, equals(' or '));
    expect(orSpan.style?.fontStyle, isNot(equals(FontStyle.italic)));

    // Interlude should be italic
    final interludeSpan = children[2] as TextSpan;
    expect(interludeSpan.text, equals('Interlude'));
    expect(interludeSpan.style?.fontStyle, equals(FontStyle.italic));

    // " is probably..." should NOT be italic
    final isSpan = children[3] as TextSpan;
    expect(isSpan.text, startsWith(' is probably'));
    expect(isSpan.style?.fontStyle, isNot(equals(FontStyle.italic)));
  });

  test('formatFootnote preserves punctuation immediately following fqa*', () {
    final TextSpan span = formatFootnote(
      footnote:
          r'Or \fqa Hallelu YAH\fqa*, meaning \fqa Praise the LORD\fqa*. This psalm is an acrostic poem.',
      highlightColor: Colors.blue,
      keywords: dummyKeywords,
      onTapKeyword: (kw, count) {},
    );

    final fullText = span.toPlainText();
    expect(
      fullText,
      equals(
        'Or Hallelu YAH, meaning Praise the LORD. This psalm is an acrostic poem.',
      ),
    );
  });
}
