# Berean Standard Bible

A mobile bible reader app for the [Berean Standard Bible](https://berean.bible/) - built with Flutter for Android and iOS.

- [Android Play Store](https://play.google.com/store/apps/details?id=dev.ethnos.bsb)
- [Apple App Store](https://apps.apple.com/gb/app/berean-standard-bible/id6740620392)


## Dependencies

This app does not build on its own. It needs two components from outside this folder:

**1. `database.db`** — a sqlite db containing the text for the Berean Standard Bible text itself. Build it with the `database_builder` project (in this repo, alongside `flutter_app`) and copy the result to:
```
assets/database/database.db
```

**2. `scripture`** - a Flutter package that renders scripture text and handles text selection. It lives in a separate repo and is included as a local path dependency in `pubspec.yaml`:
```yaml
scripture:
  path: ../../scripture
```

The `scripture` repo must be cloned as a sibling of this repo (i.e. both under the same parent folder), so the relative path resolves correctly.

```
parent-folder/
├── bsb/          ← this repo
└── scripture/    ← sibling repo, referenced via ../../scripture
```

## Build

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed. 
From the `flutter_app` folder, with both dependencies above in place:

```bash
flutter pub get          # fetch packages
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

See [LICENSE](../LICENSE) in the repository root.
