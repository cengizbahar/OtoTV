package com.ototvplus.app

import android.content.res.Configuration
import android.os.Build
import android.view.Display
import androidx.car.app.connection.CarConnection
import androidx.lifecycle.Observer
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

// audio_service'in paylaşılan FlutterEngine'ine bağlanır; ekran kapalıyken
// ve bildirimden kontrol edilirken aynı oynatıcı çalışmaya devam eder.
// FragmentActivity: Google Play Faturalandırma (RevenueCat) akışı için gerekli.
class MainActivity : AudioServiceFragmentActivity() {

    private var carSink: EventChannel.EventSink? = null
    private var connectionType = CarConnection.CONNECTION_TYPE_NOT_CONNECTED
    private val connectionObserver = Observer<Int> { type ->
        connectionType = type
        emitCarState()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Araç durumu → Dart (lib/platform/car_connection.dart):
        // 0 bağlı değil · 1 Android Automotive · 2 Android Auto (uygulama telefonda)
        // 3 Android Auto ve uygulama ARAÇ EKRANINDA çalışıyor (park uygulaması).
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "ototv/car_connection")
            .setStreamHandler(object : EventChannel.StreamHandler {
                private val live = CarConnection(this@MainActivity).type

                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    carSink = events
                    live.observe(this@MainActivity, connectionObserver)
                }

                override fun onCancel(arguments: Any?) {
                    live.removeObserver(connectionObserver)
                    carSink = null
                }
            })
    }

    override fun onResume() {
        super.onResume()
        emitCarState()
    }

    // Android Auto park uygulamayı araç ekranına taşıdığında yapılandırma değişir.
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        emitCarState()
    }

    private fun emitCarState() {
        val sink = carSink ?: return
        val onCarDisplay = connectionType == CarConnection.CONNECTION_TYPE_PROJECTION &&
            currentDisplayId() != Display.DEFAULT_DISPLAY
        sink.success(if (onCarDisplay) 3 else connectionType)
    }

    @Suppress("DEPRECATION")
    private fun currentDisplayId(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.displayId ?: Display.DEFAULT_DISPLAY
        } else {
            windowManager.defaultDisplay.displayId
        }
}
