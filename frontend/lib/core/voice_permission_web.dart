import 'dart:html' as html;

/// Called only from the user's click on the SAGE login permission control.
/// Stop the temporary stream immediately; actual speech capture starts only
/// when the user later activates SAGE Voice.
Future<String> requestSageMicrophonePermission() async {
  try {
    final devices = html.window.navigator.mediaDevices;
    if (devices == null) return 'unavailable';
    final stream = await devices.getUserMedia(<String, dynamic>{
      'audio': true,
      'video': false,
    });
    for (final track in stream.getTracks()) {
      track.stop();
    }
    return 'granted';
  } catch (_) {
    return 'denied';
  }
}
