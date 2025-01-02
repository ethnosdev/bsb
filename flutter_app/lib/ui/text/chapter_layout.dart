import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

class ChapterLayout extends StatefulWidget {
  const ChapterLayout({super.key, required this.paragraphs});

  /// The paragraphs will be rendered in order
  final List<(TextSpan, TextType)> paragraphs;

  @override
  State<ChapterLayout> createState() => _ChapterLayoutState();
}

class _ChapterLayoutState extends State<ChapterLayout> {
  static const _paragraphSpacing = SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    for (final (span, type) in widget.paragraphs) {
      switch (type) {
        case TextType.v:
          sections.add(SelectableText.rich(span));
          sections.add(_paragraphSpacing);
        case TextType.d:
          sections.add(SelectableText.rich(span));
        case TextType.r:
          sections.add(SelectableText.rich(span));
          sections.add(_paragraphSpacing);
        case TextType.s1:
          sections.add(SelectableText.rich(span));
          sections.add(_paragraphSpacing);
        case TextType.s2:
          sections.add(SelectableText.rich(span));
          sections.add(_paragraphSpacing);
        case TextType.ms:
          sections.add(SelectableText.rich(span));
        case TextType.mr:
          sections.add(SelectableText.rich(span));
        case TextType.qa:
          sections.add(SelectableText.rich(span));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }
}
