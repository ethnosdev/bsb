import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:bsb/ui/search/search_manager.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  getIt.registerLazySingleton<AnnotationDatabaseHelper>(
    () => AnnotationDatabaseHelper(),
  );
  getIt.registerLazySingleton<AnnotationService>(
    () => AnnotationService(dbHelper: getIt<AnnotationDatabaseHelper>()),
  );
  getIt.registerLazySingleton<BibleSearchService>(
    () => BibleSearchService(dbHelper: getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<SearchManager>(
    () => SearchManager(
      searchService: getIt<BibleSearchService>(),
      userSettings: getIt<UserSettings>(),
    ),
  );
  getIt.registerLazySingleton<UserSettings>(() => UserSettings());
  getIt.registerLazySingleton<TabManager>(() => TabManager());
  getIt.registerLazySingleton<AppState>(() => AppState());
}
