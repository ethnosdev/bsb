import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/playlist_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/playlists/playlist_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class FakePlaylistDbHelper implements AnnotationDatabaseHelper {
  final List<Playlist> _playlists = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Playlist>> getAllPlaylists() async => List.from(_playlists);

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    _playlists.removeWhere((p) => p.id == playlist.id);
    _playlists.add(playlist);
  }

  @override
  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
  }
}

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async => [
        UsfmLine(
          bookChapterVerse: reference.packedVerse,
          text: 'Verse text for $reference',
          format: ParagraphFormat.p,
        ),
      ];
}

void main() {
  late FakePlaylistDbHelper fakeDb;
  late PlaylistService playlistService;

  setUp(() async {
    await getIt.reset();
    fakeDb = FakePlaylistDbHelper();
    playlistService = PlaylistService(dbHelper: fakeDb);
    getIt.registerSingleton<AnnotationDatabaseHelper>(fakeDb);
    getIt.registerSingleton<PlaylistService>(playlistService);
    getIt.registerSingleton<DatabaseHelper>(FakeDatabaseHelper());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('PlaylistEditorPage displays items and allows adding notes', (tester) async {
    final playlist = Playlist(
      id: 'p1',
      title: 'Study 1',
      items: [
        PlaylistItem.reference(
          reference: Reference(bookId: 43, chapter: 3, verse: 16),
          orderIndex: 0,
        ),
      ],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistEditorPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Study 1'), findsOneWidget);
    expect(find.text('John 3:16'), findsOneWidget);

    // Tap Add Note button
    await tester.tap(find.text('Add Note'));
    await tester.pumpAndSettle();

    expect(find.text('Add Note'), findsWidgets);

    // Verify text fields in dialog do not have hint text
    final dialogTextFields = tester.widgetList<TextField>(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)),
    ).toList();
    expect(dialogTextFields.length, 2);
    expect(dialogTextFields[0].decoration?.hintText, isNull);
    expect(dialogTextFields[1].decoration?.hintText, isNull);

    // Verify Save button is initially disabled when note is blank
    final saveButtonFinder = find.widgetWithText(FilledButton, 'Save');
    var saveBtn = tester.widget<FilledButton>(saveButtonFinder);
    expect(saveBtn.onPressed, isNull);

    // Enter whitespace only -> still disabled
    await tester.enterText(find.byType(TextField).last, '   ');
    await tester.pumpAndSettle();
    saveBtn = tester.widget<FilledButton>(saveButtonFinder);
    expect(saveBtn.onPressed, isNull);

    // Enter note text -> enabled
    await tester.enterText(find.byType(TextField).last, 'Discuss God\'s love');
    await tester.pumpAndSettle();
    saveBtn = tester.widget<FilledButton>(saveButtonFinder);
    expect(saveBtn.onPressed, isNotNull);

    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Discuss God\'s love'), findsOneWidget);

    // Verify it was saved
    final saved = await playlistService.getPlaylist('p1');
    expect(saved, isNotNull);
    expect(saved!.items.length, 2);
    expect(saved.items.last.noteText, 'Discuss God\'s love');
  });

  testWidgets('PlaylistEditorPage displays items without edit icons and allows tapping cards to edit', (tester) async {
    final playlist = Playlist(
      id: 'p2',
      title: 'Study 2',
      items: [
        PlaylistItem.reference(
          id: 'ref1',
          reference: Reference(bookId: 43, chapter: 3, verse: 16),
          orderIndex: 0,
        ),
        PlaylistItem.note(
          id: 'note1',
          title: 'Opening Question',
          text: 'What does this mean to you?',
          orderIndex: 1,
        ),
        PlaylistItem.note(
          id: 'note2',
          title: null, // Untitled note
          text: 'Closing thoughts',
          orderIndex: 2,
        ),
      ],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistEditorPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    // Verify titled note shows custom title
    expect(find.text('Opening Question'), findsOneWidget);
    // Verify untitled note shows 'Note'
    expect(find.text('Note'), findsOneWidget);

    // Verify no edit, delete, or drag handle icons in the list (tapping the card edits)
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNothing);

    // Verify items are wrapped in ReorderableDelayedDragStartListener for long-press reorder
    expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(3));
  });

  testWidgets('PlaylistEditorPage allows deleting a note from inside the note editor dialog', (tester) async {
    final playlist = Playlist(
      id: 'p3',
      title: 'Study 3',
      items: [
        PlaylistItem.note(
          id: 'note_del',
          title: 'To Be Deleted',
          text: 'Some content',
          orderIndex: 0,
        ),
      ],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistEditorPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('To Be Deleted'), findsOneWidget);

    // Tap on the note card to edit
    await tester.tap(find.text('To Be Deleted'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Delete button in the dialog
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Delete Note'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this note from the playlist?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
    await tester.pumpAndSettle();

    // Note should now be removed
    expect(find.text('To Be Deleted'), findsNothing);
    expect(find.text('No items in this playlist yet'), findsOneWidget);

    final saved = await playlistService.getPlaylist('p3');
    expect(saved!.items, isEmpty);
  });

  testWidgets('PlaylistEditorPage allows deleting a passage from inside the passage picker dialog', (tester) async {
    final playlist = Playlist(
      id: 'p4',
      title: 'Study 4',
      items: [
        PlaylistItem.reference(
          id: 'ref_del',
          reference: Reference(bookId: 43, chapter: 3, verse: 16),
          orderIndex: 0,
        ),
      ],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistEditorPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('John 3:16'), findsOneWidget);

    // Tap on the passage card to edit
    await tester.tap(find.text('John 3:16'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Scripture Passage'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    // Tap Delete icon button in header
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Confirm deletion
    expect(find.text('Delete Passage'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // Passage should now be removed
    expect(find.text('John 3:16'), findsNothing);
    expect(find.text('No items in this playlist yet'), findsOneWidget);

    final saved = await playlistService.getPlaylist('p4');
    expect(saved!.items, isEmpty);
  });

  testWidgets('PlaylistEditorPage shows Trimmed badge for trimmed passage and provides Trim button', (tester) async {
    final playlist = Playlist(
      id: 'p5',
      title: 'Trimmed Study',
      items: [
        PlaylistItem.reference(
          id: 'ref_trimmed',
          reference: Reference(bookId: 43, chapter: 3, verse: 16),
          startWordId: 43003016002,
          endWordId: 43003016005,
          orderIndex: 0,
        ),
      ],
    );
    await playlistService.savePlaylist(playlist);

    await tester.pumpWidget(
      MaterialApp(
        home: PlaylistEditorPage(playlist: playlist),
      ),
    );
    await tester.pumpAndSettle();

    // The item tile displays John 3:16 and the 'Trimmed' badge
    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.text('Trimmed'), findsOneWidget);

    // Tap passage to open Edit Scripture Passage dialog
    await tester.tap(find.text('John 3:16'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Scripture Passage'), findsOneWidget);
    expect(find.byKey(const ValueKey('passage_trim_button')), findsOneWidget);
    // Both the playlist list tile and the dialog preview header show the Trimmed badge
    expect(find.text('Trimmed'), findsNWidgets(2));
  });
}
