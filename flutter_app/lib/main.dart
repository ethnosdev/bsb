import 'package:bsb/core/strings.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await getIt<DatabaseHelper>().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Strings.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF606f49)),
      ),
      home: const HomePage(),
    );
  }
}
