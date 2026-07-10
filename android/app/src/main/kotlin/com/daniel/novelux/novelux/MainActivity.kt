package com.daniel.novelux.novelux

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.URL

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val TTS_CHANNEL = "novelux/tts"
    private val MEDIA_CHANNEL = "novelux/media_notification"

    private val NOTIF_ID = 1001
    private val NOTIF_CHANNEL_ID = "novelux_audio"

    private lateinit var tts: TextToSpeech
    private var mediaSession: MediaSessionCompat? = null
    private var ttsMethodChannel: MethodChannel? = null
    private var mediaMethodChannel: MethodChannel? = null

    // Progress tracking
    private var totalDurationMs: Long = 0L
    private var currentPositionMs: Long = 0L
    private var isPlaying: Boolean = false
    private val progressHandler = Handler(Looper.getMainLooper())
    private val progressRunnable = object : Runnable {
        override fun run() {
            if (isPlaying) {
                currentPositionMs += 500
                if (currentPositionMs > totalDurationMs && totalDurationMs > 0) {
                    currentPositionMs = totalDurationMs
                }
                sendToFlutter(mediaMethodChannel, "onProgress", mapOf(
                    "position" to currentPositionMs,
                    "duration" to totalDurationMs
                ))
                updatePlaybackState(true)
                progressHandler.postDelayed(this, 500)
            }
        }
    }

    // Cached notification data
    private var cachedTitle = "Reading Novel"
    private var cachedArtist = "NoveluX"
    private var cachedAlbumArt: Bitmap? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, "novelux_native_ad", NativeAdFactoryImpl(this)
        )

        tts = TextToSpeech(this, this)
        createNotificationChannel()
        setupMediaSession()

        ttsMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL)
        ttsMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    val speed = call.argument<Double>("speed")?.toFloat() ?: 1.0f
                    val pitch = call.argument<Double>("pitch")?.toFloat() ?: 1.0f
                    tts.setSpeechRate(speed)
                    tts.setPitch(pitch)
                    tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "utterance")
                    result.success(null)
                }
                "stop", "pause" -> {
                    tts.stop()
                    isPlaying = false
                    progressHandler.removeCallbacks(progressRunnable)
                    updatePlaybackState(false)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        mediaMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL)
        mediaMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
           "show" -> {
                val title = call.argument<String>("title") ?: "Reading Novel"
                val artist = call.argument<String>("artist") ?: "NoveluX"
                val albumArtUrl = call.argument<String>("albumArt")
                val playing = call.argument<Boolean>("isPlaying") ?: false
                val duration = (call.argument<Int>("duration") ?: 0).toLong()
                val position = (call.argument<Int>("position") ?: 0).toLong()

                    cachedTitle = title
                    cachedArtist = artist
                    isPlaying = playing
                    totalDurationMs = duration
                    currentPositionMs = position

                    if (!albumArtUrl.isNullOrEmpty()) {
                        // Load album art from URL on background thread
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                val bitmap = BitmapFactory.decodeStream(URL(albumArtUrl).openStream())
                                withContext(Dispatchers.Main) {
                                    cachedAlbumArt = bitmap
                                    showMediaNotification(title, artist, playing, bitmap)
                                    updateMediaMetadata(title, artist, bitmap, duration)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    showMediaNotification(title, artist, playing, null)
                                    updateMediaMetadata(title, artist, null, duration)
                                }
                            }
                        }
                    } else {
                        showMediaNotification(title, artist, playing, cachedAlbumArt)
                        updateMediaMetadata(title, artist, cachedAlbumArt, duration)
                    }

                    if (playing) {
                        progressHandler.removeCallbacks(progressRunnable)
                        progressHandler.post(progressRunnable)
                    }

                    result.success(null)
                }
                "update" -> {
                    val playing = call.argument<Boolean>("isPlaying") ?: false
                    val position = call.argument<Int>("position")?.toLong()        
                    val duration = call.argument<Int>("duration")?.toLong()        

                    isPlaying = playing
                    if (position != null) currentPositionMs = position
                    if (duration != null) totalDurationMs = duration

                    showMediaNotification(cachedTitle, cachedArtist, playing, cachedAlbumArt)
                    updatePlaybackState(playing)

                    if (playing) {
                        progressHandler.removeCallbacks(progressRunnable)
                        progressHandler.post(progressRunnable)
                    } else {
                        progressHandler.removeCallbacks(progressRunnable)
                    }

                    result.success(null)
                }
                "seekTo" -> {
                    val position = (call.argument<Int>("position") ?: 0).toLong()
                    currentPositionMs = position
                    updatePlaybackState(isPlaying)
                    result.success(null)
                }
                "hide" -> {
                    isPlaying = false
                    progressHandler.removeCallbacks(progressRunnable)
                    NotificationManagerCompat.from(this).cancel(NOTIF_ID)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    sendToFlutter(ttsMethodChannel, "onStart")
                }
                override fun onDone(utteranceId: String?) {
                    sendToFlutter(ttsMethodChannel, "onDone")
                }
                override fun onError(utteranceId: String?) {
                    sendToFlutter(ttsMethodChannel, "onError")
                }
            })
        }
    }

    private fun setupMediaSession() {
        mediaSession = MediaSessionCompat(this, "NoveluXAudio")
        mediaSession?.setCallback(object : MediaSessionCompat.Callback() {
            override fun onPlay() { sendToFlutter(mediaMethodChannel, "play") }
            override fun onPause() { sendToFlutter(mediaMethodChannel, "pause") }
            override fun onStop() { sendToFlutter(mediaMethodChannel, "stop") }
            override fun onSkipToNext() { sendToFlutter(mediaMethodChannel, "next") }
            override fun onSkipToPrevious() { sendToFlutter(mediaMethodChannel, "previous") }
            override fun onSeekTo(pos: Long) {
                currentPositionMs = pos
                sendToFlutter(mediaMethodChannel, "seekTo", mapOf("position" to pos))
            }
        })
        mediaSession?.isActive = true
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID, "NoveluX Audio",
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Audio playback controls" }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun showMediaNotification(title: String, artist: String, playing: Boolean, albumArt: Bitmap?) {
        val playPauseIcon = if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val playPauseLabel = if (playing) "Pause" else "Play"
        val playPauseAction = if (playing) "pause" else "play"

        val builder = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(artist)
            .setOngoing(playing)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(android.R.drawable.ic_media_previous, "Prev", mediaPendingIntent("previous"))
            .addAction(playPauseIcon, playPauseLabel, mediaPendingIntent(playPauseAction))
            .addAction(android.R.drawable.ic_media_next, "Next", mediaPendingIntent("next"))
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(mediaSession?.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )

        // Set album art if available
        if (albumArt != null) {
            builder.setLargeIcon(albumArt)
        }

        NotificationManagerCompat.from(this).notify(NOTIF_ID, builder.build())
        updatePlaybackState(playing)
    }

    private fun updateMediaMetadata(title: String, artist: String, albumArt: Bitmap?, durationMs: Long) {
        val metadataBuilder = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artist)
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)

        if (albumArt != null) {
            metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, albumArt)
        }

        mediaSession?.setMetadata(metadataBuilder.build())
    }

    private fun updatePlaybackState(playing: Boolean) {
        val state = if (playing) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED
        mediaSession?.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(state, currentPositionMs, 1f)
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_SEEK_TO
                )
                .build()
        )
    }

    private fun sendToFlutter(channel: MethodChannel?, method: String, args: Map<String, Any>? = null) {
        runOnUiThread { channel?.invokeMethod(method, args) }
    }

    private fun mediaPendingIntent(action: String): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply { putExtra("media_action", action) }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getActivity(this, action.hashCode(), intent, flags)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra("media_action")?.let { sendToFlutter(mediaMethodChannel, it) }
    }

    override fun onDestroy() {
        flutterEngine?.let {
            GoogleMobileAdsPlugin.unregisterNativeAdFactory(it, "novelux_native_ad")
        }
        tts.stop()
        tts.shutdown()
        progressHandler.removeCallbacks(progressRunnable)
        mediaSession?.release()
        super.onDestroy()
    }
}