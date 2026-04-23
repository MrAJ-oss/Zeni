package com.example.zeni_app

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.media.AudioManager
import android.content.Context
import android.hardware.camera2.CameraManager
import android.content.pm.PackageManager
import android.provider.ContactsContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "zeni/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "openApp" -> {
                        val pkg = call.argument<String>("package")
                        val intent = packageManager.getLaunchIntentForPackage(pkg!!)
                        startActivity(intent)
                        result.success(true)
                    }

                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_SETTINGS))
                        result.success(true)
                    }

                    "setVolume" -> {
                        val level = call.argument<Int>("level")!!
                        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audio.setStreamVolume(AudioManager.STREAM_MUSIC, level, 0)
                        result.success(true)
                    }

                    "flashOn" -> {
                        val cam = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                        cam.setTorchMode(cam.cameraIdList[0], true)
                        result.success(true)
                    }

                    "flashOff" -> {
                        val cam = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                        cam.setTorchMode(cam.cameraIdList[0], false)
                        result.success(true)
                    }

                    "dialNumber" -> {
                        val number = call.argument<String>("number")!!
                        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                        startActivity(intent)
                        result.success(true)
                    }

                    "callContact" -> {
                        val name = call.argument<String>("name")!!.lowercase()
                        val number = findContactNumber(name)
                        if (number != null) {
                            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun findContactNumber(query: String): String? {
        val cursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            null, null, null, null
        ) ?: return null

        cursor.use {
            while (it.moveToNext()) {
                val name = it.getString(
                    it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                ).lowercase()

                val number = it.getString(
                    it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                )

                if (name.contains(query)) return number
            }
        }
        return null
    }
}