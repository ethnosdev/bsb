# Berean Standard Bible app

A mobile bible reader app for the [Berean Standard Bible](https://berean.bible/) - built with Flutter for Android and iOS.

- [Android Play Store](https://play.google.com/store/apps/details?id=dev.ethnos.bsb)
- [Apple App Store](https://apps.apple.com/gb/app/berean-standard-bible/id6740620392)

See the [road map](https://github.com/ethnosdev/bsb/wiki) for planned features.

## Build

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

Building the app is a 2 step process.

### 1. Build the database

`database.db` is a sqlite db containing the text for the Berean Standard Bible. Build it from the `database_builder` project and copy the result to `flutter_app/assets/database/database.db`.

From the `database_builder` folder:

```bash
dart pub get              # fetch packages
dart run bin/main.dart    # compiles + runs main.dart
mkdir -p ../flutter_app/assets/database
cp database.db ../flutter_app/assets/database/database.db
```

### 2. Build the app

The bsb (Berean Standard Bible) app is built from the `flutter_app` folder. It uses `scripture`, a text rendering and word referencing component published on [pub.dev](https://pub.dev/packages/scripture).

From the `flutter_app` folder on a Mac with Xcode installed:

```bash
flutter pub get          # fetch packages
open -a Simulator        # launch the iOS Simulator
flutter run              # run on a connected device or emulator
```

To build a release artifact:

```bash
flutter build apk        # Android
flutter build ipa        # iOS (requires macOS and Xcode)
```

If this is your first Flutter project, start with the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## License

See [LICENSE](LICENSE) in the repository root.
