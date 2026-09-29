import 'package:audio_service/audio_service.dart';

/// The lock-screen handler. No player is attached yet, so its playback state
/// stays idle and no notification appears; mobile/15 moves narration onto it.
class NarrationAudioHandler extends BaseAudioHandler with SeekHandler {}
