import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

class ChapterLayout extends StatefulWidget {
  const ChapterLayout({
    super.key,
    required this.paragraphs,
    required this.paragraphSpacing,
    this.bottomSpace = 300,
  });

  /// The paragraphs will be rendered in order
  final List<(TextSpan, ParagraphFormat)> paragraphs;
  final double paragraphSpacing;
  final double bottomSpace;

  @override
  State<ChapterLayout> createState() => _ChapterLayoutState();
}

class _ChapterLayoutState extends State<ChapterLayout> {
  late final _paragraphSpacing = SizedBox(height: widget.paragraphSpacing);

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    int index = 0;
    for (final (span, format) in widget.paragraphs) {
      switch (format) {
        case ParagraphFormat.d:
          sections.add(Text.rich(
            span,
            textAlign: TextAlign.center,
          ));
          sections.add(_paragraphSpacing);
        case ParagraphFormat.r:
          sections.add(Text.rich(span));
          sections.add(_paragraphSpacing);
        case ParagraphFormat.s1:
          if (sections.isNotEmpty && sections.last != _paragraphSpacing) {
            sections.add(_paragraphSpacing);
          }
          sections.add(Text.rich(span));
          if (index < widget.paragraphs.length - 1 && //
              widget.paragraphs[index + 1].$2 != ParagraphFormat.r) {
            sections.add(_paragraphSpacing);
          }
        case ParagraphFormat.s2:
          if (sections.isNotEmpty && sections.last != _paragraphSpacing) {
            sections.add(_paragraphSpacing);
          }
          sections.add(Text.rich(span));
          sections.add(_paragraphSpacing);
        case ParagraphFormat.ms:
          sections.add(Center(
            child: Text.rich(span),
          ));
        case ParagraphFormat.mr:
          sections.add(Center(
            child: Text.rich(span),
          ));
          sections.add(_paragraphSpacing);
        case ParagraphFormat.qa:
          sections.add(Text.rich(span));
        default:
          _applyFormat(sections, span, format);
      }
      index++;
    }
    sections.add(SizedBox(height: widget.bottomSpace));
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  void _applyFormat(
      List<Widget> sections, TextSpan span, ParagraphFormat format) {
    Widget text = Text.rich(span);

    switch (format) {
      case ParagraphFormat.m:
        // No padding needed for margin
        break;
      case ParagraphFormat.q1:
        text = Padding(padding: const EdgeInsets.only(left: 20), child: text);
      case ParagraphFormat.q2:
        text = Padding(padding: const EdgeInsets.only(left: 60), child: text);
      case ParagraphFormat.pmo:
        text = Padding(padding: const EdgeInsets.only(left: 20), child: text);
      case ParagraphFormat.li1:
        text = Padding(padding: const EdgeInsets.only(left: 20), child: text);
      case ParagraphFormat.li2:
        text = Padding(padding: const EdgeInsets.only(left: 60), child: text);
      case ParagraphFormat.pc:
        text = Align(alignment: Alignment.center, child: text);
      case ParagraphFormat.qr:
        text = Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: text,
          ),
        );
      default:
      // do nothing?
    }

    sections.add(text);
    if (format != ParagraphFormat.q1 && format != ParagraphFormat.q2) {
      sections.add(_paragraphSpacing);
    }
  }
}
