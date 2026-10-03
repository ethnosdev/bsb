import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to launch the Memorize Scripture app or fall back to the appropriate app store.
class MemorizeScriptureLauncher {
  static const String scheme = 'memorizescripture';
  static const String host = 'add';
  static const String androidPackageId = 'dev.ethnos.memorize_scripture';
  static const String iosAppStoreId = '6449814205';

  /// Builds the deep link URI to add a verse in the Memorize Scripture app.
  static Uri buildMemorizeUri({
    required String prompt,
    required String text,
    String? version,
  }) {
    return Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        'prompt': prompt,
        'text': text,
        if (version != null) 'version': version,
      },
    );
  }

  /// Gets the platform store URI (market:// on Android, https://apps.apple.com on iOS).
  static Uri getStoreUri({
    TargetPlatform? platform,
  }) {
    final currentPlatform = platform ?? defaultTargetPlatform;
    if (currentPlatform == TargetPlatform.android) {
      return Uri.parse('market://details?id=$androidPackageId');
    } else if (currentPlatform == TargetPlatform.iOS) {
      return Uri.parse('https://apps.apple.com/app/id$iosAppStoreId');
    } else {
      // Fallback for desktop / web
      return Uri.parse(
        'https://apps.apple.com/us/app/memorize-scripture-ethnosdev/id$iosAppStoreId',
      );
    }
  }

  /// Gets the web fallback URL for the store.
  static Uri getWebStoreUri({
    TargetPlatform? platform,
  }) {
    final currentPlatform = platform ?? defaultTargetPlatform;
    if (currentPlatform == TargetPlatform.android) {
      return Uri.parse(
        'https://play.google.com/store/apps/details?id=$androidPackageId',
      );
    } else {
      return Uri.parse('https://apps.apple.com/app/id$iosAppStoreId');
    }
  }

  /// Attempts to launch the Memorize Scripture app via deep link.
  /// If the app is not installed (canLaunchUrl is false), opens the platform app store.
  static Future<bool> launchMemorize({
    required String prompt,
    required String text,
    String? version,
    Future<bool> Function(Uri uri)? canLaunch,
    Future<bool> Function(Uri uri, {LaunchMode mode})? launch,
    TargetPlatform? platform,
  }) async {
    final canLaunchFn = canLaunch ?? canLaunchUrl;
    final launchFn = launch ??
        ((uri, {mode = LaunchMode.platformDefault}) =>
            launchUrl(uri, mode: mode));

    final deepLinkUri = buildMemorizeUri(
      prompt: prompt,
      text: text,
      version: version,
    );

    // 1. Try launching deep link if canLaunch returns true
    try {
      if (await canLaunchFn(deepLinkUri)) {
        if (await launchFn(deepLinkUri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      }
    } catch (_) {}

    // 2. If canLaunch returned false, Android 11+ package visibility checks
    // can return false negatives. Try launching directly when running in app.
    if (canLaunch == null && launch == null) {
      try {
        if (await launchFn(deepLinkUri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {}
    }

    // 3. App is not installed -> redirect to app store
    final storeUri = getStoreUri(platform: platform);
    try {
      if (await canLaunchFn(storeUri)) {
        if (await launchFn(storeUri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      }
    } catch (_) {}

    final webStoreUri = getWebStoreUri(platform: platform);
    try {
      if (await canLaunchFn(webStoreUri)) {
        return await launchFn(webStoreUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    return false;
  }
}
