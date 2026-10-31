import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

/// Prints and lets go, so every phone at the counter can share one printer.
///
/// A Bluetooth Classic printer takes one RFCOMM connection at a time; a phone
/// that keeps its connection open locks every other phone out until it quits.
/// "Many phones on one printer" is really the phones taking turns, which is
/// what this does: connect, write, wait for the job to leave the radio, and
/// disconnect. A phone that finds the printer busy with another one keeps
/// trying for [_busyWait] instead of failing on the first refusal.
///
/// Jobs from this phone run one after another, and a second print inside the
/// linger window reuses the open connection rather than reconnecting.
///
/// The connection itself is the app's own `bizpos/printer` channel
/// (`ThermalPrinter.kt`), not the plugin's: the plugin only opens a secure
/// socket, which a printer refuses once it has forgotten this phone's pairing
/// key — and cheap printers remember about two. The channel falls back to an
/// insecure socket, so any number of phones can take turns. The plugin still
/// does the permission prompt and the paired list.
class BluetoothThermalTransport implements PrinterTransport {
  static const _channel = MethodChannel('bizpos/printer');

  /// How long to keep knocking while another phone has the printer. Each
  /// phone's job plus its linger is a few seconds; with several phones at one
  /// counter this phone may be a few turns back in the line.
  static const _busyWait = Duration(seconds: 45);

  String? _connectedTo;
  Timer? _release;
  Future<void> _queue = Future.value();

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
  Future<void> send(String mac, List<int> bytes) => _serial(() async {
    _release?.cancel();
    _release = null;
    try {
      // A connection still open from a print a moment ago is reused; if the
      // printer dropped it meanwhile the first write fails at once, before
      // anything is printed, and one fresh connection is worth a try.
      if (_connectedTo == mac && await _write(bytes)) {
        return _scheduleRelease(bytes.length);
      }
      await _disconnect();
      await _connect(mac);
      if (!await _write(bytes)) throw const PrintFailed();
      _scheduleRelease(bytes.length);
    } catch (_) {
      await _disconnect();
      rethrow;
    }
  });

  /// Keeps knocking while the printer is serving another phone. A refused
  /// RFCOMM connect is also what a cheap printer answers straight after
  /// waking up, so even a free printer sometimes needs the second try.
  Future<void> _connect(String mac) async {
    final deadline = DateTime.now().add(_busyWait);
    var pause = const Duration(milliseconds: 500);
    while (true) {
      if (await _channel.invokeMethod<bool>('connect', {'mac': mac}) ?? false) {
        _connectedTo = mac;
        return;
      }
      if (DateTime.now().add(pause).isAfter(deadline)) {
        throw const PrintFailed();
      }
      developer.log('printer busy or asleep, retrying', name: 'printing');
      await Future<void>.delayed(pause);
      if (pause < const Duration(seconds: 2)) pause *= 2;
    }
  }

  /// The whole job in one call, as a byte[]; the native side writes it in
  /// pieces and flushes each one.
  Future<bool> _write(List<int> bytes) async {
    final sent = await _channel.invokeMethod<bool>('write', {
      'bytes': Uint8List.fromList(bytes),
    });
    if (sent ?? false) return true;
    _connectedTo = null;
    return false;
  }

  /// The write returns once Android has the bytes, not once the printer does:
  /// the tail of the job is still in the Bluetooth stack's buffer, and
  /// closing the socket now would cut the receipt short. So the connection
  /// is held a little longer, more for a long receipt, then given up for the
  /// next phone.
  void _scheduleRelease(int length) {
    final ms = (1500 + length ~/ 40).clamp(1500, 6000);
    _release = Timer(Duration(milliseconds: ms), () => _serial(_disconnect));
  }

  Future<void> _disconnect() async {
    _release?.cancel();
    _release = null;
    _connectedTo = null;
    try {
      await _channel.invokeMethod<bool>('disconnect');
    } catch (e) {
      developer.log('could not let go of the printer: $e', name: 'printing');
    }
  }

  Future<void> _serial(Future<void> Function() job) {
    final run = _queue.then((_) => job());
    _queue = run.catchError((_) {});
    return run;
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
