import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

class ChapterLayout extends StatefulWidget {
  const ChapterLayout({
    super.key,
    required this.paragraphs,
    required this.paragraphSpacing,
    required this.onDoubleTap,
  });

  /// The paragraphs will be rendered in order
  final List<(TextSpan, TextType, Format?)> paragraphs;
  final double paragraphSpacing;
  final void Function() onDoubleTap;

  @override
  State<ChapterLayout> createState() => _ChapterLayoutState();
}

class _ChapterLayoutState extends State<ChapterLayout> {
  late final _paragraphSpacing = SizedBox(height: widget.paragraphSpacing);

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    int index = 0;
    for (final (span, type, format) in widget.paragraphs) {
      switch (type) {
        case TextType.v:
          _applyFormat(sections, span, format);
        case TextType.d:
          sections.add(SelectableText.rich(
            span,
            textAlign: TextAlign.center,
          ));
          sections.add(_paragraphSpacing);
        case TextType.r:
          sections.add(SelectableText.rich(span));
          sections.add(_paragraphSpacing);
        case TextType.s1:
          if (sections.isNotEmpty && sections.last != _paragraphSpacing) {
            sections.add(_paragraphSpacing);
          }
          sections.add(SelectableText.rich(span));
          if (index < widget.paragraphs.length - 1 && //
              widget.paragraphs[index + 1].$2 != TextType.r) {
            sections.add(_paragraphSpacing);
          }
        case TextType.s2:
          if (sections.isNotEmpty && sections.last != _paragraphSpacing) {
            sections.add(_paragraphSpacing);
          }
          sections.add(SelectableText.rich(span));
          sections.add(_paragraphSpacing);
        case TextType.ms:
          sections.add(Center(
            child: SelectableText.rich(span),
          ));
        case TextType.mr:
          sections.add(Center(
            child: SelectableText.rich(span),
          ));
          sections.add(_paragraphSpacing);
        case TextType.qa:
          sections.add(SelectableText.rich(span));
      }
      index++;
    }
    sections.add(const SizedBox(height: 100));
    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  void _applyFormat(List<Widget> sections, TextSpan span, Format? format) {
    Widget text = SelectableText.rich(span);
    if (format != null) {
      switch (format) {
        case Format.m:
          // No padding needed for margin
          break;
        case Format.q1:
          text = Padding(padding: const EdgeInsets.only(left: 20), child: text);
        case Format.q2:
          text = Padding(padding: const EdgeInsets.only(left: 60), child: text);
        case Format.pmo:
          text = Padding(padding: const EdgeInsets.only(left: 20), child: text);
        case Format.li1:
          text = Padding(padding: const EdgeInsets.only(left: 20), child: text);
        case Format.li2:
          text = Padding(padding: const EdgeInsets.only(left: 60), child: text);
        case Format.pc:
          text = Align(alignment: Alignment.center, child: text);
        case Format.qr:
          text = Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: text,
            ),
          );
      }
    }
    sections.add(text);
    if (format != Format.q1 && format != Format.q2) {
      sections.add(_paragraphSpacing);
    }
  }
}
