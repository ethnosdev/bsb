import 'package:bsb/infrastructure/database.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
}
