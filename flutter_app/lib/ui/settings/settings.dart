import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, widget) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Light-Dark Theme'),
                subtitle: Text(manager.themeMode == ThemeMode.light
                    ? 'Light'
                    : manager.themeMode == ThemeMode.dark
                        ? 'Dark'
                        : 'Match device settings'),
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
                        height: 100,
                        child: StatefulBuilder(
                          builder: (context, setState) => Column(
                            children: [
                              const Spacer(),
                              Text(
                                'Text Size',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              Slider(
                                value: manager.textSize,
                                min: 8,
                                max: 30,
                                divisions: 22,
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
              )
            ],
          );
        },
      ),
    );
  }
}
