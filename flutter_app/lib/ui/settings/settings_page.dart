import 'package:flutter/material.dart';

import 'package:bsb/core/font_scale.dart';
import 'package:bsb/ui/annotations/annotation_file_handler.dart';
import 'package:bsb/ui/settings/user_settings.dart';

import 'settings_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final manager = SettingsManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, widget) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Light-Dark Theme'),
                subtitle: Text(
                  manager.themeMode == ThemeMode.light
                      ? 'Light'
                      : manager.themeMode == ThemeMode.dark
                      ? 'Dark'
                      : 'Match device settings',
                ),
                trailing: Icon(
                  manager.themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : manager.themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.smartphone,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            icon: Icon(Icons.smartphone),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {manager.themeMode},
                        onSelectionChanged: (Set<ThemeMode> selection) {
                          manager.setThemeMode(selection.first);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Text Size'),
                trailing: Text(
                  '${manager.textSize}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: SizedBox(
                        height: 150,
                        child: StatefulBuilder(
                          builder: (context, setState) => Column(
                            children: [
                              const Spacer(),
                              Text(
                                'Text Size',
                                style: TextStyle(fontSize: manager.textSize),
                              ),
                              const Spacer(),
                              Slider(
                                value: manager.textSize,
                                min: FontScale.minBaseSize,
                                max: FontScale.maxBaseSize,
                                divisions:
                                    (FontScale.maxBaseSize -
                                            FontScale.minBaseSize)
                                        .toInt(),
                                label: manager.textSize.toStringAsFixed(1),
                                onChanged: (value) {
                                  setState(() {
                                    manager.setTextSize(value);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Book Chooser Layout'),
                subtitle: Text(
                  manager.bookChooserStyle == BookChooserStyle.list
                      ? 'List'
                      : 'Grid',
                ),
                trailing: Icon(
                  manager.bookChooserStyle == BookChooserStyle.list
                      ? Icons.view_list
                      : Icons.grid_view,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Book Chooser Layout'),
                      content: SegmentedButton<BookChooserStyle>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment<BookChooserStyle>(
                            value: BookChooserStyle.grid,
                            label: Text('Grid'),
                            icon: Icon(Icons.grid_view),
                          ),
                          ButtonSegment<BookChooserStyle>(
                            value: BookChooserStyle.list,
                            label: Text('List'),
                            icon: Icon(Icons.view_list),
                          ),
                        ],
                        selected: {manager.bookChooserStyle},
                        onSelectionChanged: (Set<BookChooserStyle> selection) {
                          manager.setBookChooserStyle(selection.first);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Backup & Annotations',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Export Annotations'),
                subtitle: const Text('Backup highlights and notes to a file'),
                onTap: () {
                  _showExportChoiceDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: const Text('Import Annotations'),
                subtitle: const Text(
                  'Restore highlights and notes from a backup file',
                ),
                onTap: () {
                  AnnotationFileHandler().importJson(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportChoiceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Export Backup (JSON)'),
                subtitle: const Text(
                  'Complete backup for restoring on any device',
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  AnnotationFileHandler().exportJson(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Export as Markdown (.md)'),
                subtitle: const Text(
                  'Formatted text for reading and note-taking apps',
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  AnnotationFileHandler().exportMarkdown(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
