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
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: manager.isDarkMode,
                onChanged: (value) {
                  manager.setDarkMode(value);
                },
              ),
              ListTile(
                title: const Text('Text Size'),
                trailing: Text('${manager.textSize}'),
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
                                style: TextStyle(fontSize: manager.textSize),
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
