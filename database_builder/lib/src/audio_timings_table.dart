import 'dart:io';

import 'package:path/path.dart' as p;

import 'book_id.dart';
import 'database_helper.dart';
import 'schema.dart';

class AudioTimingRecord {
  final int reference;
  final int startMs;
  final int endMs;

  const AudioTimingRecord({
    required this.reference,
    required this.startMs,
    required this.endMs,
  });
}

class AudioTimingsValidationException implements Exception {
  final List<String> violations;

  const AudioTimingsValidationException(this.violations);

  @override
  String toString() {
    final preview = violations.take(25).join('\n  - ');
    final extra = violations.length > 25
        ? '\n  ...and ${violations.length - 25} more violation(s)'
        : '';
    return 'Audio timings validation failed (${violations.length} violation(s)):\n  - $preview$extra';
  }
}

final RegExp _timingFilenameRegex = RegExp(
  r'^BSB_(\d{2})_(\w{3})_(\d{3})_timing\.txt$',
);

/// Reads, strictly validates, and inserts all Souer verse timings into `audio_timings`.
Future<void> createAudioTimingsTable(
  DatabaseHelper dbHelper, {
  String timingsDirPath = 'audio_timings/souer',
  int expectedFileCount = 1189,
}) async {
  final records = await parseAndValidateAudioTimings(
    dbHelper: dbHelper,
    timingsDirPath: timingsDirPath,
    expectedFileCount: expectedFileCount,
  );

  dbHelper.beginTransaction();
  try {
    for (final record in records) {
      dbHelper.insertAudioTiming(
        reference: record.reference,
        startMs: record.startMs,
        endMs: record.endMs,
      );
    }
    dbHelper.commitTransaction();
  } catch (e) {
    dbHelper.database.execute('ROLLBACK;');
    rethrow;
  }
}

/// Parses and validates all timing files under [timingsDirPath] against the
/// `bible` table in [dbHelper]. Collects all violations and throws
/// [AudioTimingsValidationException] if any check fails.
Future<List<AudioTimingRecord>> parseAndValidateAudioTimings({
  required DatabaseHelper dbHelper,
  required String timingsDirPath,
  int expectedFileCount = 1189,
}) async {
  final rootDir = Directory(timingsDirPath);
  if (!await rootDir.exists()) {
    throw AudioTimingsValidationException([
      'Audio timings directory does not exist: $timingsDirPath',
    ]);
  }

  final files = <File>[];
  for (final entity in rootDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final name = p.basename(entity.path);
    if (name.startsWith('.')) continue; // Ignore .DS_Store, etc.
    files.add(entity);
  }
  files.sort((a, b) => a.path.compareTo(b.path));

  final violations = <String>[];

  // Rule 9: exact file count check.
  if (files.length != expectedFileCount) {
    violations.add(
      'Expected $expectedFileCount timing files, found ${files.length}',
    );
  }

  final records = <AudioTimingRecord>[];
  final seenReferences = <int>{};
  final duplicateReferences = <int>{};

  for (final file in files) {
    final filename = p.basename(file.path);
    // Rule 1: strict filename convention.
    final match = _timingFilenameRegex.firstMatch(filename);
    if (match == null) {
      violations.add('Invalid timing filename: $filename');
      continue;
    }

    final fileBook = int.parse(match.group(1)!);
    final fileAbbr = match.group(2)!;
    final fileChapter = int.parse(match.group(3)!);

    final expectedAbbr = bookIdToAbbreviationMap[fileBook];
    final validAbbr =
        expectedAbbr != null &&
        (expectedAbbr == fileAbbr.toUpperCase() ||
            (fileBook == 56 && fileAbbr.toUpperCase() == 'TTS'));
    if (!validAbbr) {
      violations.add(
        '$filename: filename book $fileBook does not match abbreviation "$fileAbbr"',
      );
    }

    final rawLines = await file.readAsLines();
    String? headerId;
    int? headerChapter;
    final dataLines = <(int lineNum, String line)>[];

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      if (line.isEmpty) continue;
      if (line.startsWith(r'\id ')) {
        headerId = line.substring(4).trim();
      } else if (line.startsWith(r'\c ')) {
        final rawChapter = line.substring(3).trim();
        headerChapter = int.tryParse(rawChapter);
        if (headerChapter == null) {
          violations.add('$filename:${i + 1}: non-numeric \\c header "$rawChapter"');
        }
      } else if (line.startsWith(r'\level ')) {
        // Expected header line (e.g. \level phrase)
      } else if (line.startsWith(r'\')) {
        violations.add('$filename:${i + 1}: unexpected header line "$line"');
      } else {
        dataLines.add((i + 1, line));
      }
    }

    // Rule 2: header \id and \c match filename.
    if (headerId == null || headerId.toLowerCase() != fileAbbr.toLowerCase()) {
      violations.add(
        '$filename: \\id "${headerId ?? '(missing)'}" != filename abbreviation "$fileAbbr"',
      );
    }
    if (headerChapter == null || headerChapter != fileChapter) {
      violations.add(
        '$filename: \\c "${headerChapter ?? '(missing)'}" != filename chapter $fileChapter',
      );
    }

    final expectedBookChapter = fileBook * 1000 + fileChapter;
    int prevVerse = 0;
    int? prevEndMs;

    for (final (lineNum, line) in dataLines) {
      final parts = line.split('\t');
      if (parts.length != 3) {
        violations.add('$filename:$lineNum: expected 3 tab-separated columns, got ${parts.length}');
        continue;
      }

      final startSec = double.tryParse(parts[0].trim());
      final endSec = double.tryParse(parts[1].trim());
      final ref = int.tryParse(parts[2].trim());
      if (startSec == null || endSec == null || ref == null) {
        violations.add('$filename:$lineNum: unparseable row "$line"');
        continue;
      }

      final startMs = (startSec * 1000).round();
      final endMs = (endSec * 1000).round();

      // Rule 3: row ID book/chapter matches file book/chapter.
      if (ref ~/ 1000 != expectedBookChapter) {
        violations.add(
          '$filename:$lineNum: reference $ref has book/chapter ${ref ~/ 1000}, expected $expectedBookChapter',
        );
      }

      // Rule 4: global uniqueness.
      if (!seenReferences.add(ref)) {
        duplicateReferences.add(ref);
      }

      // Rule 5: strictly increasing verse numbers within the chapter.
      final verse = ref % 1000;
      if (verse <= prevVerse) {
        violations.add(
          '$filename:$lineNum: verse $verse is not strictly greater than previous verse $prevVerse',
        );
      }
      prevVerse = verse;

      // Rule 6: valid positive-duration timings.
      if (startMs < 0 || startMs >= endMs) {
        violations.add(
          '$filename:$lineNum: invalid timing [$startMs, $endMs) for reference $ref',
        );
      }

      // Rule 7: contiguous within 1 ms rounding tolerance.
      if (prevEndMs != null && (prevEndMs - startMs).abs() > 1) {
        violations.add(
          '$filename:$lineNum: non-contiguous boundary $prevEndMs -> $startMs at reference $ref',
        );
      }
      prevEndMs = endMs;

      records.add(
        AudioTimingRecord(reference: ref, startMs: startMs, endMs: endMs),
      );
    }
  }

  for (final dup in duplicateReferences.toList()..sort()) {
    violations.add('Duplicate timing reference: $dup');
  }

  // Rule 8: exact 1-to-1 coverage with distinct verse references in `bible`.
  final bibleRefs = dbHelper.database
      .select(
        'SELECT DISTINCT ${Schema.colReference} '
        'FROM ${Schema.bibleTextTable} '
        'WHERE ${Schema.colReference} % 1000 > 0;',
      )
      .map((row) => row[Schema.colReference] as int)
      .toSet();

  final missingTimings = bibleRefs.difference(seenReferences).toList()..sort();
  if (missingTimings.isNotEmpty) {
    final preview = missingTimings.take(10).join(', ');
    violations.add(
      'Missing timings for ${missingTimings.length} verse(s) in bible table (e.g. $preview)',
    );
  }

  final extraTimings = seenReferences.difference(bibleRefs).toList()..sort();
  if (extraTimings.isNotEmpty) {
    final preview = extraTimings.take(10).join(', ');
    violations.add(
      'Timings exist for ${extraTimings.length} nonexistent verse(s) (e.g. $preview)',
    );
  }

  if (violations.isNotEmpty) {
    for (final v in violations) {
      print('ERROR: $v');
    }
    throw AudioTimingsValidationException(violations);
  }

  return records;
}
