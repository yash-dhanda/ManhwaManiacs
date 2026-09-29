import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';

final audioHandlerProvider = Provider<NarrationAudioHandler>(
  (ref) => throw StateError('audioHandlerProvider is overridden in main()'),
);
