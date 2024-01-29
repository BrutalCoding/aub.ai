// Copyright (c) 2023 Daniel Breedeveld
package com.example.aub_ai_example

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// These imports are required for TTS with sherpa-onnx
import com.k2fsa.sherpa.onnx.OfflineTts
import com.k2fsa.sherpa.onnx.getOfflineTtsConfig
import android.content.res.AssetManager
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import android.util.Log
import android.media.*
import android.net.Uri

const val TAG = "sherpa-onnx"

class MainActivity: FlutterActivity() {
    private lateinit var tts: OfflineTts
    private lateinit var track: AudioTrack

    private val CHANNEL = "com.brutalcoding.tts/tts"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "initTts" -> {
                    initTts()
                }
                "generateSpeech" -> {
                    val text = call.argument<String>("text") ?: ""
                    generateSpeech(text, result)
                }
                "playSpeech" -> {
                    playSpeech()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playSpeech() {
        // Print that we are playing the speech
        println("[AUB.AI] Playing speech...")
        val filename = application.filesDir.absolutePath + "/generated.wav"
        val mediaPlayer = MediaPlayer.create(
            applicationContext,
            Uri.fromFile(File(filename))
        )
        mediaPlayer.start()
        println("[AUB.AI] Speech finished playing")
    }

    private fun generateSpeech(text: String, result: MethodChannel.Result) {
        track.pause()
        track.flush()
        track.play()

        Thread {
            val audio = tts.generateWithCallback(
                text = text,
                sid = 0, // Assuming a default value for sid
                speed = 1.0f, // Assuming a default speed value
                callback = this::callback // Assuming you have a callback method defined
            )

            val filename = "${application.filesDir.absolutePath}/generated.wav"
            val ok = audio.samples.isNotEmpty() && audio.save(filename)

            if (ok) {
                runOnUiThread {
                    result.success(filename) // Return the path of the generated audio file to Flutter
                }
            } else {
                runOnUiThread {
                    result.error("TTS_ERROR", "Failed to generate speech", null)
                }
            }
        }.start()
    }

    private fun callback(samples: FloatArray) {
        track.write(samples, 0, samples.size, AudioTrack.WRITE_BLOCKING)
    }

    private fun initTts() {
        println("[AUB.AI] Initializing TTS...")

        var modelDir: String?
        var modelName: String?
        var ruleFsts: String?
        var lexicon: String?
        var dataDir: String?
        var assets: AssetManager? = application.assets

        // The purpose of such a design is to make the CI test easier
        // Please see
        // https://github.com/k2-fsa/sherpa-onnx/blob/master/scripts/apk/generate-tts-apk-script.py
        modelDir = null
        modelName = null
        ruleFsts = null
        lexicon = null
        dataDir = null

        // Example 1:
        // modelDir = "vits-vctk"
        // modelName = "vits-vctk.onnx"
        // lexicon = "lexicon.txt"

        // Example 2:
        // https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models
        // https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-amy-low.tar.bz2
        modelDir = "vits-piper-en_US-hfc_male-medium"
        modelName = "en_US-hfc_male-medium.onnx"
        dataDir = "vits-piper-en_US-hfc_male-medium/espeak-ng-data"

        println("[AUB.AI] Loading model from $modelDir/$modelName")


        if (dataDir != null) {
            val newDir = copyDataDir(modelDir)
            modelDir = newDir + "/" + modelDir
            dataDir = newDir + "/" + dataDir
            assets = null
        }

        val config = getOfflineTtsConfig(
            modelDir = modelDir!!, modelName = modelName!!, lexicon = lexicon ?: "",
            dataDir = dataDir ?: "",
            ruleFsts = ruleFsts ?: ""
        )!!

        tts = OfflineTts(assetManager = assets, config = config)

        println("[AUB.AI] TTS initialized")

        // Now initializing the audio track
        println("[AUB.AI] Initializing AudioTrack...")
        initAudioTrack()
        println("[AUB.AI] AudioTrack initialized")
    }

    private fun initAudioTrack() {
        println("[AUB.AI] Initializing AudioTrack...")
        val sampleRate = tts.sampleRate()
        val bufLength = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_FLOAT
        )
        Log.i(TAG, "sampleRate: ${sampleRate}, buffLength: ${bufLength}")

        val attr = AudioAttributes.Builder().setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .build()

        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .setSampleRate(sampleRate)
            .build()

        track = AudioTrack(
            attr, format, bufLength, AudioTrack.MODE_STREAM,
            AudioManager.AUDIO_SESSION_ID_GENERATE
        )
        track.play()
    }

    private fun copyDataDir(dataDir: String): String {
        println("data dir is $dataDir")
        copyAssets(dataDir)

        val newDataDir = application.getExternalFilesDir(null)!!.absolutePath
        println("newDataDir: $newDataDir")
        return newDataDir
    }

    private fun copyAssets(path: String) {
        val assets: Array<String>?
        try {
            assets = application.assets.list(path)
            if (assets!!.isEmpty()) {
                copyFile(path)
            } else {
                val fullPath = "${application.getExternalFilesDir(null)}/$path"
                val dir = File(fullPath)
                dir.mkdirs()
                for (asset in assets.iterator()) {
                    val p: String = if (path == "") "" else path + "/"
                    copyAssets(p + asset)
                }
            }
        } catch (ex: IOException) {
            Log.e(TAG, "Failed to copy $path. ${ex.toString()}")
        }
    }

    private fun copyFile(filename: String) {
        try {
            val istream = application.assets.open(filename)
            val newFilename = application.getExternalFilesDir(null).toString() + "/" + filename
            val ostream = FileOutputStream(newFilename)
            // Log.i(TAG, "Copying $filename to $newFilename")
            val buffer = ByteArray(1024)
            var read = 0
            while (read != -1) {
                ostream.write(buffer, 0, read)
                read = istream.read(buffer)
            }
            istream.close()
            ostream.flush()
            ostream.close()
        } catch (ex: Exception) {
            Log.e(TAG, "Failed to copy $filename, ${ex.toString()}")
        }
    }
} // End of MainActivity


