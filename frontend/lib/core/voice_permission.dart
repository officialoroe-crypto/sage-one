import 'voice_permission_stub.dart'
    if (dart.library.html) 'voice_permission_web.dart' as platform;

/// Requests microphone access only after an explicit user action.
/// Other permissions are not requested unless a SAGE feature actually needs them.
Future<String> requestSageMicrophonePermission() =>
    platform.requestSageMicrophonePermission();
