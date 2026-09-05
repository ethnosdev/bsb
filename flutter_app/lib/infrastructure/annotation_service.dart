import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'annotation_database.dart';
import 'annotation_models.dart';

class AnnotationService {
  final AnnotationDatabaseHelper _dbHelper;
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  static const _uuid = Uuid();

  AnnotationService({AnnotationDatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? AnnotationDatabaseHelper();

  void _notifyChange() {
    changeNotifier.value++;
  }

  Future<List<Highlight>> getHighlights(int bookId, int chapter) {
    return _dbHelper.getHighlightsForChapter(bookId, chapter);
  }

  Future<List<Note>> getNotes(int bookId, int chapter) {
    return _dbHelper.getNotesForChapter(bookId, chapter);
  }

  Future<Note?> getNoteById(String id) {
    return _dbHelper.getNoteById(id);
  }

  /// Adds a highlight and normalizes overlapping ranges (merging same colors,
  /// splitting/trimming overridden colors).
  Future<void> addHighlight({
    required int bookId,
    required int chapter,
    required int startWordId,
    required int endWordId,
    required HighlightColor color,
  }) async {
    final now = DateTime.now();
    int currentStart = startWordId;
    int currentEnd = endWordId;

    final existing = await _dbHelper.getHighlightsForChapter(bookId, chapter);
    final overlapping = existing.where((h) =>
        h.startWordId <= currentEnd && h.endWordId >= currentStart).toList();

    for (final h in overlapping) {
      if (h.color == color) {
        // Same color: merge
        currentStart = min(currentStart, h.startWordId);
        currentEnd = max(currentEnd, h.endWordId);
        await _dbHelper.deleteHighlight(h.id);
      } else {
        // Different color: override
        if (currentStart <= h.startWordId && currentEnd >= h.endWordId) {
          // New highlight completely covers old highlight
          await _dbHelper.deleteHighlight(h.id);
        } else if (h.startWordId < currentStart && h.endWordId > currentEnd) {
          // New highlight is inside old highlight: split into two
          await _dbHelper.updateHighlight(
            h.copyWith(
              endWordId: currentStart - 1,
              updatedAt: now,
            ),
          );
          await _dbHelper.insertHighlight(
            Highlight(
              id: _uuid.v4(),
              bookId: bookId,
              chapter: chapter,
              startWordId: currentEnd + 1,
              endWordId: h.endWordId,
              color: h.color,
              createdAt: now,
              updatedAt: now,
            ),
          );
        } else if (h.startWordId < currentStart && h.endWordId <= currentEnd) {
          // Overlaps the right tail of old highlight
          await _dbHelper.updateHighlight(
            h.copyWith(
              endWordId: currentStart - 1,
              updatedAt: now,
            ),
          );
        } else if (h.startWordId >= currentStart && h.endWordId > currentEnd) {
          // Overlaps the left head of old highlight
          await _dbHelper.updateHighlight(
            h.copyWith(
              startWordId: currentEnd + 1,
              updatedAt: now,
            ),
          );
        }
      }
    }

    // Insert the final merged/overriding highlight
    await _dbHelper.insertHighlight(
      Highlight(
        id: _uuid.v4(),
        bookId: bookId,
        chapter: chapter,
        startWordId: currentStart,
        endWordId: currentEnd,
        color: color,
        createdAt: now,
        updatedAt: now,
      ),
    );

    _notifyChange();
  }

  /// Removes any highlights in the given range.
  Future<void> clearHighlightsInRange({
    required int bookId,
    required int chapter,
    required int startWordId,
    required int endWordId,
  }) async {
    final now = DateTime.now();
    final existing = await _dbHelper.getHighlightsForChapter(bookId, chapter);
    final overlapping = existing.where((h) =>
        h.startWordId <= endWordId && h.endWordId >= startWordId).toList();

    for (final h in overlapping) {
      if (startWordId <= h.startWordId && endWordId >= h.endWordId) {
        // Completely covered: delete
        await _dbHelper.deleteHighlight(h.id);
      } else if (h.startWordId < startWordId && h.endWordId > endWordId) {
        // Split into two
        await _dbHelper.updateHighlight(
          h.copyWith(
            endWordId: startWordId - 1,
            updatedAt: now,
          ),
        );
        await _dbHelper.insertHighlight(
          Highlight(
            id: _uuid.v4(),
            bookId: bookId,
            chapter: chapter,
            startWordId: endWordId + 1,
            endWordId: h.endWordId,
            color: h.color,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else if (h.startWordId < startWordId && h.endWordId <= endWordId) {
        await _dbHelper.updateHighlight(
          h.copyWith(
            endWordId: startWordId - 1,
            updatedAt: now,
          ),
        );
      } else if (h.startWordId >= startWordId && h.endWordId > endWordId) {
        await _dbHelper.updateHighlight(
          h.copyWith(
            startWordId: endWordId + 1,
            updatedAt: now,
          ),
        );
      }
    }

    _notifyChange();
  }

  /// Saves a note (creates or updates). If content is empty and note existed, deletes it.
  Future<void> saveNote({
    required int bookId,
    required int chapter,
    required int startWordId,
    required int endWordId,
    required String content,
    String? existingNoteId,
  }) async {
    final trimmed = content.trim();
    final now = DateTime.now();

    if (trimmed.isEmpty) {
      if (existingNoteId != null) {
        await _dbHelper.deleteNote(existingNoteId);
        _notifyChange();
      }
      return;
    }

    if (existingNoteId != null) {
      final existing = await _dbHelper.getNoteById(existingNoteId);
      if (existing != null) {
        await _dbHelper.updateNote(
          existing.copyWith(
            content: trimmed,
            updatedAt: now,
          ),
        );
        _notifyChange();
        return;
      }
    }

    // New note
    await _dbHelper.insertNote(
      Note(
        id: _uuid.v4(),
        bookId: bookId,
        chapter: chapter,
        startWordId: startWordId,
        endWordId: endWordId,
        content: trimmed,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _notifyChange();
  }

  Future<void> deleteNote(String id) async {
    await _dbHelper.deleteNote(id);
    _notifyChange();
  }
}
