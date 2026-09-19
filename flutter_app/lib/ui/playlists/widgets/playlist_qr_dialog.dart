import 'package:bsb/infrastructure/playlist_models.dart';
import 'package:bsb/ui/playlists/playlist_share_handler.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PlaylistQrDialog extends StatelessWidget {
  final Playlist playlist;

  const PlaylistQrDialog({super.key, required this.playlist});

  static void show(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => PlaylistQrDialog(playlist: playlist),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrCode = PlaylistShareHandler.tryGenerateQrCode(playlist);
    final isTooLarge = qrCode == null;

    return AlertDialog(
      title: Text(
        playlist.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 280,
          child: isTooLarge
              ? _buildTooLargeContent(context)
              : _buildQrContent(context, qrCode),
        ),
      ),
      actions: isTooLarge
          ? [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ]
          : [
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy Link'),
                onPressed: () {
                  PlaylistShareHandler().copyShareLink(context, playlist);
                },
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
    );
  }

  Widget _buildQrContent(BuildContext context, QrCode qrCode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Scan with the camera on another device running BSB to import this playlist directly:',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              size: const Size.square(200.0),
              painter: QrPainter.withQr(
                qr: qrCode,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${playlist.passageCount} passage${playlist.passageCount == 1 ? '' : 's'}, ${playlist.noteCount} note${playlist.noteCount == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTooLargeContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.qr_code_2_rounded,
          size: 56,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          'Too large for a QR code',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This playlist contains too much content to fit into a single QR code. You can still share it using a link or file:',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copy Share Link'),
          onPressed: () {
            PlaylistShareHandler().copyShareLink(context, playlist);
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Export File'),
          onPressed: () {
            Navigator.of(context).pop();
            PlaylistShareHandler().exportPlaylistFile(context, playlist);
          },
        ),
        const SizedBox(height: 12),
        Text(
          '${playlist.passageCount} passage${playlist.passageCount == 1 ? '' : 's'}, ${playlist.noteCount} note${playlist.noteCount == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}
