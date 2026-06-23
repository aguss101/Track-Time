package com.agustin.track_time

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.IBinder

class CronometroService : Service() {

    companion object {
        const val ACCION_INICIAR = "com.agustin.track_time.INICIAR"
        const val ACCION_DETENER = "com.agustin.track_time.DETENER"
        const val EXTRA_NOMBRE = "nombre"
        const val EXTRA_COLOR = "color"
        const val EXTRA_INICIADA = "iniciada"

        private const val CANAL_ID = "cronometro_track_time"
        private const val NOTIF_ID = 1
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACCION_DETENER -> {
                detener()
                return START_NOT_STICKY
            }
            else -> {
                val nombre = intent?.getStringExtra(EXTRA_NOMBRE) ?: "Sesión activa"
                val colorHex = intent?.getStringExtra(EXTRA_COLOR)
                val iniciada = intent?.getLongExtra(EXTRA_INICIADA, System.currentTimeMillis())
                    ?: System.currentTimeMillis()
                iniciarForeground(nombre, colorHex, iniciada)
            }
        }
        return START_STICKY
    }

    private fun iniciarForeground(nombre: String, colorHex: String?, iniciada: Long) {
        crearCanal()

        val tocar = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val pending = PendingIntent.getActivity(
            this, 0, tocar,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = Notification.Builder(this, CANAL_ID)
            .setContentTitle(nombre)
            .setContentText("Cronómetro en curso")
            .setSmallIcon(R.drawable.ic_cronometro)
            .setOngoing(true)
            .setUsesChronometer(true)
            .setWhen(iniciada)
            .setContentIntent(pending)

        parsearColor(colorHex)?.let { builder.setColor(it) }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIF_ID,
                builder.build(),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIF_ID, builder.build())
        }
    }

    private fun detener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun crearCanal() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = NotificationChannel(
                CANAL_ID,
                "Cronómetro",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Sesión de tiempo en curso"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(canal)
        }
    }

    private fun parsearColor(hex: String?): Int? {
        if (hex.isNullOrBlank()) return null
        return try {
            Color.parseColor(if (hex.startsWith("#")) hex else "#$hex")
        } catch (_: IllegalArgumentException) {
            null
        }
    }
}
