package com.agustin.track_time

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val canal = "com.agustin.track_time/cronometro"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pedirPermisoNotificaciones()
    }

    private fun pedirPermisoNotificaciones() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val concedido = ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (!concedido) {
                ActivityCompat.requestPermissions(
                    this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 100
                )
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canal)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "iniciar" -> {
                        val nombre = call.argument<String>("nombre") ?: "Sesión activa"
                        val color = call.argument<String>("color")
                        val iniciada = (call.argument<Number>("iniciada"))?.toLong()
                            ?: System.currentTimeMillis()
                        iniciarServicio(nombre, color, iniciada)
                        result.success(null)
                    }
                    "detener" -> {
                        detenerServicio()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun iniciarServicio(nombre: String, color: String?, iniciada: Long) {
        val intent = Intent(this, CronometroService::class.java).apply {
            action = CronometroService.ACCION_INICIAR
            putExtra(CronometroService.EXTRA_NOMBRE, nombre)
            putExtra(CronometroService.EXTRA_COLOR, color)
            putExtra(CronometroService.EXTRA_INICIADA, iniciada)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun detenerServicio() {
        val intent = Intent(this, CronometroService::class.java).apply {
            action = CronometroService.ACCION_DETENER
        }
        startService(intent)
    }
}
