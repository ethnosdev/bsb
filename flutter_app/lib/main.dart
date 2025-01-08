import 'package:bsb/core/strings.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_settings_screens/flutter_settings_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await getIt<DatabaseHelper>().init();
  await getIt<UserSettings>().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Strings.appName,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF606f49),
          secondary: Color(0xFF606f49),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Charis',
            ),
      ),
      home: const HomePage(),
    );
  }
}
