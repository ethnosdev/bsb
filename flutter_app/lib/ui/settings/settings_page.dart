import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/annotations/annotation_file_handler.dart';
import 'package:bsb/ui/settings/theme/theme_selection_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AppState appState;

  @override
  void initState() {
    super.initState();
    appState = getIt<AppState>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, widget) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Light-Dark Mode'),
                  subtitle: Text(
                    appState.themeMode == ThemeMode.light
                        ? 'Light'
                        : appState.themeMode == ThemeMode.dark
                        ? 'Dark'
                        : 'Match device settings',
                  ),
                  trailing: Icon(
                    appState.themeMode == ThemeMode.light
                        ? Icons.light_mode
                        : appState.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.smartphone,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        content: SegmentedButton<ThemeMode>(
                          style: SegmentedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                          ),
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              label: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.light_mode),
                                    SizedBox(height: 4),
                                    Text('Light'),
                                  ],
                                ),
                              ),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              label: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.smartphone),
                                    SizedBox(height: 4),
                                    Text('Device'),
                                  ],
                                ),
                              ),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              label: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.dark_mode),
                                    SizedBox(height: 4),
                                    Text('Dark'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          selected: {appState.themeMode},
                          onSelectionChanged: (Set<ThemeMode> selection) {
                            appState.setThemeMode(selection.first);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Color Theme'),
                  subtitle: Text(
                    appState.isCustomTheme
                        ? 'Custom Theme'
                        : appState.currentThemePreset.name,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSelectionPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Text Size'),
                  trailing: Text(
                    '${appState.textSize}',
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
                                  style: TextStyle(fontSize: appState.textSize),
                                ),
                                const Spacer(),
                                Slider(
                                  value: appState.textSize,
                                  min: FontScale.minBaseSize,
                                  max: FontScale.maxBaseSize,
                                  divisions:
                                      (FontScale.maxBaseSize -
                                              FontScale.minBaseSize)
                                          .toInt(),
                                  label: appState.textSize.toStringAsFixed(1),
                                  onChanged: (value) {
                                    setState(() {
                                      appState.updateTextSizePreview(value);
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    appState.setTextSize(value);
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
                  value: appState.wordsOfJesusInRed,
                  onChanged: (bool value) {
                    appState.setWordsOfJesusInRed(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Keep Screen Awake'),
                  subtitle: const Text(
                    'Prevent screen from turning off while reading',
                  ),
                  value: appState.keepScreenAwake,
                  onChanged: (bool value) {
                    appState.setKeepScreenAwake(value);
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
                    appState.bookChooserStyle == BookChooserStyle.list
                        ? 'List'
                        : 'Grid',
                  ),
                  trailing: Icon(
                    appState.bookChooserStyle == BookChooserStyle.list
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
                          selected: {appState.bookChooserStyle},
                          onSelectionChanged:
                              (Set<BookChooserStyle> selection) {
                                appState.setBookChooserStyle(selection.first);
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
                    appState.chapterChooserStyle == ChapterChooserStyle.grid
                        ? 'Grid'
                        : 'Keypad',
                  ),
                  trailing: Icon(
                    appState.chapterChooserStyle == ChapterChooserStyle.grid
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
                          selected: {appState.chapterChooserStyle},
                          onSelectionChanged:
                              (Set<ChapterChooserStyle> selection) {
                                appState.setChapterChooserStyle(
                                  selection.first,
                                );
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
                    appState.verseChooserStyle == VerseChooserStyle.grid
                        ? 'Grid'
                        : 'Sidebar',
                  ),
                  trailing: Icon(
                    appState.verseChooserStyle == VerseChooserStyle.grid
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
                          selected: {appState.verseChooserStyle},
                          onSelectionChanged:
                              (Set<VerseChooserStyle> selection) {
                                appState.setVerseChooserStyle(selection.first);
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
                    'Backup',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Export Backup'),
                  subtitle: const Text(
                    'Backup highlights, notes, and playlists to a file',
                  ),
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
