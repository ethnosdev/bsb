# Getting Started

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

Building the app is a 2-step process.

## 1. Build the database

`database.db` is a SQLite database containing the text for the Berean Standard Bible. Build it from the `database_builder` project and copy the result to `flutter_app/assets/database/database.db`.

From the `database_builder` folder:

```bash
dart pub get 
dart run bin/main.dart
mkdir -p ../flutter_app/assets/database
cp database.db ../flutter_app/assets/database/database.db
```

## 2. Build the app

The BSB Android and iOS app is built from the `flutter_app` folder. 

From the `flutter_app` folder:

```bash
flutter pub get
flutter run
```

During development, running the MacOS version is generally the easiest if you have a Mac.

If this is your first Flutter project, start with the [online documentation](https://docs.flutter.dev/).