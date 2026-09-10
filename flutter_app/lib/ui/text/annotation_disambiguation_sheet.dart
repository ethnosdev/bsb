import 'package:flutter/material.dart';

class AnnotationDisambiguationSheet extends StatelessWidget {
  final String title;
  final String notePreview;
  final String footnotePreview;
  final VoidCallback onSelectNote;
  final VoidCallback onSelectFootnote;

  const AnnotationDisambiguationSheet({
    super.key,
    required this.title,
    required this.notePreview,
    required this.footnotePreview,
    required this.onSelectNote,
    required this.onSelectFootnote,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String notePreview,
    required String footnotePreview,
    required VoidCallback onSelectNote,
    required VoidCallback onSelectFootnote,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AnnotationDisambiguationSheet(
        title: title,
        notePreview: notePreview,
        footnotePreview: footnotePreview,
        onSelectNote: onSelectNote,
        onSelectFootnote: onSelectFootnote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.sticky_note_2_outlined,
                  color: theme.colorScheme.primary),
              title: const Text('My Note'),
              subtitle: Text(
                notePreview.isNotEmpty ? notePreview : 'Tap to view or edit note',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                onSelectNote();
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
              title: const Text('Translation Footnote'),
              subtitle: Text(
                footnotePreview.isNotEmpty ? footnotePreview : 'Tap to view footnote details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                onSelectFootnote();
              },
            ),
          ],
        ),
      ),
    );
  }
}
