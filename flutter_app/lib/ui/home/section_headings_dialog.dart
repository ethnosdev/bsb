import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/section_heading.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:flutter/material.dart';

class SectionHeadingsDialog extends StatefulWidget {
  final int bookId;
  final String bookName;
  final Future<List<SectionHeading>> Function(int bookId)? headingsLoader;

  const SectionHeadingsDialog({
    super.key,
    required this.bookId,
    required this.bookName,
    this.headingsLoader,
  });

  @override
  State<SectionHeadingsDialog> createState() => _SectionHeadingsDialogState();
}

class _SectionHeadingsDialogState extends State<SectionHeadingsDialog> {
  late final Future<List<SectionHeading>> _headingsFuture;

  @override
  void initState() {
    super.initState();
    final loader = widget.headingsLoader ??
        (bookId) => getIt<DatabaseHelper>().getSectionHeadings(bookId);
    _headingsFuture = loader(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                '${widget.bookName} Sections',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<SectionHeading>>(
                future: _headingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading sections: ${snapshot.error}'),
                    );
                  }
                  final headings = snapshot.data ?? [];
                  if (headings.isEmpty) {
                    return const Center(
                      child: Text('No section headings found'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: headings.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final heading = headings[index];
                      return ListTile(
                        key: ValueKey('section_heading_$index'),
                        contentPadding: EdgeInsets.only(
                          left: heading.isSubheading ? 36.0 : 20.0,
                          right: 20.0,
                        ),
                        title: Text(
                          heading.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: heading.isSubheading
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          heading.referenceDisplay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(heading),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
