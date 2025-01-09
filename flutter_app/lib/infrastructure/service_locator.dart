import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  getIt.registerLazySingleton<UserSettings>(() => UserSettings());
  getIt.registerLazySingleton<AppState>(() => AppState());
}
