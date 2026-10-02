import 'package:bsb/infrastructure/memorize_scripture_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('MemorizeScriptureLauncher', () {
    test('buildMemorizeUri generates correct URI', () {
      final uri = MemorizeScriptureLauncher.buildMemorizeUri(
        prompt: 'John 3:16',
        text: 'For God so loved the world',
        version: 'BSB',
      );

      expect(uri.scheme, 'memorizescripture');
      expect(uri.host, 'add');
      expect(uri.queryParameters['prompt'], 'John 3:16');
      expect(uri.queryParameters['text'], 'For God so loved the world');
      expect(uri.queryParameters['version'], 'BSB');
    });

    test('getStoreUri returns correct URI per platform', () {
      final androidUri = MemorizeScriptureLauncher.getStoreUri(
        platform: TargetPlatform.android,
      );
      expect(androidUri.toString(), 'market://details?id=dev.ethnos.memorize_scripture');

      final iosUri = MemorizeScriptureLauncher.getStoreUri(
        platform: TargetPlatform.iOS,
      );
      expect(iosUri.toString(), 'https://apps.apple.com/app/id6449814205');
    });

    test('getWebStoreUri returns correct URI per platform', () {
      final androidUri = MemorizeScriptureLauncher.getWebStoreUri(
        platform: TargetPlatform.android,
      );
      expect(
        androidUri.toString(),
        'https://play.google.com/store/apps/details?id=dev.ethnos.memorize_scripture',
      );

      final iosUri = MemorizeScriptureLauncher.getWebStoreUri(
        platform: TargetPlatform.iOS,
      );
      expect(iosUri.toString(), 'https://apps.apple.com/app/id6449814205');
    });

    test('launchMemorize launches deep link when app is installed', () async {
      Uri? launchedUri;
      LaunchMode? launchedMode;

      final result = await MemorizeScriptureLauncher.launchMemorize(
        prompt: 'Romans 8:28',
        text: 'And we know that in all things God works for the good...',
        canLaunch: (uri) async => uri.scheme == 'memorizescripture',
        launch: (uri, {mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          launchedMode = mode;
          return true;
        },
      );

      expect(result, isTrue);
      expect(launchedUri, isNotNull);
      expect(launchedUri!.scheme, 'memorizescripture');
      expect(launchedUri!.host, 'add');
      expect(launchedUri!.queryParameters['prompt'], 'Romans 8:28');
      expect(launchedMode, LaunchMode.externalApplication);
    });

    test('launchMemorize falls back to store when app is not installed', () async {
      Uri? launchedUri;
      LaunchMode? launchedMode;

      final result = await MemorizeScriptureLauncher.launchMemorize(
        prompt: 'Romans 8:28',
        text: 'And we know that in all things God works for the good...',
        platform: TargetPlatform.android,
        canLaunch: (uri) async {
          // App not installed, but store market:// works
          return uri.scheme == 'market';
        },
        launch: (uri, {mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          launchedMode = mode;
          return true;
        },
      );

      expect(result, isTrue);
      expect(launchedUri, isNotNull);
      expect(launchedUri.toString(), 'market://details?id=dev.ethnos.memorize_scripture');
      expect(launchedMode, LaunchMode.externalApplication);
    });

    test('launchMemorize falls back to web store when market uri is unsupported', () async {
      Uri? launchedUri;
      LaunchMode? launchedMode;

      final result = await MemorizeScriptureLauncher.launchMemorize(
        prompt: 'Romans 8:28',
        text: 'And we know that in all things God works for the good...',
        platform: TargetPlatform.android,
        canLaunch: (uri) async {
          // Only https web links work
          return uri.scheme == 'https';
        },
        launch: (uri, {mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          launchedMode = mode;
          return true;
        },
      );

      expect(result, isTrue);
      expect(launchedUri, isNotNull);
      expect(
        launchedUri.toString(),
        'https://play.google.com/store/apps/details?id=dev.ethnos.memorize_scripture',
      );
      expect(launchedMode, LaunchMode.externalApplication);
    });
  });
}
