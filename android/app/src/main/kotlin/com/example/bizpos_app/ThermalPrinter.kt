package com.example.bizpos_app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/**
 * The receipt printer's Bluetooth Classic (SPP) link: connect, write, let go.
 *
 * Why not print_bluetooth_thermal's own connect: it only ever opens a
 * *secure* RFCOMM socket, which needs the printer to still hold this phone's
 * pairing key. A cheap thermal printer remembers only a few of those (often
 * two), so every phone beyond them is refused and "couldn't reach" the
 * printer although it shows as paired. Here a refused secure socket falls
 * back to an insecure one, which needs no stored key — the printer then
 * serves any number of phones, one at a time. The way that worked is
 * remembered per printer so the next print goes straight to it.
 *
 * Also unlike the plugin: the whole socket is closed on disconnect, and the
 * job is written exactly as given (the plugin puts a '\n' in front of it).
 * The plugin is still used for permissions and the paired list.
 */
class ThermalPrinter(context: Context) : MethodChannel.MethodCallHandler {
    private val adapter: BluetoothAdapter? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var socket: BluetoothSocket? = null
    private val worked = mutableMapOf<String, Int>()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> {
                val mac = call.argument<String>("mac")
                if (mac.isNullOrEmpty()) return result.success(false)
                run(result) { connect(mac) }
            }
            "write" -> {
                val bytes = call.argument<ByteArray>("bytes")
                    ?: return result.success(false)
                run(result) { write(bytes) }
            }
            "disconnect" -> run(result) { close(); true }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        worker.execute { close() }
        worker.shutdown()
    }

    private fun run(result: MethodChannel.Result, job: () -> Boolean) {
        worker.execute {
            val ok = try {
                job()
            } catch (e: Exception) {
                Log.w(TAG, "printer: ${e.message}")
                false
            }
            main.post { result.success(ok) }
        }
    }

    private fun connect(mac: String): Boolean {
        close()
        val adapter = adapter ?: return false
        if (!adapter.isEnabled) return false
        val device = adapter.getRemoteDevice(mac)

        val first = worked[mac] ?: 0
        val order = listOf(first) + WAYS.indices.filter { it != first }
        for (way in order) {
            try {
                adapter.cancelDiscovery()
            } catch (_: SecurityException) {
            }
            var candidate: BluetoothSocket? = null
            try {
                candidate = WAYS[way](device)
                candidate.connect()
                socket = candidate
                worked[mac] = way
                return true
            } catch (e: IOException) {
                Log.d(TAG, "printer refused way $way: ${e.message}")
                closeQuietly(candidate)
            } catch (e: ReflectiveOperationException) {
                closeQuietly(candidate)
            }
        }
        return false
    }

    private fun write(bytes: ByteArray): Boolean {
        val out = socket?.outputStream ?: return false
        return try {
            var offset = 0
            while (offset < bytes.size) {
                val end = minOf(offset + CHUNK, bytes.size)
                out.write(bytes, offset, end - offset)
                out.flush()
                offset = end
            }
            true
        } catch (e: IOException) {
            Log.w(TAG, "printer write failed: ${e.message}")
            close()
            false
        }
    }

    private fun close() {
        closeQuietly(socket)
        socket = null
    }

    private fun closeQuietly(s: BluetoothSocket?) {
        if (s == null) return
        try {
            s.outputStream.close()
        } catch (_: Exception) {
        }
        try {
            s.inputStream.close()
        } catch (_: Exception) {
        }
        try {
            s.close()
        } catch (_: Exception) {
        }
    }

    companion object {
        private const val TAG = "bizpos.printer"
        private const val CHUNK = 4 * 1024
        private val SPP: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

        /**
         * Secure first, so a phone the printer still knows connects as it
         * always did; then insecure, for the phones it has forgotten; then the
         * same two on RFCOMM channel 1 directly, for printers whose service
         * lookup misbehaves.
         */
        private val WAYS: List<(BluetoothDevice) -> BluetoothSocket> = listOf(
            { it.createRfcommSocketToServiceRecord(SPP) },
            { it.createInsecureRfcommSocketToServiceRecord(SPP) },
            {
                it.javaClass.getMethod("createInsecureRfcommSocket", Int::class.javaPrimitiveType)
                    .invoke(it, 1) as BluetoothSocket
            },
            {
                it.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                    .invoke(it, 1) as BluetoothSocket
            },
        )
    }
}
