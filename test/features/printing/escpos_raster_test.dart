import 'dart:typed_data';

import 'package:bizpos_app/features/printing/escpos_raster.dart';
import 'package:flutter_test/flutter_test.dart';

/// The receipt reaches the printer as a picture; these are the bytes of it.
void main() {
  /// A white RGBA image with black dots at [ink].
  Uint8List image(int width, int height, List<(int, int)> ink) {
    final rgba = Uint8List(width * height * 4)..fillRange(0, width * height * 4, 255);
    for (final (x, y) in ink) {
      final i = (y * width + x) * 4;
      rgba[i] = rgba[i + 1] = rgba[i + 2] = 0;
    }
    return rgba;
  }

  test('one raster band, a dot where the ink is, then feed and cut', () {
    final bytes = escposRaster(
      image(16, 2, [(0, 0), (9, 1)]),
      width: 16,
      height: 2,
      dots: 16,
    );

    expect(bytes.sublist(0, 2), [0x1B, 0x40]); // reset
    // GS v 0, 2 bytes a row, 2 rows.
    expect(bytes.sublist(2, 10), [0x1D, 0x76, 0x30, 0x00, 2, 0, 2, 0]);
    expect(bytes.sublist(10, 14), [0x80, 0x00, 0x00, 0x40]);
    expect(bytes.sublist(14), [0x1B, 0x64, 4, 0x1D, 0x56, 0x42, 0x00]);
  });

  test('a capture a pixel short of the head is padded with white', () {
    // 383 px from rounding the capture, printed on a 384-dot head.
    final bytes = escposRaster(
      image(383, 1, [(382, 0)]),
      width: 383,
      height: 1,
      dots: 384,
    );

    expect(bytes.sublist(6, 8), [48, 0]); // 384 / 8 bytes a row
    final row = bytes.sublist(10, 10 + 48);
    expect(row.last, 0x02); // dot 382 is the second-last bit
  });

  test('a tall receipt is sent in bands', () {
    final bytes = escposRaster(
      image(8, 150, const []),
      width: 8,
      height: 150,
      dots: 8,
      bandRows: 64,
      cut: false,
    );
    // 64 + 64 + 22 rows: three GS v 0 headers.
    var headers = 0;
    for (var i = 0; i + 3 < bytes.length; i++) {
      if (bytes[i] == 0x1D && bytes[i + 1] == 0x76 && bytes[i + 2] == 0x30) {
        headers++;
      }
    }
    expect(headers, 3);
  });

  test('anti-aliased grey edges still burn', () {
    final rgba = image(8, 1, const []);
    rgba[0] = rgba[1] = rgba[2] = 140; // a text edge, not quite black
    final bytes = escposRaster(rgba, width: 8, height: 1, dots: 8, cut: false);
    expect(bytes[10], 0x80);
  });
}
