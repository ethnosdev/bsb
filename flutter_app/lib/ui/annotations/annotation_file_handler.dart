import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bsb/infrastructure/annotation_backup.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';

class AnnotationFileHandler {
  final AnnotationService _annotationService;

  AnnotationFileHandler({AnnotationService? annotationService})
      : _annotationService = annotationService ?? getIt<AnnotationService>();

  static String _todayDateString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Rect? _getSharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return null;
  }

  Future<void> exportJson(BuildContext context) async {
    final backup = await _annotationService.createBackup();

    if (!context.mounted) return;

    if (backup.highlights.isEmpty && backup.notes.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export Annotations'),
          content: const Text(
            'You currently have no highlights or notes saved. Do you still want to export an empty backup?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Export Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!context.mounted) return;

    final fileName = 'bsb_annotations_${_todayDateString()}.json';
    final jsonContent = backup.toJson(pretty: true);

    await _saveOrShareFile(
      context: context,
      content: jsonContent,
      fileName: fileName,
      dialogTitle: 'Export Annotations Backup (JSON)',
      allowedExtensions: ['json'],
    );
  }

  Future<void> exportMarkdown(BuildContext context) async {
    final backup = await _annotationService.createBackup();

    if (!context.mounted) return;

    if (backup.highlights.isEmpty && backup.notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No highlights or notes to export as Markdown.'),
        ),
      );
      return;
    }

    final fileName = 'bsb_annotations_${_todayDateString()}.md';
    final mdContent = backup.toMarkdown();

    await _saveOrShareFile(
      context: context,
      content: mdContent,
      fileName: fileName,
      dialogTitle: 'Export Annotations as Markdown',
      allowedExtensions: ['md'],
    );
  }

  Future<void> _saveOrShareFile({
    required BuildContext context,
    required String content,
    required String fileName,
    required String dialogTitle,
    required List<String> allowedExtensions,
  }) async {
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    if (isDesktop) {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        bytes: utf8.encode(content),
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (savedUri != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $fileName'),
          ),
        );
      }
    } else {
      // Mobile (iOS, Android)
      final origin = _getSharePositionOrigin(context);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(content);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          subject: fileName,
          sharePositionOrigin: origin,
        ),
      );
    }
  }

  Future<void> importJson(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (file == null) {
      return;
    }

    String content;
    try {
      final bytes = await file.readAsBytes();
      content = utf8.decode(bytes);
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Unable to read the selected file: $e');
      }
      return;
    }

    AnnotationBackup backup;
    try {
      backup = AnnotationBackup.fromJson(content);
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'The selected file is not a valid BSB annotations backup file.\n\nError: $e',
        );
      }
      return;
    }

    if (!context.mounted) return;

    final existingBackup = await _annotationService.createBackup();
    final hasExisting =
        existingBackup.highlights.isNotEmpty || existingBackup.notes.isNotEmpty;

    if (!context.mounted) return;

    final mode = await _showImportConfirmationDialog(
      context: context,
      highlightsCount: backup.highlights.length,
      notesCount: backup.notes.length,
      hasExisting: hasExisting,
    );

    if (mode == null || !context.mounted) return;

    final importResult = await _annotationService.restoreBackup(
      backup,
      mode: mode,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${importResult.highlightsImported} highlights and ${importResult.notesImported} notes (${mode == AnnotationImportMode.merge ? 'merged' : 'replaced'}).',
          ),
        ),
      );
    }
  }

  Future<AnnotationImportMode?> _showImportConfirmationDialog({
    required BuildContext context,
    required int highlightsCount,
    required int notesCount,
    required bool hasExisting,
  }) async {
    AnnotationImportMode selectedMode = AnnotationImportMode.merge;

    return showDialog<AnnotationImportMode>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Import Annotations'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found $highlightsCount highlights and $notesCount notes in the backup file.',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  if (hasExisting) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Choose import option:',
                      style: Theme.of(ctx)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<AnnotationImportMode>(
                      groupValue: selectedMode,
                      onChanged: (mode) {
                        if (mode != null) {
                          setDialogState(() => selectedMode = mode);
                        }
                      },
                      child: Column(
                        children: const [
                          RadioListTile<AnnotationImportMode>(
                            title: Text('Merge with existing'),
                            subtitle: Text(
                              'Keeps existing items and adds new ones (updates matches).',
                            ),
                            value: AnnotationImportMode.merge,
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<AnnotationImportMode>(
                            title: Text('Replace all existing'),
                            subtitle: Text(
                              'Deletes current highlights & notes and restores from backup.',
                            ),
                            value: AnnotationImportMode.replace,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(selectedMode),
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
