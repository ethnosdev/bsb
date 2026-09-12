import 'package:flutter/material.dart';

class NoteViewerSheet extends StatefulWidget {
  final String title;
  final String? passageText;
  final String content;
  final ValueChanged<String> onSave;
  final VoidCallback? onDelete;
  final bool initialEditMode;

  const NoteViewerSheet({
    super.key,
    required this.title,
    this.passageText,
    required this.content,
    required this.onSave,
    this.onDelete,
    this.initialEditMode = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? passageText,
    required String content,
    required ValueChanged<String> onSave,
    VoidCallback? onDelete,
    bool initialEditMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NoteViewerSheet(
        title: title,
        passageText: passageText,
        content: content,
        onSave: onSave,
        onDelete: onDelete,
        initialEditMode: initialEditMode,
      ),
    );
  }

  @override
  State<NoteViewerSheet> createState() => _NoteViewerSheetState();
}

class _NoteViewerSheetState extends State<NoteViewerSheet> {
  late bool _isEditing;
  late String _currentContent;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEditMode;
    _currentContent = widget.content;
    _textController = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete note for ${widget.title}?'),
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
      Navigator.of(context).pop();
      widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: bottomInset + 16,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header row
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit note',
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete note',
                    onPressed: _confirmDelete,
                  ),
              ],
            ],
          ),

          // Scripture passage snippet preview
          if (widget.passageText != null && widget.passageText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.passageText!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Content body: view mode vs edit mode
          if (!_isEditing) ...[
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SelectableText(
                    _currentContent,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: 7,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your note here...',
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: colorScheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _textController.text = _currentContent;
                      _isEditing = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final newContent = _textController.text.trim();
                    if (newContent.isEmpty) {
                      _confirmDelete();
                    } else {
                      setState(() {
                        _currentContent = newContent;
                        _isEditing = false;
                      });
                      widget.onSave(newContent);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
}
