import 'package:bsb/app_state.dart';
import 'package:bsb/core/strings.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await getIt<DatabaseHelper>().init();
  await getIt<UserSettings>().init();
  await getIt<AppState>().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final manager = getIt<AppState>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: manager.themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: Strings.appName,
          theme: MaterialTheme(
            ThemeData.light().textTheme.apply(fontFamily: 'Charis'),
          ).light(),
          darkTheme: MaterialTheme(
            ThemeData.dark().textTheme.apply(fontFamily: 'Charis'),
          ).dark(),
          themeMode: mode,
          home: const HomePage(),
        );
      },
    );
  }
}
