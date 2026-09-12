import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/extrabiblical_texts.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/source_texts.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class ChapterManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final _annotationService = getIt<AnnotationService>();
  final textParagraphNotifier = ValueNotifier<List<UsfmLine>>([]);
  final highlightsNotifier = ValueNotifier<List<Highlight>>([]);
  final noteMarkersNotifier = ValueNotifier<List<NoteMarker>>([]);
  int _currentBookId = 0;
  int _currentChapter = 0;

  ChapterManager() {
    _annotationService.changeNotifier.addListener(_onAnnotationsChanged);
  }

  void dispose() {
    _annotationService.changeNotifier.removeListener(_onAnnotationsChanged);
    textParagraphNotifier.dispose();
    highlightsNotifier.dispose();
    noteMarkersNotifier.dispose();
  }

  void _onAnnotationsChanged() {
    if (_currentBookId != 0 && _currentChapter != 0) {
      _loadAnnotations(_currentBookId, _currentChapter);
    }
  }

  Future<void> _loadAnnotations(int bookId, int chapter) async {
    final highlights = await _annotationService.getHighlights(bookId, chapter);
    highlightsNotifier.value = highlights;

    final notes = await _annotationService.getNotes(bookId, chapter);
    noteMarkersNotifier.value = notes.map((n) => n.toNoteMarker()).toList();
  }

  double get textSize => getIt.isRegistered<AppState>()
      ? getIt<AppState>().textSizeNotifier.value
      : getIt<UserSettings>().textSize;

  Future<void> requestText({
    required int bookId,
    required int chapter,
  }) async {
    _currentBookId = bookId;
    _currentChapter = chapter;
    textParagraphNotifier.value = await _dbHelper.getChapter(bookId, chapter);
    await _loadAnnotations(bookId, chapter);
  }

  Future<Note?> getNoteById(String id) {
    return _annotationService.getNoteById(id);
  }

  Future<void> saveNote({
    required int bookId,
    required int chapter,
    required int startWordId,
    required int endWordId,
    required String content,
    String? passageText,
    String? existingNoteId,
  }) {
    return _annotationService.saveNote(
      bookId: bookId,
      chapter: chapter,
      startWordId: startWordId,
      endWordId: endWordId,
      content: content,
      passageText: passageText,
      existingNoteId: existingNoteId,
    );
  }

  Future<void> deleteNote(String id) {
    return _annotationService.deleteNote(id);
  }

  Future<String> verseTextForClipboard(
    int bookId,
    int chapter,
    int verseNumber,
  ) async {
    final reference = Reference(
      bookId: bookId,
      chapter: chapter,
      verse: verseNumber,
    );
    final verse = await _dbHelper.getRange(reference);
    final verseString = StringBuffer();
    for (final line in verse) {
      if (line.text == '\n') continue;
      verseString.write(line.text);
      verseString.write(' ');
    }
    verseString.write('($reference)');
    return verseString.toString();
  }

  RegExp footnoteKeywords() {
    const scriptureRef =
        r'(?:\d+:\d+(?:[–\-—]\d+)?|\d+(?:[–\-—]\d+)?\b(?!:))';
    final sortedBookNames = List<String>.from(validBookNames)
      ..sort((a, b) => b.length.compareTo(a.length));
    final patterns = [
      ...sortedBookNames.map((kw) => '\\b$kw $scriptureRef'),
      ...sourceTexts.keys.map((kw) => '\\b$kw\\b'),
      ...validExtraBiblicalTexts.keys,
    ].join('|');
    return RegExp('($patterns)');
  }

  // Returns the title and text body for a given tapped keyword.
  // If a cross reference, then show the source text.
  // If a source text abbreviation, then show the full name.
  // If extrabiblical text, then show the source text.
  Future<List<UsfmLine>?> lookupFootnoteDetails(String keyword) async {
    final reference = Reference.tryParse(keyword);
    if (reference != null) {
      return await _dbHelper.getRange(reference);
    }

    if (sourceTexts.containsKey(keyword)) {
      final source = sourceTexts[keyword]!;
      final withNewLine = source.replaceAll('; ', '\n');
      return [
        UsfmLine(
            bookChapterVerse: 0, text: withNewLine, format: ParagraphFormat.m)
      ];
    }

    return _extrabiblicalContent(keyword);
  }

  List<UsfmLine>? _extrabiblicalContent(String keyword) {
    String? content;
    switch (keyword) {
      case 'Jasher 79:27':
        content = jasher7927;
      case 'Jasher 88:63':
        content = jasher8863;
      case 'Jasher 88:64':
        content = jasher8864;
      case '1 Esdras 8:32':
        content = esdras832;
      case '1 Esdras 8:36':
        content = esdras836;
      case '1 Enoch 1:9':
        content = enoch1;
      case '1 Enoch 13:1–11':
        content = enoch13;
      case '1 Enoch 20:1–4':
        content = enoch20;
      default:
        content = null;
    }
    if (content == null) return null;
    return [
      UsfmLine(bookChapterVerse: 0, text: content, format: ParagraphFormat.m)
    ];
  }
}
