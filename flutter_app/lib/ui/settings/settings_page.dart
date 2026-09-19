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
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
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
                SwitchListTile(
                  title: const Text('Words of Jesus in Red'),
                  value: manager.wordsOfJesusInRed,
                  onChanged: (bool value) {
                    manager.setWordsOfJesusInRed(value);
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Navigation',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Book Chooser'),
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
                        title: const Text('Book Chooser'),
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
                ListTile(
                  title: const Text('Chapter Chooser'),
                  subtitle: Text(
                    manager.chapterChooserStyle == ChapterChooserStyle.grid
                        ? 'Grid'
                        : 'Keypad',
                  ),
                  trailing: Icon(
                    manager.chapterChooserStyle == ChapterChooserStyle.grid
                        ? Icons.grid_view
                        : Icons.dialpad,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Chapter Chooser'),
                        content: SegmentedButton<ChapterChooserStyle>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<ChapterChooserStyle>(
                              value: ChapterChooserStyle.keypad,
                              label: Text('Keypad'),
                              icon: Icon(Icons.dialpad),
                            ),
                            ButtonSegment<ChapterChooserStyle>(
                              value: ChapterChooserStyle.grid,
                              label: Text('Grid'),
                              icon: Icon(Icons.grid_view),
                            ),
                          ],
                          selected: {manager.chapterChooserStyle},
                          onSelectionChanged:
                              (Set<ChapterChooserStyle> selection) {
                            manager.setChapterChooserStyle(selection.first);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Verse Chooser'),
                  subtitle: Text(
                    manager.verseChooserStyle == VerseChooserStyle.grid
                        ? 'Grid'
                        : 'Sidebar',
                  ),
                  trailing: Icon(
                    manager.verseChooserStyle == VerseChooserStyle.grid
                        ? Icons.grid_view
                        : Icons.view_sidebar,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Verse Chooser'),
                        content: SegmentedButton<VerseChooserStyle>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<VerseChooserStyle>(
                              value: VerseChooserStyle.sidebar,
                              label: Text('Sidebar'),
                              icon: Icon(Icons.view_sidebar),
                            ),
                            ButtonSegment<VerseChooserStyle>(
                              value: VerseChooserStyle.grid,
                              label: Text('Grid'),
                              icon: Icon(Icons.grid_view),
                            ),
                          ],
                          selected: {manager.verseChooserStyle},
                          onSelectionChanged:
                              (Set<VerseChooserStyle> selection) {
                            manager.setVerseChooserStyle(selection.first);
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
                  title: const Text('Export Backup'),
                  subtitle: const Text('Backup highlights, notes, and playlists to a file'),
                  onTap: () {
                    _showExportChoiceDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Import Backup'),
                  subtitle: const Text(
                    'Restore highlights, notes, and playlists from a backup file',
                  ),
                  onTap: () {
                    AnnotationFileHandler().importJson(context);
                  },
                ),
              ],
            );
          },
        ),
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
