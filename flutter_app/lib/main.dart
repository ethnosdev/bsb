import 'package:bsb/app_state.dart';
import 'package:bsb/core/strings.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reading_plan_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await getIt<DatabaseHelper>().init();
  await getIt<UserSettings>().init();
  await getIt<TabManager>().init();
  await getIt<AppState>().init();
  await getIt<ReadingPlanService>().init();
  await initAudioService();
  runApp(const MyApp());
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final manager = getIt<AppState>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver],
          title: Strings.appName,
          theme: manager.lightThemeData,
          darkTheme: manager.darkThemeData,
          themeMode: manager.themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
