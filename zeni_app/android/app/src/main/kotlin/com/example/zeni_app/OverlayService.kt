package com.example.zeni_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.IBinder
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.ImageButton
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

class OverlayService : Service(), TextToSpeech.OnInitListener {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingButton: ImageButton
    private lateinit var tts: TextToSpeech
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var deviceId = "overlay_device"

    private val SERVER_URL = "https://zeni-1.onrender.com"

    companion object {
        const val CHANNEL_ID = "ZeniOverlayChannel"
        const val NOTIFICATION_ID = 1
        var isRunning = false
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        tts = TextToSpeech(this, this)
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        startForegroundNotification()
        createFloatingButton()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        deviceId = intent?.getStringExtra("deviceId") ?: "overlay_device"
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts.language = Locale.US
            tts.setSpeechRate(0.9f)
        }
    }

    // ── Foreground Notification ───────────────────────────────────────
    private fun startForegroundNotification() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Zeni Assistant",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Zeni overlay is active"
            setSound(null, null)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Zeni is active")
            .setContentText("Tap the floating mic button to talk")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    // ── Create Floating Button ────────────────────────────────────────
    private fun createFloatingButton() {
        floatingButton = ImageButton(this).apply {
            setImageResource(android.R.drawable.ic_btn_speak_now)
            setPadding(28, 28, 28, 28)
            background = makeCircle("#CC1565C0")
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 20
            y = 400
        }

        // Drag + tap logic
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var hasMoved = false

        floatingButton.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    hasMoved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(dx) > 8 || Math.abs(dy) > 8) {
                        hasMoved = true
                        params.x = initialX + dx
                        params.y = initialY + dy
                        windowManager.updateViewLayout(floatingButton, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!hasMoved) onMicTapped()
                    true
                }
                else -> false
            }
        }

        windowManager.addView(floatingButton, params)
    }

    // ── Mic tap ───────────────────────────────────────────────────────
    private fun onMicTapped() {
        if (isListening) {
            stopListening()
        } else {
            startListening()
        }
    }

    // ── Start listening ───────────────────────────────────────────────
    private fun startListening() {
        isListening = true
        floatingButton.background = makeCircle("#CCFF5252")

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val text = matches?.firstOrNull() ?: ""
                stopListening()
                if (text.isNotEmpty()) sendToZeni(text)
            }
            override fun onError(error: Int) { stopListening() }
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        speechRecognizer?.startListening(intent)
    }

    // ── Stop listening ────────────────────────────────────────────────
    private fun stopListening() {
        isListening = false
        speechRecognizer?.stopListening()
        speechRecognizer?.destroy()
        speechRecognizer = null
        floatingButton.background = makeCircle("#CC1565C0")
    }

    // ── Send to Zeni server ───────────────────────────────────────────
    private fun sendToZeni(text: String) {
        // Show thinking — purple
        floatingButton.background = makeCircle("#CC7B1FA2")

        Thread {
            try {
                val url = URL("$SERVER_URL/chat")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 15000
                connection.readTimeout = 15000

                val body = JSONObject().apply {
                    put("message", text)
                    put("deviceId", deviceId)
                }.toString()

                val os: OutputStream = connection.outputStream
                os.write(body.toByteArray())
                os.flush()

                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    response.append(line)
                }

                val reply = JSONObject(response.toString()).getString("reply")

                // Back to blue after response
                floatingButton.post {
                    floatingButton.background = makeCircle("#CC1565C0")
                }

                tts.speak(reply, TextToSpeech.QUEUE_FLUSH, null, null)

            } catch (e: Exception) {
                floatingButton.post {
                    floatingButton.background = makeCircle("#CC1565C0")
                }
                tts.speak("Could not connect to Zeni server.", TextToSpeech.QUEUE_FLUSH, null, null)
            }
        }.start()
    }

    // ── Helper: make circle drawable ──────────────────────────────────
    private fun makeCircle(hex: String): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor(hex))
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        if (::floatingButton.isInitialized) {
            try { windowManager.removeView(floatingButton) } catch (e: Exception) {}
        }
        tts.shutdown()
        speechRecognizer?.destroy()
    }
}