package com.tretech.tretech_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val SCANNER_CHANNEL = "com.tretech/scanner"
    private var scanReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    scanReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            val action = intent?.action
                            if (action == "com.imin.scanner.api.RESULT_ACTION") {
                                val barcode = intent.getStringExtra("decode_data_str")
                                if (barcode != null) {
                                    events?.success(barcode)
                                }
                            }
                        }
                    }
                    val filter = IntentFilter()
                    filter.addAction("com.imin.scanner.api.RESULT_ACTION")
                    
                    try {
                        // For Android 14+ compatibility
                        registerReceiver(scanReceiver, filter, Context.RECEIVER_EXPORTED)
                    } catch (e: Exception) {
                        try {
                            registerReceiver(scanReceiver, filter)
                        } catch (e2: Exception) {}
                    }
                }

                override fun onCancel(arguments: Any?) {
                    if (scanReceiver != null) {
                        try {
                            unregisterReceiver(scanReceiver)
                        } catch (e: Exception) {}
                        scanReceiver = null
                    }
                }
            }
        )
    }
}
