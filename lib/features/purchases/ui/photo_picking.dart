import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/purchases_repository.dart';

/// 8 MB a photo is the server's limit. Photos are scaled down on the way in,
/// so a phone camera's picture fits with room to spare.
const _maxBytes = 8 * 1024 * 1024;

/// Asks camera or gallery, then returns up to [limit] photos as bytes.
///
/// A refused camera permission is not a dead end: the gallery is the other
/// button, and a WhatsApp forward — the usual shape of a supplier's bill —
/// lives there anyway.
Future<List<PhotoFile>> pickBillPhotos(
  BuildContext context, {
  required int limit,
}) async {
  final l10n = AppL10n.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.chooseFromGallery),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return const [];

  final picker = ImagePicker();
  final List<XFile> picked;
  try {
    if (source == ImageSource.camera) {
      final one = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        imageQuality: 85,
      );
      picked = one == null ? const [] : [one];
    } else {
      picked = await picker.pickMultiImage(
        maxWidth: 2400,
        imageQuality: 85,
        limit: limit > 1 ? limit : null,
      );
    }
  } catch (e) {
    if (context.mounted) showNote(context, l10n.photoPickFailed);
    return const [];
  }

  final files = <PhotoFile>[];
  var tooBig = 0;
  for (final file in picked.take(limit)) {
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      tooBig++;
      continue;
    }
    files.add(PhotoFile(name: file.name, bytes: bytes));
  }
  if (tooBig > 0 && context.mounted) {
    showNote(context, l10n.photosTooBig(tooBig));
  }
  return files;
}

/// A square thumbnail of a bill photo — from the server, or picked and not yet
/// uploaded.
class BillPhotoThumb extends StatelessWidget {
  const BillPhotoThumb({
    this.url,
    this.bytes,
    this.onOpen,
    this.onRemove,
    super.key,
  });

  final String? url;
  final Uint8List? bytes;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover)
        : Image.network(
            url ?? '',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Icon(Icons.broken_image_outlined, color: palette.muted),
          );

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.row),
            child: Material(
              color: palette.surfaceAlt,
              child: InkWell(onTap: onOpen, child: image),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: palette.surface.withValues(alpha: 0.85),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.s4),
                    child: Icon(Icons.close, size: 16, color: palette.danger),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The photo, full screen, for reading the supplier's handwriting.
Future<void> showBillPhoto(BuildContext context, String url) => showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
