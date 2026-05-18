package com.example.zeni_app

import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.BatteryManager
import android.provider.AlarmClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "zeni.phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    // ── Overlay Control ───────────────────────────────
                    "startOverlay" -> {
                        val deviceId = call.argument<String>("deviceId") ?: "overlay_device"
                        if (Settings.canDrawOverlays(this)) {
                            val intent = Intent(this, OverlayService::class.java)
                            intent.putExtra("deviceId", deviceId)
                            startForegroundService(intent)
                            result.success("started")
                        } else {
                            result.success("permission_needed")
                        }
                    }

                    "stopOverlay" -> {
                        val intent = Intent(this, OverlayService::class.java)
                        stopService(intent)
                        result.success("stopped")
                    }

                    "isOverlayRunning" -> {
                        result.success(OverlayService.isRunning)
                    }

                    "checkOverlayPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }

                    "requestOverlayPermission" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success("requested")
                    }

                    // ── Open App ──────────────────────────────────────
                    "openApp" -> {
                        val packageName = call.argument<String>("package")
                        try {
                            val intent = packageManager.getLaunchIntentForPackage(packageName!!)
                            if (intent != null) {
                                startActivity(intent)
                                result.success("opened")
                            } else {
                                val storeIntent = Intent(
                                    Intent.ACTION_VIEW,
                                    Uri.parse("market://details?id=$packageName")
                                )
                                startActivity(storeIntent)
                                result.success("store")
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    // ── Open URL ──────────────────────────────────────
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        startActivity(intent)
                        result.success("opened")
                    }

                    // ── Volume ────────────────────────────────────────
                    "volume" -> {
                        val type = call.argument<String>("type")
                        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        when (type) {
                            "up" -> audio.adjustVolume(AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI)
                            "down" -> audio.adjustVolume(AudioManager.ADJUST_LOWER, AudioManager.FLAG_SHOW_UI)
                            "mute" -> audio.adjustVolume(AudioManager.ADJUST_MUTE, AudioManager.FLAG_SHOW_UI)
                            "unmute" -> audio.adjustVolume(AudioManager.ADJUST_UNMUTE, AudioManager.FLAG_SHOW_UI)
                        }
                        result.success("done")
                    }

                    // ── Flashlight ────────────────────────────────────
                    "torch" -> {
                        val state = call.argument<Boolean>("state")
                        try {
                            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                            val cameraId = cameraManager.cameraIdList[0]
                            cameraManager.setTorchMode(cameraId, state!!)
                            result.success("done")
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    // ── Battery ───────────────────────────────────────
                    "getBattery" -> {
                        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                        result.success(level)
                    }

                    // ── Brightness ────────────────────────────────────
                    "brightness" -> {
                        val type = call.argument<String>("type")
                        try {
                            if (Settings.System.canWrite(this)) {
                                val current = Settings.System.getInt(
                                    contentResolver,
                                    Settings.System.SCREEN_BRIGHTNESS, 128
                                )
                                val newVal = when (type) {
                                    "up" -> (current + 50).coerceAtMost(255)
                                    "down" -> (current - 50).coerceAtLeast(10)
                                    "max" -> 255
                                    "min" -> 10
                                    else -> current
                                }
                                Settings.System.putInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, newVal)
                                val lp = window.attributes
                                lp.screenBrightness = newVal / 255.0f
                                window.attributes = lp
                                result.success("done")
                            } else {
                                val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                                intent.data = Uri.parse("package:$packageName")
                                startActivity(intent)
                                result.success("permission_needed")
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    // ── Call ──────────────────────────────────────────
                    "call" -> {
                        val number = call.argument<String>("number")
                        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number"))
                        startActivity(intent)
                        result.success("done")
                    }

                    // ── Set Alarm ─────────────────────────────────────
                    "setAlarm" -> {
                        val hour = call.argument<Int>("hour")
                        val minute = call.argument<Int>("minute")
                        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                            putExtra(AlarmClock.EXTRA_HOUR, hour)
                            putExtra(AlarmClock.EXTRA_MINUTES, minute)
                            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                        }
                        startActivity(intent)
                        result.success("done")
                    }

                    // ── Go Home ───────────────────────────────────────
                    "goHome" -> {
                        val intent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success("done")
                    }

                    // ── Open Downloads ────────────────────────────────
                    "openDownloads" -> {
                        try {
                            val intent = Intent(android.app.DownloadManager.ACTION_VIEW_DOWNLOADS)
                            startActivity(intent)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                        result.success("done")
                    }

                    // ── WiFi Settings ─────────────────────────────────
                    "wifiSettings" -> {
                        startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                        result.success("done")
                    }

                    // ── Bluetooth Settings ────────────────────────────
                    "bluetoothSettings" -> {
                        startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                        result.success("done")
                    }

                    // ── Play Store ────────────────────────────────────
                    "openPlayStore" -> {
                        val query = call.argument<String>("query")
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://search?q=$query"))
                        startActivity(intent)
                        result.success("done")
                    }

                    // ── Settings ──────────────────────────────────────
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_SETTINGS))
                        result.success("done")
                    }

                    else -> result.notImplemented()
                }
            }
    }
}