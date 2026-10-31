package com.example.bizpos_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var printer: ThermalPrinter? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = ThermalPrinter(applicationContext)
        printer = handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bizpos/printer")
            .setMethodCallHandler(handler)
    }

    override fun onDestroy() {
        printer?.dispose()
        printer = null
        super.onDestroy()
    }
}
