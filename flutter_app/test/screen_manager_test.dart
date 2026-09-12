import 'package:bsb/ui/text/screen_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextScreenManager URL generation', () {
    late TextScreenManager manager;

    setUp(() {
      manager = TextScreenManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('bibleHubUrl formats standard books', () {
      // Genesis 1:1
      expect(
        manager.bibleHubUrl(bookId: 1, chapter: 1, verse: 1),
        'https://biblehub.com/genesis/1-1.htm',
      );

      // John 3:16
      expect(
        manager.bibleHubUrl(bookId: 43, chapter: 3, verse: 16),
        'https://biblehub.com/john/3-16.htm',
      );
    });

    test('bibleHubUrl formats books with special naming', () {
      // Psalm 23:4 -> psalms
      expect(
        manager.bibleHubUrl(bookId: 19, chapter: 23, verse: 4),
        'https://biblehub.com/psalms/23-4.htm',
      );

      // Song of Solomon 2:1 -> songs
      expect(
        manager.bibleHubUrl(bookId: 22, chapter: 2, verse: 1),
        'https://biblehub.com/songs/2-1.htm',
      );

      // 1 Corinthians 13:4 -> 1_corinthians
      expect(
        manager.bibleHubUrl(bookId: 46, chapter: 13, verse: 4),
        'https://biblehub.com/1_corinthians/13-4.htm',
      );
    });

    test('bibleHubCrossReferenceUrl appends #crossref', () {
      // Psalm 23:4
      expect(
        manager.bibleHubCrossReferenceUrl(bookId: 19, chapter: 23, verse: 4),
        'https://biblehub.com/psalms/23-4.htm#crossref',
      );

      // Genesis 1:1
      expect(
        manager.bibleHubCrossReferenceUrl(bookId: 1, chapter: 1, verse: 1),
        'https://biblehub.com/genesis/1-1.htm#crossref',
      );
    });
  });
}
