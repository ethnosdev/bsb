import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/playlists/widgets/playlist_qr_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PlaylistQrDialog renders without LayoutBuilder intrinsic error and without overflow', (tester) async {
    final playlist = Playlist(
      id: 'p1',
      title: 'Romans Road Study',
      items: [
        PlaylistItem.reference(
          reference: Reference(bookId: 45, chapter: 3, verse: 23),
          orderIndex: 0,
        ),
        PlaylistItem.note(
          text: 'Key reflection verse',
          orderIndex: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PlaylistQrDialog.show(context, playlist),
              child: const Text('Open QR'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open QR dialog
    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();

    expect(find.text('Romans Road Study'), findsOneWidget);
    expect(find.text('1 passage, 1 note'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Copy Link'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Tap Close
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Romans Road Study'), findsNothing);
  });

  testWidgets('PlaylistQrDialog shows friendly fallback UI when playlist data exceeds QR capacity', (tester) async {
    // Generate an oversized playlist whose compressed representation exceeds QR capacity (~3KB)
    final oversizedPlaylist = Playlist(
      id: 'p_large',
      title: 'Extensive Sermon Notes',
      items: [
        PlaylistItem.reference(
          reference: Reference(bookId: 19, chapter: 119, verse: 105),
          orderIndex: 0,
        ),
        PlaylistItem.note(
          title: 'Deep Commentary Part 1',
          text: List.generate(400, (i) => 'Sermon reflection point number $i discussing theological contexts and cross references').join('\n'),
          orderIndex: 1,
        ),
        PlaylistItem.note(
          title: 'Deep Commentary Part 2',
          text: List.generate(400, (i) => 'Application section step $i for daily devotional prayer and scripture meditation').join('\n'),
          orderIndex: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PlaylistQrDialog.show(context, oversizedPlaylist),
              child: const Text('Open QR'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open QR dialog with oversized data
    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();

    // Should display graceful fallback instead of throwing InputTooLongException
    expect(find.text('Extensive Sermon Notes'), findsOneWidget);
    expect(find.text('Too large for a QR code'), findsOneWidget);
    expect(
      find.text('This playlist contains too much content to fit into a single QR code. You can still share it using a link or file:'),
      findsOneWidget,
    );
    expect(find.text('Copy Share Link'), findsOneWidget);
    expect(find.text('Export File'), findsOneWidget);
    expect(find.text('1 passage, 2 notes'), findsOneWidget);

    // Tap Close
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Extensive Sermon Notes'), findsNothing);
  });
}
