import 'dart:typed_data';

/// Browser stand-in for the on-device skin model.
/// TensorFlow Lite uses dart:ffi, which Chrome cannot compile.
class AIService {
  static Future<void> loadModel() async {}

  static Future<Map<String, dynamic>> predictSkinCondition(
    Uint8List imageBytes,
  ) async {
    throw UnsupportedError(
      'Skin analysis uses the on-device model and only runs in the Android or iOS app. Chrome cannot load that model.',
    );
  }

  static void dispose() {}
}
