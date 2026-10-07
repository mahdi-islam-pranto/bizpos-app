import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'escpos_raster.dart';

/// The two thermal roll widths. [dots] is the print head; [logicalWidth] is
/// what the receipt is laid out at, so a capture at `dots / logicalWidth`
/// fills the head exactly.
enum ReceiptPaper {
  mm58('58mm', dots: 384, logicalWidth: 288),
  mm80('80mm', dots: 576, logicalWidth: 400);

  const ReceiptPaper(
    this.wire, {
    required this.dots,
    required this.logicalWidth,
  });

  final String wire;
  final int dots;
  final double logicalWidth;

  double get pixelRatio => dots / logicalWidth;

  static ReceiptPaper parse(String? value) =>
      value == '80mm' ? ReceiptPaper.mm80 : ReceiptPaper.mm58;
}

/// The printer this phone prints on, and the roll in it.
///
/// Kept on the device, not on the account: the printer is the one paired with
/// this phone, and a second phone at the same counter has its own.
class PrinterSetup {
  const PrinterSetup({this.name, this.mac, this.paper = ReceiptPaper.mm58});

  final String? name;
  final String? mac;
  final ReceiptPaper paper;

  bool get hasPrinter => (mac ?? '').isNotEmpty;

  PrinterSetup withPrinter(String name, String mac) =>
      PrinterSetup(name: name, mac: mac, paper: paper);

  PrinterSetup withPaper(ReceiptPaper paper) =>
      PrinterSetup(name: name, mac: mac, paper: paper);
}

class PrinterSetupController extends AsyncNotifier<PrinterSetup> {
  static const _nameKey = 'printer.name';
  static const _macKey = 'printer.mac';
  static const _paperKey = 'printer.paper';

  @override
  Future<PrinterSetup> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PrinterSetup(
        name: prefs.getString(_nameKey),
        mac: prefs.getString(_macKey),
        paper: ReceiptPaper.parse(prefs.getString(_paperKey)),
      );
    } catch (e) {
      developer.log('could not read the printer: $e', name: 'printing');
      return const PrinterSetup();
    }
  }

  Future<void> choose(String name, String mac) async {
    final current = state.value ?? const PrinterSetup();
    state = AsyncData(current.withPrinter(name, mac));
    await _store({_nameKey: name, _macKey: mac});
  }

  Future<void> setPaper(ReceiptPaper paper) async {
    final current = state.value ?? const PrinterSetup();
    state = AsyncData(current.withPaper(paper));
    await _store({_paperKey: paper.wire});
  }

  Future<void> _store(Map<String, String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in values.entries) {
        await prefs.setString(entry.key, entry.value);
      }
    } catch (e) {
      developer.log('could not save the printer: $e', name: 'printing');
    }
  }
}

final printerSetupProvider =
    AsyncNotifierProvider<PrinterSetupController, PrinterSetup>(
      PrinterSetupController.new,
    );

/// Why the phone cannot reach a printer right now.
enum BluetoothState { ready, denied, off }

class PairedPrinter {
  const PairedPrinter({required this.name, required this.mac});

  final String name;
  final String mac;
}

class PrintFailed implements Exception {
  const PrintFailed();
}

/// Bluetooth Classic (SPP), which is what the cheap 58 mm and 80 mm receipt
/// printers speak. Behind an interface so a widget test can stand in for it.
abstract class PrinterTransport {
  Future<BluetoothState> check();
  Future<List<PairedPrinter>> paired();
  Future<void> send(String mac, List<int> bytes);
}

class BluetoothThermalTransport implements PrinterTransport {
  String? _connectedTo;

  @override
  Future<BluetoothState> check() async {
    // On Android 12+ this asks for BLUETOOTH_CONNECT / SCAN the first time.
    if (!await PrintBluetoothThermal.isPermissionBluetoothGranted) {
      return BluetoothState.denied;
    }
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      return BluetoothState.off;
    }
    return BluetoothState.ready;
  }

  @override
  Future<List<PairedPrinter>> paired() async => [
    for (final device in await PrintBluetoothThermal.pairedBluetooths)
      PairedPrinter(
        name: device.name.isEmpty ? device.macAdress : device.name,
        mac: device.macAdress,
      ),
  ];

  @override
  Future<void> send(String mac, List<int> bytes) async {
    final connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected || _connectedTo != mac) {
      if (connected) await PrintBluetoothThermal.disconnect;
      if (!await PrintBluetoothThermal.connect(macPrinterAddress: mac)) {
        _connectedTo = null;
        throw const PrintFailed();
      }
      _connectedTo = mac;
    }
    // In pieces: one huge write overruns the buffer of the cheaper printers,
    // which then drop the middle of the receipt without saying so.
    const piece = 4096;
    for (var start = 0; start < bytes.length; start += piece) {
      final end = start + piece < bytes.length ? start + piece : bytes.length;
      if (!await PrintBluetoothThermal.writeBytes(bytes.sublist(start, end))) {
        _connectedTo = null;
        throw const PrintFailed();
      }
    }
  }
}

final printerTransportProvider = Provider<PrinterTransport>(
  (ref) => BluetoothThermalTransport(),
);

/// Rendering, printing and saving a captured receipt.
class ReceiptOutput {
  const ReceiptOutput._();

  /// The receipt at the printer's own dot width, as ESC/POS bytes.
  static Future<List<int>> rasterFor(
    RenderRepaintBoundary boundary,
    ReceiptPaper paper,
  ) async {
    final image = await boundary.toImage(pixelRatio: paper.pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw const PrintFailed();
      return escposRaster(
        data.buffer.asUint8List(),
        width: image.width,
        height: image.height,
        dots: paper.dots,
      );
    } finally {
      image.dispose();
    }
  }

  /// A sharp PNG of the receipt, for the gallery.
  static Future<Uint8List> pngFor(RenderRepaintBoundary boundary) async {
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const PrintFailed();
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Into the phone's gallery, named after the invoice. Returns false when the
  /// person refused access or the save failed.
  static Future<bool> saveToGallery(Uint8List png, String invoiceNo) async {
    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) return false;
      final safe = invoiceNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      await Gal.putImageBytes(png, name: 'invoice_$safe');
      return true;
    } catch (e) {
      developer.log('could not save the receipt: $e', name: 'printing');
      return false;
    }
  }
}
