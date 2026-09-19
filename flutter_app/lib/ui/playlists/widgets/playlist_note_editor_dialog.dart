import 'package:flutter/material.dart';

class PlaylistNoteEditorResult {
  final String? title;
  final String text;
  final bool isDeleted;

  const PlaylistNoteEditorResult({
    this.title,
    this.text = '',
    this.isDeleted = false,
  });
}

class PlaylistNoteEditorDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialText;
  final bool isEditing;

  const PlaylistNoteEditorDialog({
    super.key,
    this.initialTitle,
    this.initialText,
    this.isEditing = false,
  });

  static Future<PlaylistNoteEditorResult?> show(
    BuildContext context, {
    String? initialTitle,
    String? initialText,
    bool isEditing = false,
  }) {
    return showDialog<PlaylistNoteEditorResult>(
      context: context,
      builder: (ctx) => PlaylistNoteEditorDialog(
        initialTitle: initialTitle,
        initialText: initialText,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<PlaylistNoteEditorDialog> createState() => _PlaylistNoteEditorDialogState();
}

class _PlaylistNoteEditorDialogState extends State<PlaylistNoteEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _textController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note from the playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const PlaylistNoteEditorResult(isDeleted: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Note' : 'Add Note'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: 6,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isEditing)
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            onPressed: _delete,
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _textController,
          builder: (context, value, _) {
            final isBlank = value.text.trim().isEmpty;
            return FilledButton(
              onPressed: isBlank
                  ? null
                  : () {
                      final text = _textController.text.trim();
                      final title = _titleController.text.trim().isEmpty
                          ? null
                          : _titleController.text.trim();
                      Navigator.of(context).pop(
                        PlaylistNoteEditorResult(title: title, text: text),
                      );
                    },
              child: const Text('Save'),
            );
          },
        ),
      ],
    );
  }
}
