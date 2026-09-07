import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleSearchService.computeMatchSpans', () {
    test('finds single word match', () {
      const text = 'In the beginning God created the heavens and the earth.';
      final spans = BibleSearchService.computeMatchSpans(text, 'God');
      expect(spans, equals([(17, 20)]));
      expect(text.substring(spans.first.$1, spans.first.$2), equals('God'));
    });

    test('finds case-insensitive matches', () {
      const text = 'Light shines in the darkness, and God called the light day.';
      final spans = BibleSearchService.computeMatchSpans(text, 'light');
      expect(spans.length, equals(2));
      expect(text.substring(spans[0].$1, spans[0].$2), equals('Light'));
      expect(text.substring(spans[1].$1, spans[1].$2), equals('light'));
    });

    test('finds multi-word matches', () {
      const text = 'Now faith, hope, and love remain—these three; but the greatest of these is love.';
      final spans = BibleSearchService.computeMatchSpans(text, 'faith love');
      expect(spans.length, equals(3));
      expect(text.substring(spans[0].$1, spans[0].$2), equals('faith'));
      expect(text.substring(spans[1].$1, spans[1].$2), equals('love'));
      expect(text.substring(spans[2].$1, spans[2].$2), equals('love'));
    });

    test('finds exact quoted phrase matches', () {
      const text = 'In the beginning was the Word, and the Word was with God.';
      final spans = BibleSearchService.computeMatchSpans(text, '"In the beginning"');
      expect(spans, equals([(0, 16)]));
      expect(text.substring(spans.first.$1, spans.first.$2), equals('In the beginning'));
    });

    test('handles empty or special character inputs without error', () {
      const text = 'Jesus wept.';
      expect(BibleSearchService.computeMatchSpans(text, ''), isEmpty);
      expect(BibleSearchService.computeMatchSpans(text, '???'), isEmpty);
      expect(BibleSearchService.computeMatchSpans('', 'Jesus'), isEmpty);
    });
  });
}
