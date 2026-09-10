import 'package:audio_service/audio_service.dart';
import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
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

Future<void> initAudioService() async {
  if (getIt.isRegistered<AudioPlaybackManager>()) return;

  try {
    final audioHandler = await AudioService.init(
      builder: () => BsbAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'dev.ethnos.bsb.audio',
        androidNotificationChannelName: 'BSB Audio Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    getIt.registerSingleton<AudioHandler>(audioHandler);
    getIt.registerSingleton<BsbAudioHandler>(audioHandler);
    getIt.registerSingleton<AudioPlaybackManager>(
      AudioPlaybackManager(audioHandler: audioHandler),
    );
  } catch (_) {
    final fallbackHandler = BsbAudioHandler();
    getIt.registerSingleton<AudioHandler>(fallbackHandler);
    getIt.registerSingleton<BsbAudioHandler>(fallbackHandler);
    getIt.registerSingleton<AudioPlaybackManager>(
      AudioPlaybackManager(audioHandler: fallbackHandler),
    );
  }
}

