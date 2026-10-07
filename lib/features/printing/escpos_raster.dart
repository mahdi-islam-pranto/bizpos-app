import 'dart:typed_data';

/// Turns a rendered receipt into the bytes a thermal printer understands.
///
/// The receipt is printed as a picture, never as text: no ESC/POS code page
/// covers Bangla, and a customer's name or a product's can be in either
/// language. One path for both keeps the English slip and the Bangla slip
/// identical in every other respect.
///
/// [rgba] is `ui.Image.toByteData(format: rawRgba)` of an image [width] ×
/// [height]. [dots] is the printer's head width — 384 for 58 mm paper, 576 for
/// 80 mm. A picture narrower than that is padded with white, a wider one is
/// cut, so a pixel or two of rounding in the capture never skews a row.
List<int> escposRaster(
  Uint8List rgba, {
  required int width,
  required int height,
  required int dots,
  int bandRows = 64,
  int feedLines = 4,
  bool cut = true,
}) {
  final bytesPerRow = (dots + 7) ~/ 8;
  final out = BytesBuilder(copy: false)
    // ESC @ — reset, so a half-finished job from before cannot bleed in.
    ..add(const [0x1B, 0x40]);

  // GS v 0 in bands rather than one command: cheap printers have small
  // buffers, and some cap the height a single raster command may carry.
  for (var top = 0; top < height; top += bandRows) {
    final rows = (height - top) < bandRows ? height - top : bandRows;
    out.add([
      0x1D, 0x76, 0x30, 0x00, //
      bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF,
      rows & 0xFF, (rows >> 8) & 0xFF,
    ]);
    final band = Uint8List(bytesPerRow * rows);
    for (var y = 0; y < rows; y++) {
      final rowStart = (top + y) * width * 4;
      for (var x = 0; x < dots && x < width; x++) {
        final i = rowStart + x * 4;
        if (_isInk(rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3])) {
          band[y * bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
        }
      }
    }
    out.add(band);
  }

  // ESC d n — feed past the tear bar; GS V 66 0 — cut, where there is a
  // cutter. A printer without one ignores it.
  out.add([0x1B, 0x64, feedLines]);
  if (cut) out.add(const [0x1D, 0x56, 0x42, 0x00]);
  return out.takeBytes();
}

/// Dark enough to burn. The threshold sits above the midpoint because text is
/// anti-aliased: its edges are grey, and dropping them makes thin strokes
/// break up on paper.
bool _isInk(int r, int g, int b, int a) {
  if (a < 128) return false;
  final luminance = (299 * r + 587 * g + 114 * b) ~/ 1000;
  return luminance < 160;
}
