import 'package:flutter/services.dart';

class TtsService {
  static const MethodChannel _channel =
      MethodChannel('com.brutalcoding.tts/tts');

  /// Initializes the TTS engine of sherpa-onnx.
  static Future<void> initTts() async {
    try {
      await _channel.invokeMethod('initTts');
    } on PlatformException catch (e) {
      print("Failed to initialize TTS: '${e.message}'.");
    }
  }

  /// Generates speech from the given text and plays it.
  static Future<void> generateAndPlaySpeech(String text) async {
    try {
      final result =
          await _channel.invokeMethod('generateSpeech', {'text': text});
      print("Path to audio file (e.g. generated.wav): $result");
    } on PlatformException catch (e) {
      print("Failed to generate and play speech: '${e.message}'.");
    }
  }
}
