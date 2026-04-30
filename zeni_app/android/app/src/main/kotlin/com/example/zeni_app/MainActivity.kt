package com.example.zeni_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.media.AudioManager
import android.content.Context
import androidx.core.content.ContextCompat
import android.hardware.camera2.CameraManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "zeni.phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "openApp" -> {
                        val packageName = call.argument<String>("package")
                        val intent = packageManager.getLaunchIntentForPackage(packageName!!)
                        if (intent != null) startActivity(intent)
                    }

                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        startActivity(intent)
                    }

                    "volume" -> {
                        val type = call.argument<String>("type")
                        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager

                        if (type == "up") {
                            audio.adjustVolume(AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI)
                        } else {
                            audio.adjustVolume(AudioManager.ADJUST_LOWER, AudioManager.FLAG_SHOW_UI)
                        }
                    }

                    "torch" -> {
                        val state = call.argument<Boolean>("state")
                        val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                        val cameraId = cameraManager.cameraIdList[0]
                        cameraManager.setTorchMode(cameraId, state!!)
                    }
                }
            }
    }
}