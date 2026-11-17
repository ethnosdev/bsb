import 'dart:io';

import 'package:database_builder/database_builder.dart';
import 'package:database_builder/src/audio_timings_table.dart';
import 'package:database_builder/src/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late DatabaseHelper dbHelper;
  late Directory timingsDir;

  void seedBibleVerses(List<(int book, int chapter, int verse)> verses) {
    dbHelper.beginTransaction();
    for (final (b, c, v) in verses) {
      dbHelper.insertBsbLine(
        bookId: b,
        chapter: c,
        verse: v,
        text: 'Verse $b:$c:$v',
        format: 'p',
      );
    }
    dbHelper.commitTransaction();
  }

  void writeTimingFile(String subdir, String filename, String content) {
    final dir = Directory(p.join(timingsDir.path, subdir))
      ..createSync(recursive: true);
    File(p.join(dir.path, filename)).writeAsStringSync(content);
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('audio_timings_test_');
    dbHelper = DatabaseHelper(databaseName: p.join(tempDir.path, 'test.db'));
    dbHelper.init();
    timingsDir = Directory(p.join(tempDir.path, 'timings'))..createSync();
  });

  tearDown(() {
    dbHelper.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('accepts valid multi-chapter fixture, ignores dotfiles, and rounds ms', () async {
    seedBibleVerses([
      (10, 1, 1),
      (10, 1, 2),
      (10, 2, 1),
      (43, 10, 1),
      (43, 10, 2),
    ]);

    writeTimingFile(
      'OT',
      '.DS_Store',
      'binary junk',
    );
    writeTimingFile(
      'OT',
      'BSB_10_2Sa_001_timing.txt',
      '\\id 2Sa\r\n\\c 001\r\n\\level phrase\r\n\r\n'
          '4.73\t11.48\t10001001\r\n'
          '11.48\t20.95\t10001002\r\n',
    );
    writeTimingFile(
      'OT',
      'BSB_10_2Sa_002_timing.txt',
      '\\id 2Sa\n\\c 002\n\\level phrase\n'
          '4.67\t16.55\t10002001\n',
    );
    writeTimingFile(
      'NT',
      'BSB_43_Jhn_010_timing.txt',
      '\\id Jhn\n\\c 010\n\\level phrase\n'
          '4.7\t266.77\t43010001\n'
          '266.77\t271.656\t43010002\n',
    );

    await createAudioTimingsTable(
      dbHelper,
      timingsDirPath: timingsDir.path,
      expectedFileCount: 3,
    );

    final rows = dbHelper.database.select(
      'SELECT reference, start_ms, end_ms FROM ${Schema.audioTimingsTable} ORDER BY reference;',
    );
    expect(rows.length, 5);
    expect(rows.last['reference'], 43010002);
    expect(rows.last['start_ms'], 266770);
    expect(rows.last['end_ms'], 271656);
  });

  test('rule 1: rejects invalid filename', () async {
    seedBibleVerses([(43, 10, 1)]);
    writeTimingFile(
      'NT',
      'bad_name.txt',
      '\\id Jhn\n\\c 010\n\\level phrase\n4.7\t12.95\t43010001\n',
    );

    await expectLater(
      () => parseAndValidateAudioTimings(
        dbHelper: dbHelper,
        timingsDirPath: timingsDir.path,
        expectedFileCount: 1,
      ),
      throwsA(
        isA<AudioTimingsValidationException>().having(
          (e) => e.violations.join('\n'),
          'violations',
          contains('Invalid timing filename'),
        ),
      ),
    );
  });

  test('rule 2: rejects mismatched \\id or \\c header', () async {
    seedBibleVerses([(43, 10, 1)]);
    writeTimingFile(
      'NT',
      'BSB_43_Jhn_010_timing.txt',
      '\\id Mat\n\\c 009\n\\level phrase\n4.7\t12.95\t43010001\n',
    );

    await expectLater(
      () => parseAndValidateAudioTimings(
        dbHelper: dbHelper,
        timingsDirPath: timingsDir.path,
        expectedFileCount: 1,
      ),
      throwsA(
        isA<AudioTimingsValidationException>().having(
          (e) => e.violations.join('\n'),
          'violations',
          allOf(contains(r'\id'), contains(r'\c')),
        ),
      ),
    );
  });

  test('rules 3 & 4: rejects numbered-book chapter-1 bug and duplicates', () async {
    seedBibleVerses([
      (9, 1, 1),
      (9, 2, 1),
    ]);
    writeTimingFile(
      'OT',
      'BSB_09_1Sa_001_timing.txt',
      '\\id 1Sa\n\\c 001\n\\level phrase\n4.0\t10.0\t09001001\n',
    );
    // Simulates the real-world bug: \c 002 file whose row IDs say chapter 1.
    writeTimingFile(
      'OT',
      'BSB_09_1Sa_002_timing.txt',
      '\\id 1Sa\n\\c 002\n\\level phrase\n4.0\t10.0\t09001001\n',
    );

    await expectLater(
      () => parseAndValidateAudioTimings(
        dbHelper: dbHelper,
        timingsDirPath: timingsDir.path,
        expectedFileCount: 2,
      ),
      throwsA(
        isA<AudioTimingsValidationException>().having(
          (e) => e.violations.join('\n'),
          'violations',
          allOf(
            contains('expected 9002'),
            contains('Duplicate timing reference: 9001001'),
          ),
        ),
      ),
    );
  });

  test('rule 5: rejects non-increasing verse numbers', () async {
    seedBibleVerses([(43, 10, 1), (43, 10, 2)]);
    writeTimingFile(
      'NT',
      'BSB_43_Jhn_010_timing.txt',
      '\\id Jhn\n\\c 010\n\\level phrase\n'
          '4.0\t8.0\t43010002\n'
          '8.0\t12.0\t43010001\n',
    );

    await expectLater(
      () => parseAndValidateAudioTimings(
        dbHelper: dbHelper,
        timingsDirPath: timingsDir.path,
        expectedFileCount: 1,
      ),
      throwsA(
        isA<AudioTimingsValidationException>().having(
          (e) => e.violations.join('\n'),
          'violations',
          contains('not strictly greater'),
        ),
      ),
    );
  });

  test('rule 6: rejects negative start_ms or start_ms >= end_ms', () async {
    seedBibleVerses([(2, 16, 1), (2, 16, 2)]);
    writeTimingFile(
      'OT',
      'BSB_02_Exo_016_timing.txt',
      '\\id Exo\n\\c 016\n\\level phrase\n'
          '-1\t-1\t02016001\n'
          '5.0\t5.0\t02016002\n',
    );

    await expectLater(
      () => parseAndValidateAudioTimings(
        dbHelper: dbHelper,
        timingsDirPath: timingsDir.path,
        expectedFileCount: 1,
      ),
      throwsA(
        isA<AudioTimingsValidationException>().having(
          (e) => e.violations.join('\n'),
          'violations',
          contains('invalid timing'),
        ),
      ),
    );
  });

  test('rule 7: rejects non-contiguous boundaries (> 1 ms gap or overlap)', () async {
    seedBibleVerses([(43, 10, 1), (43, 10, 2)]);
    writeTimingFile(
      'NT',
      'BSB_43_Jhn_010_timing.txt',
      '\\id Jhn\n\\c 010\n\\level phrase\n'
          '4.0\t10.0\t43010001\n'
          '10.05\t15.0\t43010002\n',
    );

    await expectLater(
      () => parseAndValidateAudioTimings(
        dbHelper: dbHelper,
        timingsDirPath: timingsDir.path,
        expectedFileCount: 1,
      ),
      throwsA(
        isA<AudioTimingsValidationException>().having(
          (e) => e.violations.join('\n'),
          'violations',
          contains('non-contiguous boundary'),
        ),
      ),
    );
  });

  test('rule 8: reports both missing timings and timings for nonexistent verses', () async {
    seedBibleVerses([
      (40, 17, 20),
      (40, 17, 22),
    ]);
    writeTimingFile(
      'NT',
      'BSB_40_Mat_017_timing.txt',
      '\\id Mat\n\\c 017\n\\level phrase\n'
          '4.0\t10.0\t40017020\n'
          '10.0\t15.0\t40017021\n',
    );

    await expectLater(
      () => parseAndValidateAudioTimings(
        dbHelper: dbHelper,
        timingsDirPath: timingsDir.path,
        expectedFileCount: 1,
      ),
      throwsA(
        isA<AudioTimingsValidationException>().having(
          (e) => e.violations.join('\n'),
          'violations',
          allOf(
            contains('Missing timings for 1 verse(s)'),
            contains('40017022'),
            contains('nonexistent verse(s)'),
            contains('40017021'),
          ),
        ),
      ),
    );
  });

  test('rule 9: rejects unexpected file count', () async {
    seedBibleVerses([(43, 10, 1)]);
    writeTimingFile(
      'NT',
      'BSB_43_Jhn_010_timing.txt',
      '\\id Jhn\n\\c 010\n\\level phrase\n4.0\t10.0\t43010001\n',
    );

    await expectLater(
      () => parseAndValidateAudioTimings(
        dbHelper: dbHelper,
        timingsDirPath: timingsDir.path,
        expectedFileCount: 1189,
      ),
      throwsA(
        isA<AudioTimingsValidationException>().having(
          (e) => e.violations.join('\n'),
          'violations',
          contains('Expected 1189 timing files, found 1'),
        ),
      ),
    );
  });
}
