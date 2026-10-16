/// Non-web platforms use their native speech/microphone permission flow.
Future<String> requestSageMicrophonePermission() async => 'use_device_voice_controls';
