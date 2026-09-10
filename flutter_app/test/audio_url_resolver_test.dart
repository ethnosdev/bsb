import 'package:bsb/infrastructure/audio/audio_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioUrlResolver', () {
    const resolver = AudioUrlResolver();

    test('generates expected OpenBible Souer stream URLs', () {
      expect(
        resolver.getChapterUrl(1, 1),
        'https://openbible.com/audio/souer/BSB_01_Gen_001.mp3',
      );
      expect(
        resolver.getChapterUrl(1, 50),
        'https://openbible.com/audio/souer/BSB_01_Gen_050.mp3',
      );
      expect(
        resolver.getChapterUrl(19, 119),
        'https://openbible.com/audio/souer/BSB_19_Psa_119.mp3',
      );
      expect(
        resolver.getChapterUrl(56, 1),
        'https://openbible.com/audio/souer/BSB_56_Tts_001.mp3',
      );
      expect(
        resolver.getChapterUrl(66, 22),
        'https://openbible.com/audio/souer/BSB_66_Rev_022.mp3',
      );
    });

    test('supports custom base URL', () {
      const customResolver = AudioUrlResolver(
        baseUrl: 'https://mycustomserver.com/bsb_audio',
      );
      expect(
        customResolver.getChapterUrl(40, 5),
        'https://mycustomserver.com/bsb_audio/BSB_40_Mat_005.mp3',
      );
    });

    test('formats chapter title', () {
      expect(resolver.getChapterTitle(1, 1), 'Genesis 1');
      expect(resolver.getChapterTitle(19, 23), 'Psalm 23');
      expect(resolver.getChapterTitle(66, 22), 'Revelation 22');
    });

    test('calculates next chapter correctly within book and across books', () {
      // Within same book
      expect(resolver.getNextChapter(1, 1), (1, 2));
      expect(resolver.getNextChapter(1, 49), (1, 50));

      // Across book boundary
      expect(resolver.getNextChapter(1, 50), (2, 1)); // Genesis 50 -> Exodus 1
      expect(resolver.getNextChapter(39, 4), (40, 1)); // Malachi 4 -> Matthew 1

      // End of Bible
      expect(resolver.getNextChapter(66, 22), isNull);
    });

    test('calculates previous chapter correctly within book and across books', () {
      // Start of Bible
      expect(resolver.getPreviousChapter(1, 1), isNull);

      // Within same book
      expect(resolver.getPreviousChapter(1, 2), (1, 1));

      // Across book boundary
      expect(resolver.getPreviousChapter(2, 1), (1, 50)); // Exodus 1 -> Genesis 50
      expect(resolver.getPreviousChapter(40, 1), (39, 4)); // Matthew 1 -> Malachi 4
    });
  });
}
